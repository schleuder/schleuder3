module Mail
  # creates a Mail::Message likes schleuder
  def self.create_message_to_list(msg, recipient, list)
    mail = Mail.new(msg)
    mail.list = list
    mail.recipient = recipient
    # don't freeze here, as the mail might not be fully
    # parsed as body is lazy evaluated and might still
    # be changed later.
    mail.original_message = mail.dup #.freeze
    mail
  end

  # TODO: Test if subclassing breaks integration of mail-gpg.
  class Message
    attr_accessor :recipient
    attr_accessor :original_message
    attr_accessor :list
    attr_accessor :protected_headers_subject
    attr_writer :dynamic_pseudoheaders

    # TODO: This should be in initialize(), but I couldn't understand the
    # strange errors about wrong number of arguments when overriding
    # Message#initialize.
    def setup
      if self.encrypted?
        # Specify 'loopback'-pinentry-mode to ensure that gnupg never-ever
        # tries to interactively ask for a passphrase.
        new = self.decrypt(verify: true, pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK)
        # Test if there's a signed multipart inside the ciphertext
        # ("encapsulated" format of pgp/mime).
        if encapsulated_signed?(new)
          new = new.verify
        end
      elsif self.signed?
        new = self.verify
      else
        new = self
      end

      new.list = self.list
      new.recipient = self.recipient

      new.gpg list.gpg_sign_options
      new.original_message = self.dup.freeze
      # Trigger method early to save the information. Later some information
      # might be gone (e.g. request-keywords that delete subscriptions or
      # keys).
      new.signer
      new.dynamic_pseudoheaders = self.dynamic_pseudoheaders.dup

      # Store previously protected subject for later access.
      # mail-gpg pulls headers from the decrypted mime parts "up" into the main
      # headers, which reveals protected subjects.
      if self.subject != new.subject
        new.protected_headers_subject = self.subject.dup
      end

      # Delete the protected headers which might leak information.
      if new.parts.first && new.parts.first.content_type == "text/rfc822-headers; protected-headers=v1"
        new.parts.shift
      end

      new
    end

    def clean_copy(with_pseudoheaders=false)
      clean = Mail.new
      clean.list = self.list
      clean.gpg self.list.gpg_sign_options
      clean.from = list.email
      clean.subject = self.subject
      clean.protected_headers_subject = self.protected_headers_subject

      clean.add_msgids(list, self)
      clean.add_list_headers(list)
      clean.add_openpgp_headers(list)

      if with_pseudoheaders
        new_part = Mail::Part.new
        new_part.body = self.pseudoheaders(list)
        clean.add_part new_part
      end

      if self.protected_headers_subject.present?
        new_part = Mail::Part.new
        new_part.content_type = "text/rfc822-headers; protected-headers=v1"
        new_part.body = "Subject: #{self.subject}\n"
        clean.add_part new_part
      end

      # Attach body or mime-parts in a new wrapper-part, to preserve the
      # original mime-structure.
      # We can't use self.to_s here — that includes all the headers we *don't*
      # want to copy.
      wrapper_part = Mail::Part.new
      # Copy headers to are relevant for the mime-structure.
      wrapper_part.content_type = self.content_type
      wrapper_part.content_transfer_encoding = self.content_transfer_encoding if self.content_transfer_encoding
      wrapper_part.content_disposition = self.content_disposition if self.content_disposition
      wrapper_part.content_description = self.content_description if self.content_description
      # Copy contents.
      if self.multipart?
        self.parts.each do |part|
          wrapper_part.add_part(part)
        end
      else
        # We copied the content-headers, so we need to copy the body encoded.
        # Otherwise the content might become unlegible.
        wrapper_part.body = self.body.encoded
      end
      clean.add_part(wrapper_part)

      clean
    end

    def prepend_part(part)
      self.add_part(part)
      self.parts.unshift(parts.delete_at(parts.size-1))
    end

    def add_public_footer!
      # Add public_footer unless it's empty?.
      add_footer!(:public_footer)
    end

    def add_internal_footer!
      add_footer!(:internal_footer)
    end

    def was_encrypted?
      Mail::Gpg.encrypted?(original_message)
    end

    def signature
      case signatures.size
      when 0
        if multipart?
          signature_multipart_inline
        else
          nil
        end
      when 1
        signatures.first
      else
        raise "Multiple signatures found! Cannot handle!"
      end
    end

    def was_validly_signed?
      signature.present? && signature.valid? && signer.present?
    end

    def signer
      @signer ||= begin
        if signing_key.present?
          list.subscriptions.where(fingerprint: signing_key.fingerprint).first
        end
      end
    end

    # The fingerprint of the signature might be the one of a sub-key, but the
    # subscription-assigned fingerprints are (should be) the ones of the
    # primary keys, so we need to look up the key.
    def signing_key
      if signature.present?
        @signing_key ||= list.keys(signature.fpr).first
      end
    end

    def reply_to_signer(output)
      reply = self.reply
      self.class.all_to_message_part(output).each do |part|
        reply.add_part(part)
      end
      self.signer.send_mail(reply)
    end

    def self.all_to_message_part(input)
      Array(input).map do |thing|
        case thing
        when Mail::Part
          thing
        when String, StandardError
          Mail::Part.new do
            body thing.to_s
          end
        else
          raise "Don't know how to handle input: #{thing.inspect}"
        end
      end
    end

    def sendkey_request?
      @recipient.match(/-sendkey@/)
    end

    def to_owner?
      @recipient.match(/-owner@/)
    end

    def request?
      @recipient.match(/-request@/)
    end

    def automated_message?
      @recipient.match(/-bounce@/).present? ||
          # Empty Return-Path
          self.return_path.to_s == '<>' ||
          bounced?
    end

    def bounced?
      @bounced ||= bounce_detected? || (error_status != "unknown")
    end

    def error_status
      @error_status ||= detect_error_code
    end
 
    def keywords
      return @keywords if @keywords

      part = first_plaintext_part
      if part.blank?
        return []
      end

      @keywords, lines = extract_keywords(part.decoded.lines)
      new_body = lines.join

      # Work around problems with re-encoding the body. If we delete the
      # content-transfer-encoding prior to re-assigning the body, and let Mail
      # decide itself how to encode, it works. If we don't, some
      # character-sequences are not properly re-encoded.
      part.content_transfer_encoding = nil

      # Set the right charset on the now parsed body
      part.charset = new_body.encoding.to_s
      part.body = new_body

      @keywords
    end

    def add_subject_prefix!
      _add_subject_prefix(nil)
    end

    def add_subject_prefix_in!
      _add_subject_prefix(:in)
    end

    def add_subject_prefix_out!
      _add_subject_prefix(:out)
    end

    def add_pseudoheader(string_or_key, value=nil)
      dynamic_pseudoheaders << make_pseudoheader(string_or_key, value)
    end

    def make_pseudoheader(key, value)
      output = "#{key.to_s.camelize}: #{value.to_s}"
      # wrap lines after 76 with 2 indents
      output.gsub(/(.{1,76})( +|$)\n?/, "  \\1\n").chomp.lstrip
    end

    def dynamic_pseudoheaders
      @dynamic_pseudoheaders ||= []
    end

    def signature_state
      # Careful to add information about the incoming signature. GPGME
      # throws exceptions if it doesn't know the key.
      if self.signature.present?
        # Some versions of gpgme return nil if the key is unknown, so we check
        # for that manually and provide our own fallback. (Calling
        # `signature.key` results in an EOFError in that case.)
        if signing_key.present?
          signature_state = signature.to_s
        else
          signature_state = I18n.t("signature_states.unknown", fingerprint: self.signature.fingerprint)
        end
      else
        signature_state = I18n.t("signature_states.unsigned")
      end
      signature_state
    end

    def encryption_state
      if was_encrypted?
        encryption_state = I18n.t("encryption_states.encrypted")
      else
        encryption_state = I18n.t("encryption_states.unencrypted")
      end
      encryption_state
    end

    def standard_pseudoheaders(list)
      if @standard_pseudoheaders.present?
        return @standard_pseudoheaders
      else
        @standard_pseudoheaders = []
      end

      Array(list.headers_to_meta).each do |field|
        value = case field.to_s
          when 'sig' then signature_state
          when 'enc' then encryption_state
          else self.header[field.to_s]
        end
        @standard_pseudoheaders << make_pseudoheader(field.to_s, value)
      end


      @standard_pseudoheaders
    end

    def pseudoheaders(list)
      separator = '------------------------------------------------------------------------------'
      (standard_pseudoheaders(list) + dynamic_pseudoheaders).flatten.join("\n") + "\n" + separator + "\n"
    end

    def add_msgids(list, orig)
      if list.keep_msgid
        # Don't use `orig['in-reply-to']` here, because that sometimes fails to
        # parse the original value and then returns it without the
        # angle-brackets.
        self.message_id = clutch_anglebrackets(orig.message_id)
        self.in_reply_to = clutch_anglebrackets(orig.in_reply_to)
        self.references = clutch_anglebrackets(orig.references)
      end
    end

    def add_list_headers(list)
      if list.include_autocrypt_header
        # Inject whitespaces, to let Mail break the string at these points
        # leading to correct wrapping.
        keydata = list.key_minimal_base64_encoded.gsub(/(.{78})/, '\1 ')
        
        self['Autocrypt'] = "addr=#{list.email}; prefer-encrypt=mutual; keydata=#{keydata}"
      end

      if list.include_list_headers
        self['List-Id'] = "<#{list.email.gsub('@', '.')}>"
        self['List-Owner'] = "<mailto:#{list.owner_address}> (Use list's public key)"
        self['List-Help'] = '<https://schleuder.org/>'

        postmsg = if list.receive_admin_only
                    "NO (Admins only)"
                  elsif list.receive_authenticated_only
                    "<mailto:#{list.email}> (Subscribers only)"
                  else
                    "<mailto:#{list.email}>"
                  end

        self['List-Post'] = postmsg
      end
    end

    def add_openpgp_headers(list)
      if list.include_openpgp_header

        if list.openpgp_header_preference == 'none'
          pref = ''
        else
          pref = "preference=#{list.openpgp_header_preference}"

          # TODO: simplify.
          pref << ' ('
          if list.receive_admin_only
            pref << 'Only encrypted and signed emails by list-admins are accepted'
          elsif ! list.receive_authenticated_only
            if list.receive_encrypted_only && list.receive_signed_only
              pref << 'Only encrypted and signed emails are accepted'
            elsif list.receive_encrypted_only && ! list.receive_signed_only
              pref << 'Only encrypted emails are accepted'
            elsif ! list.receive_encrypted_only && list.receive_signed_only
              pref << 'Only signed emails are accepted'
            else
              pref << 'All kind of emails are accepted'
            end
          elsif list.receive_authenticated_only
            if list.receive_encrypted_only
              pref << 'Only encrypted and signed emails by subscribers are accepted'
            else
              pref << 'Only signed emails by subscribers are accepted'
            end
          else
            pref << 'All kind of emails are accepted'
          end
          pref << ')'
        end

        fingerprint = list.fingerprint
        comment = "(Send an email to #{list.sendkey_address} to receive the public-key)"

        self['OpenPGP'] = "id=0x#{fingerprint} #{comment}; #{pref}"
      end
    end

    def empty?
      if self.multipart?
        if self.parts.empty?
          return true
        else
          # Test parts recursively. E.g. Thunderbird with activated
          # memoryhole-headers send nested parts that might still be empty.
          return parts.inject(true) { |result, part| result && part.empty? }
        end
      else
        return self.body.empty?
      end
    end

    def first_plaintext_part(part=nil)
      part ||= self
      if part.multipart?
        first_plaintext_part(part.parts.first)
      elsif part.mime_type == 'text/plain'
        part
      else
        nil
      end
    end


    def attach_list_key!(list)
      filename = "#{list.email}.asc"
      self.add_file({
        filename: filename,
        content: list.export_key
      })
      self.attachments[filename].content_type = 'application/pgp-keys'
      self.attachments[filename].content_description = 'OpenPGP public key'
      true
    end

    private


    def extract_keywords(content_lines)
      keywords = []
      in_keyword_block = false
      content_lines.each_with_index do |line, i|
        if match = line.match(/^x-([^:\s]*)[:\s]*(.*)/i)
          keyword = match[1].strip.downcase
          arguments = match[2].to_s.strip.downcase.split(/[,; ]{1,}/)
          keywords << [keyword, arguments]
          in_keyword_block = true

          # Set this line to nil to have it stripped from the message.
          content_lines[i] = nil

          if keyword == 'stop'
            # This stops the parsing.
            break
          end
        elsif in_keyword_block == true
          # Interpret line as arguments to the previous keyword.
          keywords[-1][-1] += line.downcase.strip.split(/[,; ]{1,}/)
          content_lines[i] = nil
        end
      end
      [keywords, content_lines.compact]
    end

    # mail.signed? throws an error if it finds
    # pgp boundaries, so we must use the Mail::Gpg
    # methods.
    def encapsulated_signed?(mail)
      (mail.verify_result.nil? || mail.verify_result.signatures.empty?) && \
        (Mail::Gpg.signed_mime?(mail) || Mail::Gpg.signed_inline?(mail))
    end

    def add_footer!(footer_attribute)
      if self.list.blank? || self.list.send(footer_attribute).to_s.empty?
        return
      end
      footer_part = Mail::Part.new
      footer_part.body = self.list.send(footer_attribute).to_s
      if wrapped_single_text_part?
        self.parts.first.add_part footer_part
      else
        self.add_part footer_part
      end
    end

    def wrapped_single_text_part?
      parts.size == 1 && 
        parts.first.mime_type == 'multipart/mixed' && 
        parts.first.parts.size == 1 && 
        parts.first.parts.first.mime_type == 'text/plain'
    end

    def _add_subject_prefix(suffix)
      attrib = "subject_prefix"
      if suffix
        attrib << "_#{suffix}"
      end
      if ! self.list.respond_to?(attrib)
        return false
      end

      string = self.list.send(attrib).to_s.strip
      if ! string.empty?
        prefix = "#{string} "
        # Only insert prefix if it's not present already.
        if self.subject.nil?
          self.subject = string
        elsif ! self.subject.include?(prefix)
          self.subject = "#{prefix}#{self.subject}"
        end
      end
    end

    # Looking for signatures in each part. They are not aggregated into the main part.
    # We only return the signature if all parts are validly signed by the same key.
    def signature_multipart_inline
      fingerprints = parts.map do |part|
        if part.signature_valid?
          part.signature.fpr
        else
          nil
        end
      end
      if fingerprints.uniq.size == 1
        parts.first.signature
      else
        nil
      end
    end

    def clutch_anglebrackets(input)
      Array(input).map do |string|
        if string.first == '<'
          string
        else
          "<#{string}>"
        end
      end.join(' ')
    end

    def detect_error_code
      # Detects the error code of an email with different heuristics
      # from: https://github.com/mailtop/bounce_email
      
      # Custom status codes
      unicode_subject = self.subject.to_s
      unicode_subject = unicode_subject.encode('utf-8') if unicode_subject.respond_to?(:encode)
 
      return '97' if unicode_subject.match(/delayed/i)
      return '98' if unicode_subject.match(/(unzulässiger|unerlaubter) anhang/i)
      return '99' if unicode_subject.match(/auto.*reply|férias|ferias|Estarei ausente|estou ausente|vacation|vocation|(out|away).*office|on holiday|abwesenheits|autorespond|Automatische|eingangsbestätigung/i)

      # Feedback-Type: abuse
      return '96' if self.to_s.match(/Feedback-Type\: abuse/i)

      if self.parts[1]
        match_parts = self.parts[1].body.match(/(Status:.|550 |#)([245]\.[0-9]{1,3}\.[0-9]{1,3})/)
        code = match_parts[2] if match_parts
        return code if code
      end

      # Now try getting it from correct part of tmail
      code = detect_bounce_status_code_from_text(self.body)
      return code if code

      # OK getting desperate so try getting code from entire email
      code = detect_bounce_status_code_from_text(self.to_s)
      code || 'unknown'
    end

    def bounce_detected?
      # Detects bounces from different parts of the email without error status codes
      # from: https://github.com/mailtop/bounce_email
      return true if self.subject.to_s.match(/(returned|undelivered) mail|mail delivery( failed)?|(delivery )(status notification|failure)|failure notice|undeliver(able|ed)( mail)?|return(ing message|ed) to sender/i)
      return true if self.subject.to_s.match(/auto.*reply|vacation|vocation|(out|away).*office|on holiday|abwesenheits|autorespond|Automatische|eingangsbestätigung/i)
      return true if self['precedence'].to_s.match(/auto.*(reply|responder|antwort)/i)
      return true if self.from.to_s.match(/^(MAILER-DAEMON|POSTMASTER)\@/i)
      false
    end

    def detect_bounce_status_code_from_text(text)
      # Parses a text and uses pattern matching to determines its error status (RFC 3463)
      # from: https://github.com/mailtop/bounce_email
      return "5.0.0" if text.match(/Status: 5\.0\.0/i)
      return "5.1.1" if text.match(/no such (address|user)|Recipient address rejected|User unknown|does not like recipient|The recipient was unavailable to take delivery of the message|Sorry, no mailbox here by that name|invalid address|unknown user|unknown local part|user not found|invalid recipient|failed after I sent the message|did not reach the following recipient|nicht zugestellt werden|o pode ser entregue para um ou mais/i)
      return "5.1.2" if text.match(/unrouteable mail domain|Esta casilla ha expirado por falta de uso|I couldn't find any host named/i)
      if text.match(/mailbox is full|Mailbox quota (usage|disk) exceeded|quota exceeded|Over quota|User mailbox exceeds allowed size|Message rejected\. Not enough storage space|user has exhausted allowed storage space|too many messages on the server|mailbox is over quota|mailbox exceeds allowed size|excedeu a quota/i)
        return "5.2.2" if text.match(/This is a permanent error||(Status: |)5\.2\.2/i)
        return "4.2.2"
      end
      return "5.1.0" if text.match(/Address rejected/)
      return "4.1.2" if text.match(/I couldn't find any host by that name/)
      return "4.2.0" if text.match(/not yet been delivered/i)
      return "5.1.1" if text.match(/mailbox unavailable|No such mailbox|RecipientNotFound|not found by SMTP address lookup|Status: 5\.1\.1/i)
      return "5.2.3" if text.match(/Status: 5\.2\.3/i) # Too messages in folder
      return "5.4.0" if text.match(/Status: 5\.4\.0/i) # too many hops
      return "5.4.4" if text.match(/Unrouteable address/i)
      return "4.4.7" if text.match(/retry timeout exceeded/i)
      return "5.2.0" if text.match(/The account or domain may not exist, they may be blacklisted, or missing the proper dns entries./i)
      return "5.5.4" if text.match(/554 TRANSACTION FAILED/i)
      return "4.4.1" if text.match(/Status: 4.4.1|delivery temporarily suspended|wasn't able to establish an SMTP connection/i)
      return "5.5.0" if text.match(/550 OU\-002|Mail rejected by Windows Live Hotmail for policy reasons/i)
      return "5.1.2" if text.match(/PERM_FAILURE: DNS Error: Domain name not found/i)
      return "4.2.0" if text.match(/Delivery attempts will continue to be made for/i)
      return "5.5.4" if text.match(/554 delivery error:/i)
      return "5.1.1" if text.match(/550-5.1.1|This Gmail user does not exist/i)
      return "5.7.1" if text.match(/5.7.1 Your message.*?was blocked by ROTA DNSBL/i) # AA added
      return "5.7.2" if text.match(/not have permission to post messages to the group/i)
      return "5.3.2" if text.match(/Technical details of permanent failure|Too many bad recipients/i) && (text.match(/The recipient server did not accept our requests to connect/i) || text.match(/Connection was dropped by remote host/i) || text.match(/Could not initiate SMTP conversation/i)) # AA added
      return "4.3.2" if text.match(/Technical details of temporary failure/i) && (text.match(/The recipient server did not accept our requests to connect/i) || text.match(/Connection was dropped by remote host/i) || text.match(/Could not initiate SMTP conversation/i)) # AA added
      return "5.0.0" if text.match(/Delivery to the following recipient failed permanently/i) # AA added
      return '5.2.3' if text.match(/account closed|account has been disabled or discontinued|mailbox not found|prohibited by administrator|access denied|account does not exist/i)
    end
  end
end

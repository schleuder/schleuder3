module Schleuder
  class Cert < Thor
    extend SubcommandFix

    desc 'generate', 'Generate a new TLS-certificate.'
    def generate
      key = Conf.api['tls_key_file']
      cert = Conf.api['tls_cert_file']
      fingerprint = SchleuderCertManager.generate('schleuder', key, cert)
      puts "Fingerprint of generated certificate: #{fingerprint}"
      puts 'Have this fingerprint included into the configuration-file of all clients that want to connect to your Schleuder API.'
      if Process.euid == 0
        puts '! Warning: this process was run as root — please make sure the above files are accessible by the user that is running `schleuder-api-daemon`.'
      end
    end

    desc 'fingerprint', 'Show fingerprint of configured certificate.'
    def fingerprint
      cert = Conf.api['tls_cert_file']
      fingerprint = SchleuderCertManager.fingerprint(cert)
      say "Fingerprint of #{Conf.api['tls_cert_file']}: #{fingerprint}"
    end
  end
end

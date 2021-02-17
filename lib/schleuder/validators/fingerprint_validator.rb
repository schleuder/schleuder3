class FingerprintValidator <  ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless GPGME::Key.valid_fingerprint?(value)
      record.errors.add(attribute, (options[:message] || I18n.t('errors.invalid_fingerprint')))
    end
  end
end

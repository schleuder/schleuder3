class EmailValidator <  ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value =~ Conf::EMAIL_REGEXP
      record.errors[attribute] << (options[:message] || I18n.t('errors.invalid_email'))
    end
  end
end

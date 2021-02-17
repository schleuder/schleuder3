class NoLineBreaksValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.to_s.include?("\n")
      record.errors.add(attribute, I18n.t('errors.no_linebreaks') )
    end
  end
end

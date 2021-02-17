class BooleanValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if ! [true, false].include?(value)
      record.errors.add(attribute, I18n.t('errors.must_be_boolean'))
    end
  end
end

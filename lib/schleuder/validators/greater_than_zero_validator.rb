class GreaterThanZeroValidator <  ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.to_i == 0
      record.errors.add(attribute, I18n.t('errors.must_be_greater_than_zero'))
    end
  end
end

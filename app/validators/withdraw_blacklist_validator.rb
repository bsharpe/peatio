class WithdrawBlacklistValidator < ActiveModel::Validator

  def validate(record)
    if record.channel && record.channel.blacklist && record.channel.blacklist.include?(record.fund_uid)
      record.errors[:fund_uid] << I18n.t('withdraws.invalid_address')
    end
  end

end

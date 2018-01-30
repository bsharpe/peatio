class WithdrawSubscriber
  def after_create(object)
    object.generate_serial_number
    ::Pusher["private-#{object.member.sn}"].trigger_async('withdraws', { type: 'create', attributes: object.as_json })
  end

  def after_update(object, changes, current_user)
    if changes.keys.include?('aasm_state')
      Audit::TransferAuditLog.audit!(object, current_user)
    end
    ::Pusher["private-#{object.member.sn}"].trigger_async('withdraws', { type: 'update', id: object.id, attributes: changes })
  end

  def after_destroy(object_data)
    ::Pusher["private-#{object.member.sn}"].trigger_async('withdraws', { type: 'destroy', id: object_data[:id] })
  end

  def send_mail(object)
    case object.aasm_state
    when 'submitted'
      WithdrawMailer.submitted(object.id).deliver_later
    when 'processing'
      WithdrawMailer.processing(object.id).deliver_later
    when 'done'
      WithdrawMailer.done(object.id).deliver_later
    else
      WithdrawMailer.withdraw_state(object.id).deliver_later
    end
  end

  def send_sms(object)
    sms_message = I18n.t('sms.withdraw_done', email: object.member.email,
                                             currency: object.currency_text,
                                             time: I18n.l(Time.current),
                                             amount: object.amount,
                                             balance: object.account.balance)

    AMQPQueue.enqueue(:sms_notification, phone: object.member.phone_number, message: sms_message)
  end
end
class DepositSubscriber
  def after_create(object)
    ::Pusher["private-#{object.member.sn}"].trigger_async('deposits', { type: 'create', attributes: object.as_json })
  end

  def after_update(object, changes, current_user)
    if changes.keys.include(:aasm_state)
      Audit::TransferAuditLog.audit!(object, current_user)
    end
    ::Pusher["private-#{object.member.sn}"].trigger_async('deposits', { type: 'update', id: object.id, attributes: changes })
  end

  def after_destroy(object_data)
    ::Pusher["private-#{object.member.sn}"].trigger_async('deposits', { type: 'destroy', id: object_data[:id] })
  end

  def deposit_made(object)
    # send email
    DepositMailer.accepted(object.id).deliver_later

    # send sms
    sms_message = I18n.t('sms.deposit_done', email: object.member.email,
                                             currency: object.currency_text,
                                             time: I18n.l(Time.current),
                                             amount: object.amount,
                                             balance: object.account.balance)

    AMQPQueue.enqueue(:sms_notification, phone: object.member.phone_number, message: sms_message)
  end
end
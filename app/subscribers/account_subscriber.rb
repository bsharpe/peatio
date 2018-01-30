class AccountSubscriber

  def after_create(object)
    sync(object)
  end

  def after_update(object, changes, user)
    sync(object)
  end

  private

  def sync(object)
    return unless object.member

    ::Pusher["private-#{object.member.sn}"].trigger_async('accounts', {
      type: 'update',
      id: object.id,
        attributes: {
          balance: object.balance,
          locked: object.locked
        }
      }
    )
    json = Jbuilder.encode do |json|
      json.(object, :balance, :locked, :currency)
    end

    AMQPQueue.enqueue(:pusher_member, {member_id: object.member.id, event: :account, data: json})
  end

end

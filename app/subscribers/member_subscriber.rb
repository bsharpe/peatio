class MemberSubscriber
  def after_create(object)
    # touch_accounts(object)
    object.create_id_document
  end

  def after_update(object, changes, current_user)
    send_activation(object) if changes.keys.include?('email')
    sync_update(object)
  end

  def send_activation(member)
    if member.authentications.for_provider(:identity).first
      member.token_activations.create
    end
  end

  def touch_accounts(member)
    less = Currency.codes - member.accounts.map(&:currency).map(&:to_sym)
    less.each do |code|
      member.accounts.create(currency: code, balance: 0, locked: 0)
    end
  end

  def sync_update(member)
    ::Pusher["private-#{member.uid}"].trigger_async(
      'members',
      { type: 'update',
        id: member.id,
        attributes: member.changes_attributes_as_json,
      }
    )
  end
end
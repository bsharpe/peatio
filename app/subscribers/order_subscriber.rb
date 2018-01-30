class OrderSubscriber

  def after_create(object)
    trigger(object)
  end

  def after_update(object, changes, current_user)
    trigger(object)
  end

  private
  ATTRIBUTES = %w[id at market kind price state state_text volume origin_volume].freeze

  def trigger(object)
    return unless object.member

    json = Jbuilder.encode do |json|
      json.(object, *ATTRIBUTES)
    end

    object.member.trigger('order', json)
  end

end
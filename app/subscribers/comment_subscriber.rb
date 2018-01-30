class CommentSubscriber

  def after_create(object)
    ticket_author = object.ticket.author

    if ticket_author != object.author
      CommentMailer.user_notification(object)&.deliver_later
    else
      CommentMailer.admin_notification(object)&.deliver_later
    end
  end

end
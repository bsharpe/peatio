class CommentMailer < ApplicationMailer

  def user_notification(comment)
    comment = Comment.ensure(comment)
    @ticket_url = ticket_url(comment.ticket)

    mail(to: comment.ticket.author.email)
  end

  def admin_notification(comment)
    comment = Comment.ensure(comment)
    @ticket_url = admin_ticket_url(comment.ticket)
    @author_email = comment.author.email

    mail(to: ENV['SUPPORT_MAIL'])
  end

end

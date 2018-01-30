class TicketMailer < ApplicationMailer

  def author_notification(ticket)
    ticket = Ticket.ensure(ticket)
    @ticket_url = ticket_url(ticket)

    mail to: ticket.author.email
  end

  def admin_notification(ticket)
    ticket = Ticket.ensure(ticket)
    @author_email = ticket.author.email
    @ticket_url = admin_ticket_url(ticket)

    mail to: ENV['SUPPORT_MAIL']
  end

end

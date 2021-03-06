# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  content    :text(65535)
#  author_id  :integer
#  ticket_id  :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Comment do
  describe "#send_notification" do
    let!(:author) { create(:member, email: 'terry@apple.com') }
    let!(:admin)  { create(:member) }
    let!(:ticket) { create(:ticket, author: author) }
    let(:mailer) { OpenStruct.new }
    before { allow(mailer).to receive(:deliver) }
    after { comment.send(:send_notification) }

    context "admin reply the ticket" do
      let!(:comment) { create(:comment, author: admin, ticket: ticket)}
      it "should notify the author" do
        expect(CommentMailer).to receive(:user_notification).with(comment.id).and_return(mailer)
      end
    end

    context "author reply the ticket" do
      let!(:comment) { create(:comment, author: author, ticket: ticket)}

      it "should not notify the admin" do
        expect(CommentMailer).to receive(:admin_notification).with(comment.id).and_return(mailer)
      end

    end
  end
end

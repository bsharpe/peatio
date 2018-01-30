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

require 'rails_helper'

RSpec.describe Comment, type: :model do

  let(:user)    { create(:member) }
  let(:admin)   { create(:member) }
  let(:ticket)  { create(:ticket, author: user) }

  context "author reply the ticket" do
    let(:comment) { create(:comment, author: user, ticket: ticket) }

    it "should not notify the admin" do
      expect(CommentMailer).to receive(:admin_notification)
      comment
    end
  end

  context "admin reply the ticket" do
    let(:comment) { create(:comment, author: admin, ticket: ticket) }

    it "should notify the author" do
      expect(CommentMailer).to receive(:user_notification)
      comment
    end
  end

end

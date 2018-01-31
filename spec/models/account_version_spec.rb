# == Schema Information
#
# Table name: account_versions
#
#  id              :integer          not null, primary key
#  member_id       :integer
#  account_id      :integer
#  reason          :integer
#  balance         :decimal(32, 16)
#  locked          :decimal(32, 16)
#  fee             :decimal(32, 16)
#  amount          :decimal(32, 16)
#  modifiable_id   :integer
#  modifiable_type :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  currency        :integer
#  operation       :integer
#
# Indexes
#
#  index_account_versions_on_account_id                         (account_id)
#  index_account_versions_on_account_id_and_reason              (account_id,reason)
#  index_account_versions_on_member_id_and_reason               (member_id,reason)
#  index_account_versions_on_modifiable_id_and_modifiable_type  (modifiable_id,modifiable_type)
#

# NOTE: Not sure this is still needed with atomic account operations

# # == Schema Information
# #
# # Table name: account_versions
# #
# #  id              :integer          not null, primary key
# #  member_id       :integer
# #  account_id      :integer
# #  reason          :integer
# #  balance         :decimal(32, 16)
# #  locked          :decimal(32, 16)
# #  fee             :decimal(32, 16)
# #  amount          :decimal(32, 16)
# #  modifiable_id   :integer
# #  modifiable_type :string(255)
# #  created_at      :datetime
# #  updated_at      :datetime
# #  currency        :integer
# #  operation       :integer
# #
# # Indexes
# #
# #  index_account_versions_on_account_id                         (account_id)
# #  index_account_versions_on_account_id_and_reason              (account_id,reason)
# #  index_account_versions_on_member_id_and_reason               (member_id,reason)
# #  index_account_versions_on_modifiable_id_and_modifiable_type  (modifiable_id,modifiable_type)
# #
#
# require 'rails_helper'
#
# RSpec.describe AccountVersion do
#
#   let(:member)  { create(:member) }
#   let(:account) { member.get_account(:btc) }
#
#   before { account.update_attributes(locked: '10.0'.to_d, balance: '10.0'.to_d) }
#
#   context "#optimistically_lock_account_and_save!" do
#     # mock AccountVersion attributes of
#     # `unlock_and_sub_funds('5.0'.to_d, locked: '8.0'.to_d, fee: ZERO)`
#     let(:attrs) do
#       { account_id: account.id,
#         operation: :unlock_and_sub_funds,
#         fee: Account::ZERO,
#         reason: Account::UNKNOWN,
#         amount: '15.0'.to_d,
#         currency: account.currency,
#         member_id: account.member_id,
#         locked: '-8.0'.to_d,
#         balance: '3.0'.to_d }
#     end
#
#     it "should require account id" do
#       attrs.delete :account_id
#       expect {
#         AccountVersion.optimistically_lock_account_and_create!('13.0'.to_d, '2.0'.to_d, attrs)
#       }.to raise_error(ActiveRecord::ActiveRecordError)
#     end
#
#     it "should save record if associated account is fresh" do
#       expect {
#         # `unlock_and_sub_funds('5.0'.to_d, locked: '8.0'.to_d, fee: ZERO)`
#         ActiveRecord::Base.connection.execute "update accounts set balance = balance + 3, locked = locked - 8 where id = #{account.id}"
#         AccountVersion.optimistically_lock_account_and_create!('13.0'.to_d, '2.0'.to_d, attrs)
#       }.to change(AccountVersion, :count).by(1)
#     end
#
#     it "should raise StaleObjectError if associated account is stale" do
#       account_in_another_thread = Account.find(account.id)
#       Account::AddFunds.(account: account_in_another_thread, amount: 2)
#
#       expect {
#         # `unlock_and_sub_funds('5.0'.to_d, locked: '8.0'.to_d, fee: ZERO)`
#         ActiveRecord::Base.connection.execute "update accounts set balance = balance + 3, locked = locked - 8 where id = #{account.id}"
#         AccountVersion.optimistically_lock_account_and_create!('13.0'.to_d, '2.0'.to_d, attrs)
#       }.to raise_error(ActiveRecord::StaleObjectError)
#
#       expect {
#         AccountVersion.optimistically_lock_account_and_create!('15.0'.to_d, '2.0'.to_d, attrs)
#       }.to change(AccountVersion, :count).by(1)
#     end
#
#     it "should save associated modifiable record" do
#       attrs_with_modifiable = attrs.merge(modifiable_id: 1, modifiable_type: 'OrderAsk')
#
#       expect {
#         AccountVersion.optimistically_lock_account_and_create!('10.0'.to_d, '10.0'.to_d, attrs_with_modifiable)
#       }.to change(AccountVersion, :count).by(1)
#     end
#   end
#
# end

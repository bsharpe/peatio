# == Schema Information
#
# Table name: audit_logs
#
#  id             :integer          not null, primary key
#  type           :string(255)
#  operator_id    :integer
#  created_at     :datetime
#  updated_at     :datetime
#  auditable_id   :integer
#  auditable_type :string(255)
#  source_state   :string(255)
#  target_state   :string(255)
#
# Indexes
#
#  index_audit_logs_on_auditable_id_and_auditable_type  (auditable_id,auditable_type)
#  index_audit_logs_on_operator_id                      (operator_id)
#

require 'spec_helper'

module Audit
  describe TransferAuditLog do
    describe ".audit!" do
      let(:deposit) { create(:deposit) }
      let(:member) { create(:member) }

      subject { TransferAuditLog.audit!(deposit, member) }

      before do
        allow(deposit).to receive(:aasm_state_was).and_return('submitted')
        allow(deposit).to receive(:aasm_state).and_return('accepted')
      end

      it "should create the TransferAuditLog record" do
        expect { subject }.to change{ TransferAuditLog.count }.by(1)
      end

      its(:operator) { should == member }
      its(:auditable) { should == deposit }
      its(:source_state) { should == 'submitted' }
      its(:target_state) { should == 'accepted' }

    end
  end

end

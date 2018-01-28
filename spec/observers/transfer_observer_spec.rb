require 'spec_helper'

describe TransferObserver do
  describe "#after_update" do
    let!(:member) { create(:member) }
    let!(:deposit) { create(:deposit, aasm_state: 'submitted')}
    before do
      allow_any_instance_of(TransferObserver).to receive(:current_user).and_return(member)
    end

    subject { deposit.update_attributes(aasm_state: 'accepted')}

    it "should create the audit log" do
      expect { subject }.to change{ Audit::TransferAuditLog.count }.by(1)

    end
  end
end

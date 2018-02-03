class ChangeToEnumerizeInPaymentTransactions < ActiveRecord::Migration[4.2]
  def up
    change_column :payment_transactions, :state, :integer
  end

  def down
    change_column :payment_transactions, :state, :string
  end
end

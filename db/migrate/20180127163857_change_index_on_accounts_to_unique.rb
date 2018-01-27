class ChangeIndexOnAccountsToUnique < ActiveRecord::Migration
  def up
    remove_index :accounts, [:member_id, :currency] rescue nil
    add_index :accounts, [:member_id, :currency], unique: true
  end

  def down
    remove_index :accounts, [:member_id, :currency]
    add_index :accounts, [:member_id, :currency]
  end
end

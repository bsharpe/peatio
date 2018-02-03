class DropResetPasswords < ActiveRecord::Migration[4.2]
  def up
    if ActiveRecord::Base.connection.table_exists? :reset_passwords
      drop_table :reset_passwords
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

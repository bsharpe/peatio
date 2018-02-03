class AddDefaultsToAccount < ActiveRecord::Migration[5.1]
  def change
    change_column_default :accounts, :balance, 0
    change_column_default :accounts, :locked, 0
    change_column_default :accounts, :in, 0
    change_column_default :accounts, :out, 0
  end
end

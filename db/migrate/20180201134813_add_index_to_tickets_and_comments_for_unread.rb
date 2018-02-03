class AddIndexToTicketsAndCommentsForUnread < ActiveRecord::Migration[5.1]
  def change
    add_index :tickets, :created_at
    add_index :comments, :created_at
  end
end

class RenameSnToUidOnMembers < ActiveRecord::Migration[5.1]
  def change
    rename_column :members, :sn, :uid
  end
end

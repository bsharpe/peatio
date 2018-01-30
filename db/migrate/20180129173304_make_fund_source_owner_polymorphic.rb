class MakeFundSourceOwnerPolymorphic < ActiveRecord::Migration[5.1]
  def up
    rename_column :fund_sources, :member_id, :owner_id
    add_column :fund_sources, :owner_type, :string
    add_index :fund_sources, [:owner_type, :owner_id], unique: true
  end

  def down
    remove_index :fund_sources, [:owner_type, :owner_id]
    rename_column :fund_sources, :owner_id, :member_id
    remove_column :fund_sources, :owner_type
  end
end

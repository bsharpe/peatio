class AddAlipayAddressToMembers < ActiveRecord::Migration[4.2]
  def change
    add_column :members, :alipay, :string
    add_column :members, :state, :integer
  end
end

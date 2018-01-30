class ChangeFunToOperationOnAccountVersions < ActiveRecord::Migration[5.1]
  def change
    rename_column :account_versions, :fun, :operation
  end
end

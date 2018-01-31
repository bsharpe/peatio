class UnreadPolymorphicReaderMigration < Unread::MIGRATION_BASE_CLASS
  def self.up
    remove_index :read_marks, [:member_id]
    remove_index :read_marks, [:readable_type, :readable_id]
    rename_column :read_marks, :member_id, :reader_id
    add_column :read_marks, :reader_type, :string
    execute "UPDATE read_marks SET reader_type = 'Member'"
    add_index :read_marks, [:reader_id, :reader_type, :readable_type, :readable_id], name: 'read_marks_reader_readable_index', unique: true
  end

  def self.down
    remove_index :read_marks, name: 'read_marks_reader_readable_index'
    remove_column :read_marks, :reader_type
    rename_column :read_marks, :reader_id, :member_id
    add_index :read_marks, [:readable_type, :readable_id]
    add_index :read_marks, [:member_id]
  end
end
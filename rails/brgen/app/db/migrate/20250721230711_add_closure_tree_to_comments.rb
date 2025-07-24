class AddClosureTreeToComments < ActiveRecord::Migration[7.2]
  def change
    add_column :comments, :parent_id, :integer
    add_column :comments, :children_count, :integer, default: 0
    
    add_index :comments, :parent_id
  end
end

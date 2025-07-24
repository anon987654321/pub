class CreateDirectMessages < ActiveRecord::Migration[7.2]
  def change
    create_table :direct_messages do |t|
      t.integer :sender_id, null: false
      t.integer :recipient_id, null: false
      t.text :content, null: false
      t.datetime :read_at

      t.timestamps
    end
    
    add_foreign_key :direct_messages, :users, column: :sender_id
    add_foreign_key :direct_messages, :users, column: :recipient_id
    add_index :direct_messages, [:sender_id, :recipient_id]
  end
end

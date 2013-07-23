class CreateTodoItems < ActiveRecord::Migration
  def self.up
    create_table :todo_items do |t|
      t.integer :user_id
      t.boolean :complete, :default => false
      t.text :description, :default => ""

      t.timestamps
    end
  end

  def self.down
    drop_table :todo_items
  end
end

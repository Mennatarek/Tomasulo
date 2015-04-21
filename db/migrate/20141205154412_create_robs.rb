class CreateRobs < ActiveRecord::Migration
  def change
    create_table :robs do |t|
      t.integer :number
      t.string :instruction_type
      t.string :destination_register_name
      t.string :value
      t.boolean :ready
      t.boolean :tail
      t.boolean :head
      t.integer :cycle_id
      t.boolean :flushed
      
      t.timestamps
    end
  end
end

class CreateMemAccesses < ActiveRecord::Migration
  def change
    create_table :mem_accesses do |t|
      t.integer :cycle_id
      t.integer :cache_level_id
      t.string :mem_type
      t.boolean :is_read
      t.boolean :is_write
      t.boolean :hit
      t.integer :program_id
      t.integer :data_memory_id
      t.integer :instruction_memory_id
      t.timestamps
    end
  end
end

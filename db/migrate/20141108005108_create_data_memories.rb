class CreateDataMemories < ActiveRecord::Migration
  def change
    create_table :data_memories do |t|
      t.string :address
      t.string :value
      t.integer :cycle_id
      t.boolean :is_changed
      t.timestamps
    end
  end
end

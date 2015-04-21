class CreateActivities < ActiveRecord::Migration

#relation between instruction memory and activities 
  def change
    create_table :activities do |t|
      t.integer :instruction_memory_id
      t.string :instruction_memory_value
      t.integer :fetched
      t.integer :issued
      t.integer :executed
      t.integer :written
      t.integer :commited
      t.integer :cycle_id
      t.integer :number
      t.boolean :flushed, default: false
      t.integer :reservation_station_number
      t.integer :rob_number
      t.integer :waiting
      t.boolean :started_writing
      t.boolean :started_reading
      t.boolean :finished_writing
      t.boolean :finished_reading
      t.integer :data_cache_id

      t.timestamps
    end
  end
end

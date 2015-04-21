class CreatePrograms < ActiveRecord::Migration
  def change
    create_table :programs do |t|
      t.text :labels
      t.string :counter
      t.string :name
      t.text :code
      t.text :data
      t.integer :main_memory_access_time
      t.integer :memory_capacity
      t.integer :starting_address
      t.integer :pipeline_width
      t.integer :size_of_instruction_buffer
      t.integer :number_of_rob_enteries
      t.integer :_activity_counter, default: 0
      t.text :number_of_reservation_stations
      t.text :number_of_cycles_needed
      t.timestamps
    end
  end
end

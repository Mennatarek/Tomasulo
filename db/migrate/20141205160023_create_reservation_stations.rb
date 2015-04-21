class CreateReservationStations < ActiveRecord::Migration
  def change
    create_table :reservation_stations do |t|
      t.integer :remaining_cycles
      t.string :station_type
      t.string :name
      t.boolean :busy, default: false
      t.string :operation
      t.string :vk
      t.string :vj
      t.integer :qj
      t.integer :qk
      t.integer :destination
      t.string :address
      t.integer :cycle_id
      t.integer :number
      t.boolean :flushed
      t.timestamps
    end
  end
end

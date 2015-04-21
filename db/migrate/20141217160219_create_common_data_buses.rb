class CreateCommonDataBuses < ActiveRecord::Migration
  def change
    create_table :common_data_buses do |t|
      t.integer :cycle_id
      t.integer :activity_number
      t.string :register_name
      t.string :address
      t.string :value

      t.timestamps
    end
  end
end

class CreateCycles < ActiveRecord::Migration
  def change
    create_table :cycles do |t|
      t.integer :program_id
      t.integer :cycle_number

      t.timestamps
    end
  end
end

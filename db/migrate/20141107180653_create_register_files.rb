class CreateRegisterFiles < ActiveRecord::Migration
  def change
    create_table :register_files do |t|
      t.integer :cycle_id

      t.timestamps
    end
  end
end

class CreateRegisters < ActiveRecord::Migration
  def change
    create_table :registers do |t|
      t.string :name
      t.string :value
      t.integer :register_file_id
      t.boolean :is_changed
      t.integer :status, default: 0
      
      t.timestamps
    end
  end
end

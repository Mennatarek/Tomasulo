class CreateDataCaches < ActiveRecord::Migration
  def change
    create_table :data_caches do |t|
      t.integer :cache_level_id
      t.string :address
      t.string :value
      t.integer :cycle_id
      t.boolean :dirty_bit
      t.boolean :hit
      t.boolean :is_changed
      t.string :offset
      t.string :tag
      t.string :index
      t.timestamps
    end
  end
end

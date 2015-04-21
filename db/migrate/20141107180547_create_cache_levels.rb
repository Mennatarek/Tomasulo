class CreateCacheLevels < ActiveRecord::Migration
  
  def change
    create_table :cache_levels do |t|
      t.integer :number
      t.integer :size
      t.integer :line_size
      t.integer :associativity
      t.integer :offset_bits
      t.integer :tag_bits
      t.integer :index_bits
      t.integer :sets
      t.string :policy
      t.integer :number_of_cycles_to_access_data
      t.integer :program_id
      t.string :cache_type
      t.timestamps
    end
  end
end

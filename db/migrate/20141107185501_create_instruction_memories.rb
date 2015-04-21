class CreateInstructionMemories < ActiveRecord::Migration
  def change
    create_table :instruction_memories do |t|
      t.string :instruction_type
      t.string :name
      t.string :rs_name
      t.string :rt_name
      t.string :rd_name
      t.string :imm_value
      t.integer :number_of_cycles
      t.integer :program_id
      t.string :address
      t.string :value
      t.boolean :is_changed
      t.boolean :prediction_taken, default: true
      t.boolean :branch_mispredicted, default: false

      t.timestamps
    end
  end
end

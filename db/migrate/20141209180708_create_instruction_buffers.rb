class CreateInstructionBuffers < ActiveRecord::Migration
  def change
    create_table :instruction_buffers do |t|
      t.integer :instruction_memory_id
      t.integer :cycle_id

      t.timestamps
    end
  end
end

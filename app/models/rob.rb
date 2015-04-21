class Rob < ActiveRecord::Base
	belongs_to :cycle


  # integer :number
  # string :instruction_type
  # string :destination_register_name
  # string :value
  # boolean :ready
  # boolean :tail
  # boolean :head
  # integer :cycle_id

	def self.using_registers?(instruction, cycle)
		if rs = instruction.rs_name
			return true if Rob.exists?(destination_register_name: rs, cycle: cycle)
		end
		if rt = instruction.rt_name
			return true if Rob.exists?(destination_register_name: rt, cycle: cycle)
		end
		return false
	end


	def self.add!(instruction, cycle)
		rob = self.find_by(tail: true, cycle: cycle)
		rob.update(instruction_type: instruction.instruction_type, destination_register_name: instruction.rd_name, ready: false, tail: false)
		if new_rob = Rob.find_by(cycle: cycle, number: ( ( (rob.number+1) % cycle.program.number_of_rob_enteries) + 1) , destination_register_name: nil)
			new_rob.update(tail: true)
		end
		rob
	end

	def self.has_space?(cycle, instruction)
		self.exists?(tail: true, cycle: cycle)
	end

end

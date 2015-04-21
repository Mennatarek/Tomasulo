class InstructionBuffer < ActiveRecord::Base
	belongs_to :instruction, class_name: :InstructionMemory, foreign_key: :instruction_memory_id
	belongs_to :cycle


	def self.read(cycle)
		inst = InstructionBuffer.find_by(cycle: cycle)
		inst.destroy
		inst.instruction
	end

	def self.issuable?(cycle)
		return false unless buff = InstructionBuffer.find_by(cycle: cycle)
		if buff.instruction.reservable?
			return cycle.reservation_stations.exists?(station_type: buff.instruction.instruction_type, busy: false)
		end
		true
	end

	def self.has_space?(cycle)
		InstructionBuffer.where(cycle: cycle).count < cycle.program.size_of_instruction_buffer
	end

	def self.add!(instruction, cycle)
		InstructionBuffer.create(instruction: instruction, cycle: cycle)
	end

	def self.remove!(instruction, cycle)
		if buff = InstructionBuffer.find_by(instruction: instruction, cycle: cycle)
			buff.destroy
		end
	end

end

class InstructionMemory < ActiveRecord::Base
	belongs_to :program
	has_many :instruction_buffers

	def self.read(cycle)
		counter , program = cycle.program.counter , cycle.program
		program.pipeline_width.times do
			instruction = InstructionMemory.find_by(program: program, address: counter)
			if InstructionBuffer.has_space?(cycle)
				if instruction.fetchable?(cycle)
					Activity.add_fetch(instruction, cycle)
					counter = add_bin_int(counter, 1)
				else
					case instruction.name
					when "RET"
						if r = cycle.registers.find_by(name: instruction.rd_name, status: 0)
							# Return: branches (unconditionally) to the address stored in regA
							# RET regA
							counter = r.value
							Activity.add_fetch(instruction, cycle)
						else
							break
						end
					when "JMP"
						if r =  cycle.registers.find_by(name: instruction.rd_name, status: 0)
							# Jump: branches to the address PC+1+regA+imm
							# JMP regA, imm
							counter = add_bin(  add_bin_int(counter, 1) , add_bin(instruction.imm_value, r.value) )
							Activity.add_fetch(instruction, cycle)
						else
							break
						end
					when "JALR"
						if r = cycle.registers.find_by(name: instruction.rs_name, status: 0)
							# Jump and link register: Stores the value of PC+1 in regA and branches (unconditionally) to the address in regB.
							# JALR regA, regB
							counter = r.value
							Activity.add_fetch(instruction, cycle)
						else
							break
						end
					when "BEQ"
						Activity.add_fetch(instruction, cycle)
						if instruction.imm_value.starts_with? "1"
							counter = add_bin(  add_bin_int(counter, 1) , instruction.imm_value )
						else
							instruction.update(prediction_taken: false)
							counter = add_bin_int(counter, 1)
						end
					end
				end
			end
		end
		program.update(counter: counter)
	end

	def reservable?
		["add", "load", "store", "mult", "and"].include? self.instruction_type
	end

	def fetchable?(cycle)
		not ["RET", "JMP", "JALR", "BEQ"].include? self.name
	end

    def self.add_bin(add1, add2) #adds 2 bin numbers
      self.int_to_bin( self.bin_to_int(add1) + self.bin_to_int(add2) )
    end

    def self.add_bin_int(add1, value) #adds bin and int
      self.int_to_bin( self.bin_to_int(add1) + value)
    end

    def self.int_to_bin(value) #converts from int to bin
      value.to_s(2).rjust(16, '0')
    end

    def self.bin_to_int(value) #converts from bin to int
      value.to_i(2)
    end

end

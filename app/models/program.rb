class Program < ActiveRecord::Base
	attr_accessor :number_of_levels
	serialize :number_of_reservation_stations, Hash
	serialize :number_of_cycles_needed, Hash

	has_many :cache_levels
	has_many :cycles
	has_many :instruction_memories

	accepts_nested_attributes_for :cache_levels#, reject_if: lambda { |a| ( a[:size].to_i == -1) }

	before_create :prepare_instructions

	def self.compile(input=nil)
		code_array = input.split("#DATA")[0].gsub("\r", "").split("\n")
		code_array.each_with_index do |code_line, index|
			line = code_line.split(/[ ]*[,][ ]*|[ ]/)
			case line[0]
			## 1. Load/store
		when "LW"
					# Load word: Loads value from memory into regA. 
					# Memory address is formed by adding imm with contents of regB, 
					# where imm is a 7-bit signed immediate value (ranging from -64 to 63).
					# LW regA, regB, imm
					return index unless line.length == 4 and write_register?(line[1]) and read_register?(line[2]) and line[3].to_i.is_a? Integer
					puts "Load #{line}"
				when "SW"
					# Store word: Stores value from regA into memory. 
					# Memory address is computed as in the case of the load word instruction
					# SW regA, regB, imm
					return index unless line.length == 4 and write_register?(line[1]) and read_register?(line[2]) and line[3].to_i.is_a? Integer
					puts "store #{line}"
			## 2. Unconditional branch
		when "JMP"
					# Jump: branches to the address PC+1+regA+imm
					# JMP regA, imm
					return index unless line.length == 3 and read_register?(line[1]) and line[3].to_i.is_a? Integer
					puts "jump #{line}"
			## 3. Conditional branch
		when "BEQ"
					# Branch if equal: branches to the address PC+1+imm if regA=regB
					# BEQ regA, regB, imm
					return index unless line.length == 4 and read_register?(line[1]) and read_register?(line[2]) and line[3].to_i.is_a? Integer
					puts "Branch if equal #{line}"
			## 4. Call/Return
		when "JALR"
					# Jump and link register: Stores the value of PC+1 in regA and branches (unconditionally) to the address in regB.
					# JALR regA, regB
					return index unless line.length == 3 and write_register?(line[1]) and read_register?(line[2]) 
					puts "Jump and link register #{line}"
				when "RET"
					# Return: branches (unconditionally) to the address stored in regA
					# RET regA
					return index unless line.length == 2 and read_register?(line[1])
					puts "Return: branches #{line}"
			## 5. Arithmetic
		when "ADDI"
					# Add immediate: Adds the value of regB to imm storing the result in regA
					# ADDI regA, regB, imm
					return index unless line.length == 4 and write_register?(line[1]) and read_register?(line[2]) and line[3].to_i.is_a? Integer
					puts "Add immediate: #{line}"
				when "ADD"
					# Add: Adds the value of regB and regC storing the result in regA.
					# ADD regA, regB, regC
					return index unless line.length == 4 and write_register?(line[1]) and read_register?(line[2]) and read_register?(line[3])
					puts "ADD #{line}"
				when "SUB"
					# Subtract: Subtracts the value of regC from regB storing the result in regA.
					# SUB regA, regB, regC
					return index unless line.length == 4 and write_register?(line[1]) and read_register?(line[2]) and read_register?(line[3])
					puts "Subtract #{line}"
				when "NAND"
					# Nand: Performans a bitwise NAND operation between the values of regB and regC storing the result in regA
					# NAND regA, regB, regC
					return index unless line.length == 4 and write_register?(line[1]) and read_register?(line[2]) and read_register?(line[3])
					puts "NAND #{line}"
				when "MUL"
					# Multiply: Multiplies the value of regB and regC storing the result in regA
					# MUL regA, regB, regC
					return index unless line.length == 4 and write_register?(line[1]) and read_register?(line[2]) and read_register?(line[3])
					puts "Multiply #{line}"
				when "END"
					puts "END #{line}"
				else
					puts "ERORRRRRRRRRR"
				end
				
			end

		if input.split("#DATA").length > 1 and data_code = input.split("#DATA")[1]
			puts data_code
			data_array = data_code.gsub("\r", "").split("\n")
			data_array.each_with_index do |data_line, index|
				line = data_line.split(" ")
				if line[1].to_i >32000 || line[1].to_i <0
					return index + code_array.length
				elsif line[0].to_i > 64 || line[0].to_i < -63 
					return index + code_array.length
				end
			end	
		end
		true
	end

	def prepare_instructions
		self.counter = self.starting_address.to_i.to_s(2).rjust(16, '0')
		code_array = self.code.split("#DATA")[0].gsub("\r", "").split("\n")
		code_array.each_with_index do |code_line, index|
			line = code_line.split(/[ ]*[,][ ]*|[ ]/)
			case line[0]
			when "SW"
				instruction = self.instruction_memories.build(instruction_type: "store",name: line[0],rd_name: line[1],rs_name: line[2],imm_value: line[3].to_i.to_s(2).rjust(16, '0'),address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "LW" 
				instruction = self.instruction_memories.build(instruction_type: "load",name: line[0],rd_name: line[1],rs_name: line[2],imm_value: line[3].to_i.to_s(2).rjust(16, '0'),address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "JMP"
				instruction = self.instruction_memories.build(name: line[0],rd_name: line[1],imm_value: line[2].to_i.to_s(2).rjust(16, '0'),address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "BEQ"
				instruction = self.instruction_memories.build(name: line[0],rd_name: line[1],rs_name: line[2],imm_value: line[3].to_i.to_s(2).rjust(16, '0'),address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "JALR"
				instruction = self.instruction_memories.build(name: line[0],rd_name: line[1],rs_name: line[2],imm_value: line[3].to_i.to_s(2).rjust(16, '0'),address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "RET"
				instruction = self.instruction_memories.build(name: line[0],rd_name: line[1],address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "ADDI"
				instruction = self.instruction_memories.build(instruction_type: "add",name: line[0],rd_name: line[1],rs_name: line[2],imm_value: line[3],address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "ADD" ,"SUB"
				instruction = self.instruction_memories.build(instruction_type: "add",name: line[0],rd_name: line[1],rs_name: line[2],rt_name: line[3],address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "MUL"
				instruction = self.instruction_memories.build(instruction_type: "mult",name: line[0],rd_name: line[1],rs_name: line[2],rt_name: line[3],address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)
			when "NAND"
				instruction = self.instruction_memories.build(instruction_type: "and", name: line[0],rd_name: line[1],rs_name: line[2],rt_name: line[3],address: (self.starting_address + index).to_s(2).rjust(16, '0'),value: code_line)

			when "END"
				puts "END #{line}"
			else
				puts "ERORRRRRRRRRR"
			end
		end
		cycle = self.cycles.build(cycle_number: 1)
		register_file = cycle.build_register_file
		Program.read_registers.each do |r_name|
			register_file.registers.build(name: r_name, value: "0000000000000000")
		end
		if self.code.split("#DATA").length > 1
			data_code = self.code.split("#DATA")[1]
			data_array = data_code.gsub("\r", "").split("\n")
			data_array.each do |data_line|
				line = data_line.split(/[ ]*[,][ ]*|[ ]/)
				cycle.data_memories.build(address: line[0].to_i.to_s(2).rjust(16, '0'), value: line[1].to_i.to_s(2).rjust(16, '0') )
			end	
		end
		key_number = 1
		self.number_of_reservation_stations.keys.each do |key|
			self.number_of_reservation_stations[key].to_i.times do |i| 
				cycle.reservation_stations.build(station_type: key, name: key + (i + 1).to_s, number: key_number)
				key_number +=1
			end
		end

		self.number_of_rob_enteries.times do |i|
			i == 0 ? cycle.robs.build(head: true, tail: true, number: i + 1) :  cycle.robs.build(number: i + 1)
		end
		self.number_of_cycles_needed["ADDI"] = self.number_of_cycles_needed["ADD"]
	end

	def self.read_register?(r)
		self.read_registers.include?(r)
	end

	def self.write_register?(r)
		self.read_registers.drop(1).include?(r)
	end

	def self.read_registers
		["$0", "$1", "$2", "$3", "$4", "$5", "$6", "$7"]
	end

	def increment_counter!
		self.update(counter: self.counter + 1 )
	end

	def increment_activity_counter!
		self.update(_activity_counter: self._activity_counter + 1 )
		self._activity_counter
	end
end

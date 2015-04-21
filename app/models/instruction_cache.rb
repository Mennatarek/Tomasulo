class InstructionCache < ActiveRecord::Base
		belongs_to :cycle
		belongs_to :cache_level

	def self.read_by_index_and_tag_and_offset(cycle, level, address)
		InstructionCache.find_by(index: level.index_of(address), tag: level.tag_of(address), offset: level.offset_of(address) ,cycle: cycle, cache_level: level)
	end

	def self.read_by_index_and_tag(cycle, level, address)
		InstructionCache.find_by(index: level.index_of(address), tag: level.tag_of(address), cycle: cycle, cache_level: level)
	end

	def self.read_by_index(cycle, level, address)
		InstructionCache.find_by(index: level.index_of(address), cycle: cycle, cache_level: level)
	end

	def self.has_cache_space?(cycle, level, address)
		InstructionCache.with_in_same_tag(cycle, level, address).count < level.words_per_block
	end

	def self.with_in_same_tag(cycle, level, address)
		InstructionCache.where(index: level.index_of(address) , cycle: cycle, cache_level: level).select { |inst_ca| level.have_similar_tag?(level.tag_of(address), level.tag_of(inst_ca.address)) }
	end

	def self.cache_read(cycle, address)
		cycle.program.cache_levels.instructions_only.each do |level|
			number_of_cycles = level.number == 1 ? level.number_of_cycles_to_access_data - 1 : level.number_of_cycles_to_access_data
			number_of_cycles.times { cycle = cycle.program.cycles.create!(cycle_number: (cycle.cycle_number + 1 ) )}
			if inst = InstructionCache.read_by_index_and_tag_and_offset(cycle, level, address)
				#Hit
				inst.update(hit: true)
				level.access_memory!(cycle, "read", true)
				inst.write_to_previous_levels!
				return inst
			end
			level.access_memory!(cycle, "read", false)
		end

		inst_mem = InstructionMemory.read(cycle.program)
		cache_level = cycle.program.cache_levels.instructions_only.last
		inst = InstructionCache.write(cycle, cache_level, inst_mem)
		inst.write_to_previous_levels!
		inst
	end

	def write_to_previous_levels!
		self.cycle.program.cache_levels.instructions_only.where("number < ?", self.cache_level.number).each do |level|	
			InstructionCache.write(self.cycle, level, self)
		end
	end

	def self.write(cycle, level, instruction)
		unless InstructionCache.has_cache_space?(cycle, level, instruction.address)
			InstructionCache.with_in_same_tag(cycle, level, instruction.address).first.destroy
		end
		InstructionCache.create!(name: instruction.name, rs_name: instruction.rs_name, rt_name: instruction.rt_name, rd_name: instruction.rd_name, imm_value: instruction.imm_value, cache_level: level, address: instruction.address, offset: level.offset_of(instruction.address), index: level.index_of(instruction.address),tag: level.tag_of(instruction.address), cycle: cycle, value: instruction.value, is_changed: true)
	end
end

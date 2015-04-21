class DataCache < ActiveRecord::Base
	belongs_to :cycle
	belongs_to :cache_level


	def memory_address
		self.cache_level.memory_address_of(self.address)
	end

	def self.read_by_index_and_tag_and_offset(cycle, level, address)
		DataCache.find_by(index: level.index_of(address), tag: level.tag_of(address), offset: level.offset_of(address), cycle: cycle, cache_level: level)
	end

	def self.read_by_index_and_tag(cycle, level, address)
		DataCache.find_by(level.index_of(address), tag: level.tag_of(address), cycle: cycle, cache_level: level)
	end

	def self.read_by_index(cycle, level, address)
		DataCache.find_by(index: level.index_of(address), cycle: cycle, cache_level: level)
	end

	def self.has_cache_space?(cycle, level, address)
		DataCache.with_in_same_tag(cycle, level, address).count < level.words_per_block
	end

	def self.with_in_same_tag(cycle, level, address)
		DataCache.where(index: level.index_of(address) ,cycle: cycle, cache_level: level).select { |dat_ca| level.have_similar_tag?(level.tag_of(address), level.tag_of(dat_ca.address)) }
	end

	def self.cache_write(address,cycle,value,activity)
		new_data = nil
		cycle.program.cache_levels.data_only.each do |level|
			number_of_cycles = level.number == 1 ? level.number_of_cycles_to_access_data - 1 : level.number_of_cycles_to_access_data
			number_of_cycles.times { cycle = cycle.program.cycles.create!(cycle_number: (cycle.cycle_number + 1 ) )}
			
			if new_data = DataCache.read_by_index_and_tag_and_offset(cycle, level, address)
				new_data.update(hit: true, value: value, dirty_bit: level.policy == "write_back" )
				level.access_memory!(cycle, "write", true)
			else
				level.access_memory!(cycle, "write", false)
				if DataCache.has_cache_space?(cycle, level, address)
					if level.policy == "write_back"
						#dirty bit
						new_data = DataCache.write_value(cycle, level, address, value, true)
					else
						#write fel mem
						new_data = DataCache.write_value(cycle, level, address, value)
					end
				else
					tmp = DataCache.with_in_same_tag(cycle, level, address).first
					DataMemory.write(cycle, tmp.address, tmp.value) and tmp.destroy if tmp.dirty_bit
					if level.policy == "write_back"
						#dirty bit
						new_data = DataCache.write_value(cycle, level, address, value, true)
					else
						#write fel mem
						new_data = DataCache.write_value(cycle, level, address, value)
					end
				end
			end
			DataMemory.write(cycle, new_data.memory_address, new_data.value) unless level.policy == "write_back"
		end
		activity.update(finished_writing: true)
		new_data
	end


	def self.cache_read(cycle,address,activity)
		cycle.program.cache_levels.instructions_only.each do |level|
			number_of_cycles = level.number == 1 ? level.number_of_cycles_to_access_data - 1 : level.number_of_cycles_to_access_data
			number_of_cycles.times { cycle = cycle.program.cycles.create!(cycle_number: (cycle.cycle_number + 1 ) )}
			if data = DataCache.read_by_index_and_tag_and_offset(cycle, level, address)
				#Hit
				data.update(hit: true)
				level.access_memory!(cycle, "read", true)
				data.write_to_previous_levels!
				return data
			end
			level.access_memory!(cycle, "read", false)
		end

		data_mem = DataMemory.read(cycle, address)
		cache_level = cycle.program.cache_levels.data_only.last
		data = DataCache.write_afer_read(cycle, cache_level, data_mem)
		data.write_to_previous_levels!
		activity.update(finished_reading: true)
		data
	end


	def write_to_previous_levels!
		self.cycle.program.cache_levels.data_only.where("number < ?", self.cache_level.number).each do |level|	
			DataCache.write_afer_read(self.cycle,level, self)
		end
	end

	def self.write_afer_read(cycle, level, data)
		unless DataCache.has_cache_space?(cycle, level, data.address)
			tmp = DataCache.with_in_same_tag(cycle, level, data.address).first
			DataMemory.write(cycle, tmp.address, tmp.value) and tmp.destroy if tmp.dirty_bit
		end
		DataCache.write(cycle, level, data)
	end

	def self.write(cycle, level, data)
		DataCache.create!(cache_level: level, address: level.cache_address_of(data.address), offset: level.offset_of(data.address), index: level.index_of(data.address),tag: level.tag_of(data.address), cycle: cycle, value: data.value, is_changed: true)
	end

	def self.write_value(cycle, level, address, value, dirty_bit=nil)
		DataCache.create!(cache_level: level, address: level.cache_address_of(address), offset: level.offset_of(address), index: level.index_of(address),tag: level.tag_of(address), cycle: cycle, value: value, is_changed: true, dirty_bit: dirty_bit)
	end

end

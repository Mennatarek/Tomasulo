class DataMemory < ActiveRecord::Base
	belongs_to :cycle

	def self.read(cycle, address)
		DataMemory.find_by(cycle: cycle, address: address)
	end

	def self.write(cycle ,address ,value)
		if dm = DataMemory.find_by(cycle: cycle, address: address)
			dm.destroy
		end
		DataMemory.create(cycle: cycle, address: address, value: value, is_changed: true)
	end
end

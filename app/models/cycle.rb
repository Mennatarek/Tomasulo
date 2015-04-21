class Cycle < ActiveRecord::Base	
	has_one :register_file
	has_many :registers, through: :register_file
	has_many :data_caches, class_name: :DataCache
	has_many :data_memories
	has_one :mem_accesses
	has_many :activities
	has_many :reservation_stations
	has_many :robs
	has_many :instruction_buffers
	has_many :common_data_buses
	belongs_to :program

	after_create :copy_old_cycle!

	def next_cycle
		unless cycle = Cycle.find_by(program: self.program, cycle_number: self.cycle_number + 1)
			cycle = Cycle.create(program: self.program, cycle_number: self.cycle_number + 1)
		end
		cycle.copy_cycle!
		cycle
	end

	def copy_old_cycle!
		if self.cycle_number > 1
			prevoious_cycle = self.program.cycles.find_by(cycle_number: (self.cycle_number-1))

			## Copying cached Data From Previous Cycle
			prevoious_cycle.data_caches.each do |dc|
				self.data_caches.create!(cache_level_id: dc.cache_level_id,address: dc.address,value: dc.value, hit: dc.hit, dirty_bit: dc.dirty_bit)
			end

			## Copy Data Memory
			prevoious_cycle.data_memories.each do |dm|
				self.data_memories.create!(address: dm.address,value: dm.value)
			end
		end
	end

	def copy_cycle!
		prevoious_cycle = self.program.cycles.find_by(cycle_number: (self.cycle_number-1))

		## Copy Register File
		register_file = self.create_register_file

		## Copy Registers
		prevoious_cycle.register_file.registers.each do |r|
			register_file.registers.create!(name: r.name,value: r.value, status: r.status)
		end

		## copy activites	
		prevoious_cycle.activities.not_flushed.each do |a|
			self.activities.create!(instruction_memory: a.instruction_memory,fetched: a.fetched,executed: a.executed, issued: a.issued, written: a.written, commited: a.commited, number: a.number, reservation_station_number: a.reservation_station_number, waiting: a.waiting,started_reading: a.started_reading,started_writing: a.started_writing,finished_reading: a.finished_reading,finished_writing: a.finished_writing,data_cache_id: a.data_cache_id, rob_number: a.rob_number)
		end

		## copy ROB	
		prevoious_cycle.robs.each do |r|
			self.robs.create!(number: r.number, instruction_type: r.instruction_type, destination_register_name: r.destination_register_name, value: r.value, ready: r.ready, tail: r.tail, head: r.head )
		end

		## copy Reservation Stations	
		prevoious_cycle.reservation_stations.each do |r|
			self.reservation_stations.create!(remaining_cycles: r.remaining_cycles, name: r.name, busy: r.busy, operation: r.operation, vk: r.vk, vj: r.vj, qj: r.qj, qk: r.qk, destination: r.destination, address: r.address, number: r.number, station_type: r.station_type)
		end

		prevoious_cycle.instruction_buffers.each do |ib|
			self.instruction_buffers.create!(instruction_memory_id: ib.instruction_memory_id)
		end

		prevoious_cycle.common_data_buses.each do |dcb|
			self.common_data_buses.create(activity_number: dcb.activity_number,register_name: dcb.register_name, address: dcb.address, value: dcb.value )
		end

	end

	def clean_up_after_commit!(rob)
		rob.update(destination_register_name: nil, value: nil, ready: false, head: false)
		Rob.find_by(cycle: self, number: (rob.number + 1 % self.program.number_of_rob_enteries)).update(head: true)
	end
end

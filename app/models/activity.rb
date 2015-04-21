class Activity < ActiveRecord::Base
	belongs_to :instruction_memory
	belongs_to :cycle
	belongs_to :data_cache

	scope :for_program, ->(program_id) {joins(:cycle).where(cycles: {program_id: program_id})}
	scope :flushed, ->{where(flushed: true)}
	scope :not_flushed, ->{where(flushed: false)}
	scope :since_created, ->(activity) {not_flushed.for_program(activity.cycle.program_id).where("( activities.issued IS NULL OR activities.issued >= ? ) AND activities.number > ? ", activity.issued, activity.number) }
	scope :recent, -> {order("id ASC")}
	scope :waiting, ->(cycle) {where("waiting IS NOT NULL").where(cycle: cycle)}
	scope :finishing_execution, ->(cycle) {waiting(cycle).where(waiting: cycle.cycle_number)}
	scope :for_rob, ->(rob, cycle) {where(cycle: cycle, rob_number: rob.number)}

	def self.add_fetch(instruction, cycle)
		InstructionBuffer.add!(instruction, cycle)
		Activity.create(instruction_memory: instruction, cycle: cycle, fetched: cycle.cycle_number, number: cycle.program.increment_activity_counter!)
	end

	def self.add_issue(instruction, cycle,reservation_station_number=nil, rob_number=nil)
		Activity.recent.find_by(instruction_memory: instruction, cycle: cycle, issued: nil).update(issued: cycle.cycle_number,reservation_station_number: reservation_station_number, rob_number: rob_number)
		InstructionBuffer.remove!(instruction, cycle)
	end

	def self.add_execute(instruction, cycle)
		Activity.recent.find_by(instruction_memory: instruction, cycle: cycle, executed: nil).update(executed: (cycle.cycle_number + (cycle.program.number_of_cycles_needed["#{instruction.name}"] || 0)))
	end

	def self.add_write(instruction, cycle)
		Activity.recent.find_by(instruction_memory: instruction, cycle: cycle, written: nil).update(written: cycle.cycle_number)
	end

	def self.add_commit(instruction, cycle)
		Activity.recent.find_by(instruction_memory: instruction, cycle: cycle, commited: nil).update(commited: cycle.cycle_number)
	end

	def self.can_execute(cycle)
		Activity.recent.where(cycle: cycle, executed: nil).where("issued IS NOT NULL AND issued < ?", cycle.cycle_number)
	end

	def self.can_write(cycle)
		Activity.order('issued ASC, id ASC').where(cycle: cycle, written: nil).where("executed IS NOT NULL AND executed < ?", cycle.cycle_number)
	end

	def self.can_commit(cycle)
		Activity.recent.where(cycle: cycle, commited: nil).where("written IS NOT NUL written < ?", cycle.cycle_number)
	end

	def flush
		Activity.since_created(self).each do |activity|
			# if activity.cycle_id >= self.cycle_id
			# 	if rs = ReservationStattion.find_by(number: activity.reservation_station_number, cycle: activity.cycle)
			# 		if r1 = activity.cycle.registers.find_by(name: rs.vj)
			# 			r1.update(status: 0)
			# 		end
			# 		if r2 = activity.cycle.registers.find_by(name: rs.vk)
			# 			r2.update(status: 0)
			# 		end
			# 		if rob = rs.rob
			# 			rob.remove!
			# 		end
			# 		rs.remove!
			# 	end
			# 	activity.destroy
			# else

				if rs = ReservationStattion.find_by(number: activity.reservation_station_number, cycle: activity.cycle)
					if r1 = activity.cycle.registers.find_by(name: rs.vj)
						r1.update(status: 0)
					end
					if r2 = activity.cycle.registers.find_by(name: rs.vk)
						r2.update(status: 0)
					end
					if rob = rs.rob
						rob.update(flushed: true)
					end
					rs.update(flushed: true)
				end
				acivity.update(flushed: true)
			end
		# end
		InstructionBuffer.where(cycle: self.cycle).destroy_all
	end

	def reservation_station
		ReservationStation.find_by(number: self.reservation_station_number, cycle: self.cycle)
	end
end

class ReservationStation < ActiveRecord::Base
	belongs_to :cycle

# :remaining_cycles
# :station_type
# :name
# :busy
# :operation
# :vk
# :vj
# :qj
# :qk
# :destination
# :address
# :cycle_id

def self.add!(instruction, cycle, rob1)
	station = self.find_by(busy: false, station_type: instruction.instruction_type, cycle: cycle)
	rs = cycle.registers.find_by(name: instruction.rs_name)
	rt = cycle.registers.find_by(name: instruction.rt_name)
	case instruction.name
	when "LW", "SW", "ADDI"
		station.update(busy: true, operation: instruction.name, vk: (rs.status == 0 ? rs.name : nil), vj: nil, qk: (rs.status != 0 ? rs.status : nil), qj: nil, destination: rob1.number, address: instruction.imm_value )
	else
		station.update(busy: true, operation: instruction.name, vk: (rs.status == 0 ? rs.name : nil), vj: (rt.status == 0 ? rt.name : nil), qk: (rs.status != 0 ? rs.status : nil), qj: (rt.status != 0 ? rt.status : nil), destination: rob1.number, address: nil)
		rs.update(status: station.number) if rs.status == 0 
		rt.update(status: station.number) if rt.status == 0 
	end
	station
end

def remove!
	self.update(busy: false, operation: nil, vk: nil, vj: nil, qk: nil, qj: nil, destination: nil, address: nil)
end

	# def self.has_space?(cycle, instruction)
	# 	self.exists?(busy: false, station_type: instruction.instruction_type, cycle: cycle)
	# end

	def rob
		self.cycle.robs.find_by(number: self.destination)
	end

	def executable?
		(self.qj==nil and self.qk==nil) ? true : false
	end

	def self.remove_stalls(cycle,res)
		awel_wa7da = nil
		self.where(cycle: cycle).joins('JOIN activities AS a ON a.reservation_station_number = reservation_stations.number AND a.cycle_id = reservation_stations.cycle_id').where("a.executed IS NULL").order("a.issued DESC").where("reservation_stations.qk = ? OR reservation_stations.qj = ?",res.number, res.number).each_with_index do |res_sta, index|
			if index == 0
				awel_wa7da = res_sta
				if res_sta.qj == res.number
					res_sta.update(qj: 0,vj: res_sta.activity.instruction_memory.rs_name)
				end
				if res_sta.qk == res.number
					res_sta.update(qk: 0,vk: res_sta.activity.instruction_memory.rt_name)
				end	
			else
				if res_sta.qj == res.number
					res_sta.update(qj: awel_wa7da.number)
				end
				if res_sta.qk == res.number
					res_sta.update(qk: awel_wa7da.number)
				end	
			end
		end	
	end

	def activity
		Activity.where(cycle: cycle).joins("JOIN reservation_stations AS rs reservation_station_number = #{self.number} AND rs.cycle_id = cycle_id").first
	end
end

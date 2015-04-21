class CommonDataBus < ActiveRecord::Base
	belongs_to :cycle
	#syntax
	scope :oldest, ->(cycle) {order("id ASC").where(cycle: cycle)}

end

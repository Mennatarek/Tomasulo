class RegisterFile < ActiveRecord::Base
	belongs_to :cycle
	has_many :registers
end

class CacheLevel < ActiveRecord::Base
	belongs_to :program

	before_create :split_address
	has_many :mem_accesses

	scope :instructions_only, ->{where(cache_type: "instruction").order("number ASC")}
	scope :data_only, ->{where(cache_type: "data").order("number ASC")}

	def split_address
		self.offset_bits = Math.log2(self.line_size/2)
		self.index_bits = Math.log2(number_of_sets)
		self.tag_bits = 16 - (self.offset_bits + self.index_bits)
	end

	def offset_of(address)
		address.length < 17 ? (address << "0").rjust(17, "0") : address
		address[self.tag_bits+self.index_bits..15]
	end

	def index_of(address)
		address.length < 17 ? (address << "0").rjust(17, "0") : address
		address[self.tag_bits..self.tag_bits+self.index_bits-1]
	end

	def tag_of(address)
		address.length < 17 ? (address << "0").rjust(17, "0") : address
		address[0..self.tag_bits-1]
	end

	def words_per_block
		self.line_size/2
	end

	def number_of_sets
		(self.size * 1000)/(self.line_size * self.associativity)
	end

	def number_of_blocks
		(self.size * 1000)/self.line_size
	end

	def number_of_blocks_per_set
		self.number_of_blocks / self.number_of_sets
	end

	def have_similar_tag?(tag1, tag2)
		(bin_to_int(tag1) % self.number_of_blocks_per_set) == (bin_to_int(tag2) % self.number_of_blocks_per_set)
	end

  def int_to_bin(value) #converts from int to bin
    value.to_s(2).rjust(16, '0')
  end

  def bin_to_int(value) #converts from bin to int
    value.to_i(2)
  end

  def access_memory!(cycle, purpose, hit)
  	is_read = purpose == "read" ? true : nil
  	is_write = purpose == "write" ? true : nil
  	self.mem_accesses.create!(mem_type: self.cache_type, cycle: cycle , is_write: is_write, is_read: is_read, hit: hit, program: self.program)
  end

  def cache_address_of(address)
		address.length < 17 ? (address << "0").rjust(17, "0") : address
	end

  def memory_address_of(address)
		address.length == 17 ? address[0..15] : address
	end
# Block Offset = Memory Address mod 2^self.offset_bits

# Block Address = Memory Address / 2^n 

# Set Index = Block Address mod 2^s
end

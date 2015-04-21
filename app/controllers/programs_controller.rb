class ProgramsController < ApplicationController
  before_action :set_program, only: [ :edit, :update, :destroy]

  # GET /programs
  # GET /programs.json
  def index
    @programs = Program.all
  end

  # GET /programs/1
  # GET /programs/1.json
  def cycle_no
    @program = Program.find_by_id(params[:id])
    cycle = params[:cycle] || 1
    @cycle = @program.cycles.where(cycle_number: cycle).first
    redirect_to @program unless @cycle
  end

  def show
    @program = Program.find_by_id(params[:id])
  end

  # GET /programs/new
  def new
    @program = Program.new
  end

  # GET /programs/1/edit
  def edit
  end

  # POST /programs
  # POST /programs.json
  def create
    if @program = Program.create!(program_params)
      @cycle = @program.cycles.first
      10.times do
        commit
        write
        execute
        issue
        fetch
        @cycle = @cycle.next_cycle
        # break unless Activity.exists?(cycle: @cycle, commited: nil)
      end

      redirect_to @program
    end
  end

  def compile
    compiled = Program.compile(params[:code])
    render json: {compiled: compiled}
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_program
      @program = Program.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def program_params
      params.require(:program).permit(:name, :code, :starting_address,:number_of_rob_enteries ,:size_of_instruction_buffer, { number_of_cycles_needed: [:LW, :SW, :ADD, :SUB , :MUL, :NAND] }, { number_of_reservation_stations: [:load, :store, :add, :mult, :and] }, :pipeline_width , cache_levels_attributes: [:main_memory_access_time, :size, :line_size, :associativity, :policy, :cache_type, :number, :number_of_cycles_to_access_data])
    end

    def add_bin(add1, add2) #adds 2 bin numbers
      int_to_bin( bin_to_int(add1) + bin_to_int(add2) )
    end

    def sub_bin(add1, add2) #subs 2 bin numbers
      int_to_bin( bin_to_int(add1) - bin_to_int(add2) )
    end

    def not_bin(add1) # returns the negated bin
      add1.gsub(/[10]/, '1' => '0', '0' => '1')
    end

    def mult_bin(add1, add2) # mults 2 bins
      int_to_bin( bin_to_int(add1) * bin_to_int(add2) )
    end

    def add_bin_int(add1, value) #adds bin and int
      int_to_bin( bin_to_int(add1) + value)
    end

    def int_to_bin(value) #converts from int to bin
      value.to_s(2).rjust(16, '0')
    end

    def bin_to_int(value) #converts from bin to int
      value.to_i(2)
    end

    def fetch
      InstructionMemory.read(@cycle)
    end

    def issue
      @program.pipeline_width.times do   
        if InstructionBuffer.issuable?(@cycle)
          inst = InstructionBuffer.read(@cycle)
          if inst.reservable?
            if Rob.has_space?(@cycle, inst)
              rob = Rob.add!(inst, @cycle)
              rob_number = rob.number
              station_number = ReservationStation.add!(inst, @cycle, rob).number
            else
              break
            end
          end
          Activity.add_issue(inst, @cycle, station_number, rob_number)
        else
          break
        end
      end
    end

    def start_execution
      Activity.can_execute(@cycle).each do |activity|
        break if Activity.waiting(@cycle).count == @program.pipeline_width
        if res = activity.reservation_station
          if res.executable?
            rob = res.rob
            activity.update(waiting: @cycle.cycle_number + @cycle.program.number_of_cycles_needed[activity.instruction_memory.name].to_i-1 , started_reading: true)
          end
        end 
      end  
    end

    def end_execution
      Activity.finishing_execution(@cycle).each do |activity|
        if res = activity.reservation_station and rob = res.rob
          alu(res, rob, activity)
        else
          alu(nil, nil, activity)
        end
      end
    end

    def execute
      start_execution
      end_execution
    end

    def write
      if cdb = CommonDataBus.oldest(@cycle).first
        activity = Activity.find_by(number: cdb.activity_number,cycle: @cycle)
        activity.update(written: @cycle.cycle_number)
        res = activity.reservation_station
        rob = res.rob
        rob.update(value: cdb.value, ready: true)
        ReservationStation.remove_stalls(@cycle,res)
        res.remove!
      end
    end

    def commit
      if rob = Rob.find_by(head: true, ready: true)
        if activity = Activity.for_rob(rob, @cycle).first
          case rob.instruction_type
          when "store"
            unless activity.started_writing
              data = DataCache.cache_write(rob.destination ,@cycle ,rob.value,activity).cycle.clean_up_after_commit!(rob)
              activity.update(started_writing: true)
            else
              if activity.finished_writing
                activity.update(committed: @cycle.cycle_number)
              end
            end  
          else
            @cycle.registers.find_by(name: rob.destination_register_name).update(value: rob.value)
            @cycle.clean_up_after_commit!(rob)
            activity.update(committed: @cycle.cycle_number)
          end

        end
      end
    end

    def alu(res, rob, activity)
      instruction = activity.instruction_memory
      rs = @cycle.registers.find_by(name: instruction.rs_name)
      rt = @cycle.registers.find_by(name: instruction.rt_name)
      rd = @cycle.registers.find_by(name: instruction.rd_name)
      imm_value = instruction.imm_value
      activity.update(waiting: nil,executed: @cycle.cycle_number)
      case instruction.name
      when "ADD"
        CommonDataBus.create(cycle_id: @cycle.id,activity_number: activity.number,register_name: rd.name,value: add_bin(rs.value, rt.value))
      when "SUB"
        CommonDataBus.create(cycle_id: @cycle.id,activity_number: activity.number,register_name: rd.name,value: sub_bin(rs.value, rt.value))
      when "NAND"
        CommonDataBus.create(cycle_id: @cycle.id,activity_number: activity.number,register_name: rd.name,value: not_bin( (rs and rt)) )
      when "MUL"
        CommonDataBus.create(cycle_id: @cycle.id,activity_number: activity.number,register_name: rd.name,value: mult_bin(rs.value, rt.value))
      when "ADDI"
        CommonDataBus.create(cycle_id: @cycle.id,activity_number: activity.number,register_name: rd.name,value: add_bin(rs.value, imm_value))
      when "LW"
        unless activity.started_reading
          address = add_bin(rs.value, imm_value)
          activity.update(waiting: @cycle.cycle_number-1 , executed: nil ,started_reading: true)
          tmp_dc = DataCache.cache_read(cycle, address,activity)
          activity.update(data_cache: tmp_dc)
        else 
          if activity.finished_reading
            CommonDataBus.create(cycle_id: activity.data_cache.cycle.id,activity_number: activity.number,address: address,value: tmp_dc.value)
          end
        end  
      when "SW"
        CommonDataBus.create(cycle_id: @cycle.id,activity_number: activity.number,address: add_bin(rs.value, imm_value),value: rd.value)
      when "JALR" 
        CommonDataBus.create(cycle_id: @cycle.id,activity_number: activity.number,register_name: rd.name,value: add_bin_int(@program.counter, +1))
      when "BEQ"
        if rs.value == rd.value
          instruction.update(branch_mispredicted: true) unless instruction.prediction_taken 
        else
          instruction.update(branch_mispredicted: true) if instruction.prediction_taken
        end

        if instruction.branch_mispredicted
          #flush
          #take the opposite prediction mn awl el fetch
        end
      end
    end
  end
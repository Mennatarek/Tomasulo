json.array!(@programs) do |program|
  json.extract! program, :id, :labels, :name, :code, :main_memory_access_time, :memory_capacity, :starting_address
  json.url program_url(program, format: :json)
end

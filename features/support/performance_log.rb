def measure_runtime_report(message_prefix)
  start = Time.now.to_i
  yield
  puts "#{message_prefix}: #{Time.now.to_i - start} seconds"
end

def measure_runtime_debug(message_prefix)
  start = Time.now.to_i
  yield
  p "#{message_prefix}: #{Time.now.to_i - start} seconds"
end
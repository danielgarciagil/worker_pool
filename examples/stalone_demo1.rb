
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "logger"
require "worker_pool"

# Verbose logs
WorkerPool.configure do |c|
  c.logger = Logger.new($stdout, level: Logger::DEBUG)
  c.workers  = 5
  c.queue_size = 100
end

c = WorkerPool.start!

stop_heart = false
heartbeat = Thread.new do
  i = 0
  until stop_heart
    i += 1
    WorkerPool.submit(name: "heartbeat-#{i}", unique_key: nil) do |t|
      puts "[HB] #{Time.now} (#{t.name})"
      sleep 0.2 # simula trabajo corto
    end
    sleep 2
  end
end

WorkerPool.submit do |job|
  puts "Job simple con payload: #{job.payload}"

end


# 10.times do |i|
#   WorkerPool.submit( payload: "Tarea #{i}") do |job|
#     puts "Procesando job #{job.id} con valor #{job.payload}"
#     sleep(rand * 0.2) # Simula trabajo
#   end
# end

tries = 0
 WorkerPool.submit(name: "falla_y_pasa") do |t|
    tries += 1
    puts "[USR1] intento #{tries} (#{t.name})"
    raise "boom" if tries < 4
    puts "[USR1] OK al intento #{tries}"
  end


# --- DEMO: señales
graceful_stop = proc do |sig|
  puts "\n[Runner] Recibida señal #{sig} → apagando…"
  stop_heart = true
  heartbeat.join
  # si tu versión ya expone graceful, cámbialo a: WorkerHub.stop!(timeout: 20, graceful: true)
  # WorkerPool.shutdown(graceful: true)
  puts "[Runner] Listo. Bye!"
  exit 0
end

Signal.trap("TERM", &graceful_stop)
Signal.trap("INT", &graceful_stop)


puts "[Runner] PID=#{Process.pid} — esperando señales. (Ctrl+C para salir)"

loop { sleep 1 }
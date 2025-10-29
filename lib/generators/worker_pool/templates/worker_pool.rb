WorkerPool.configure do |c|
  # Ajusta a tu carga
  c.workers  = ENV.fetch("WORKER_POOL_WORKERS", 4).to_i
  c.queue_size   = ENV.fetch("WORKER_POOL_QUEUE_SIZE", 100).to_i
  c.max_attempts = ENV.fetch("WORKER_POOL_MAX_ATTEMPTS", 3).to_i

  # Puedes conectar tu logger de Rails
  c.logger   = defined?(Rails) ? Rails.logger : Logger.new($stdout, level: Logger::INFO)
end
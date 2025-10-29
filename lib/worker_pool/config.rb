require "logger"

module WorkerPool
  class Config
    attr_accessor :workers, :queue_size, :logger, :default_retry_policy,
                  :unique_registry, :middleware

    def initialize
      @workers  = Integer(ENV.fetch("WORKER_POOL_WORKERS", 4))
      @queue_size   = Integer(ENV.fetch("WORKER_POOL_QUEUE_SIZE", 100))
      max_attempts = Integer(ENV.fetch("WORKER_POOL_MAX_ATTEMPTS", 3))
      @logger   = Logger.new($stdout, level: Logger::INFO)
      @default_retry_policy = RetryPolicy.new( max_attempts: max_attempts)
      @middleware = Middleware.new()
      @middleware.use Middleware::NotifyErrors
      @middleware.use Middleware::Timing

      @unique_registry = UniqueRegistry.new
    end
  end
end




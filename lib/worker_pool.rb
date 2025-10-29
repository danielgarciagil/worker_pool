# frozen_string_literal: true

require "worker_pool/version"
require "worker_pool/config"
require "worker_pool/errors"
require "worker_pool/retry_policy"
require "worker_pool/unique_registry"
require "worker_pool/middleware"
require "worker_pool/coordinator"
require "worker_pool/task"
require "worker_pool/instrumentation"


require "thread"
require "securerandom"
require "time"

begin
  require "worker_pool/railtie"
rescue LoadError
end

module WorkerPool

  class << self

    def configure
      yield(config)
    end

    def config
      @config ||= Config.new
    end
    
    def start!
      return @coordinator if @coordinator
      @coordinator = Coordinator.new(
        workers: config.workers,
        logger: config.logger,
        queue_size: config.queue_size,
        unique_registry: config.unique_registry,
        middleware: config.middleware
      ).tap(&:start)
      @coordinator
    end


    def coordinator
      @coordinator || raise("WorkerPool.coordinator no inicializado. Llama WorkerPool.build primero.")
    end

    # Alias corto para enviar trabajos al singleton
    def submit(task=nil, **kwargs, &block)
      t = task || Task.build(**kwargs, &block)
      @coordinator.submit(t)
      Instrumentation.instrument(:scheduled, name: t.name, uniq_key: t.unique_key)
      t
    end

    # Atajo para apagar el singleton
    def shutdown(graceful: true)
      @coordinator&.shutdown(graceful: graceful)
      @coordinator = nil
    end
  end
end
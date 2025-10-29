require "concurrent-ruby"


module WorkerPool
  class Coordinator
    STOP = :__STOP__

    def initialize( workers:, logger:,  queue_size:, unique_registry:, middleware:)
      @logger = logger

      @workers_count = workers

      @queue = SizedQueue.new(queue_size)

      @stats = { enqueued: 0, processed: 0, failed: 0, retried: 0 }
      @stats_mtx = Mutex.new
      @threads = []
      @running = Concurrent::AtomicBoolean.new(false)

      @unique_registry = unique_registry
      @unique_release = ->(key) { @unique_registry.release(key) }

      @executor = middleware.build(->(task) { task.call })

      # Apagado elegante cuando el proceso termina
      at_exit do
        begin
          shutdown(graceful: true)
        rescue StandardError
          # no-op
        end
      end
    end

    def start
      @running.make_true

      spawn_workers

      self
    end

    def stats
      @stats_mtx.synchronize { @stats.dup }
    end

    def metrics_line
      s = stats
      "enqueued=#{s[:enqueued]} processed=#{s[:processed]} retried=#{s[:retried]} failed=#{s[:failed]}"
    end

    def submit(task)
      raise StoppedError, "Coordinator detenido" if @running.false?

      if task.unique_key && !@unique.acquire(task.unique_key)
        raise UniqueViolation, "Task única ya encolada/ejecutándose (key=#{task.unique_key})"
      end
      @queue.push(task)
      incr(:enqueued)
      task.id
    end

    # Apagado: graceful espera, force no
    def shutdown(graceful: true)
      return if @running.false?
      @running.make_false

      if graceful
        @logger.info "Esperando a que la cola se vacíe…"
        drain
      else
        @logger.warn "Apagado inmediato solicitado."
      end

      @workers_count.times { @queue.push(STOP) }
      @threads.each(&:join)
      @logger.info "Pool detenido. #{metrics_line}"
    end

    # Espera a que la cola se vacíe (sin impedir que entren nuevos jobs)
    def drain
      loop do
        sleep 0.05
        break if @queue.empty?
      end
    end

    private

    def spawn_workers
      @logger.info "Iniciando #{@workers_count} worker(s)…"
      @workers_count.times do |i|
        @threads << Thread.new { worker_loop(i) }
      end
    end

    def worker_loop(index)
      Thread.current.name = "worker-#{index}" if Thread.current.respond_to?(:name=)
      @logger.info "Worker #{index} listo."

      loop do
        job = @queue.pop
        break if job.equal?(STOP)

        begin
          Instrumentation.instrument(:start, name: job.name, attempt: job.attempt + 1)
          @executor.call(job) # Aquí va tu lógica de consumo
          Instrumentation.instrument(:success, name: job.name, attempt: job.attempt + 1)
          @logger.debug "Worker #{index} procesó job #{job.id} (#{metrics_line})"
          incr(:processed)
          @unique_release.call(job.unique_key) if job.unique_key
        rescue => e
          handle_failure(job, e, index)
        end
      end

      @logger.info "Worker #{index} saliendo."
    end


    def handle_failure(task, error, _index)
      attempt = task.attempt + 1
      if task.retry_policy.should_retry?(error, attempt)
        incr(:retried)
        delay = task.retry_policy.next_delay(attempt)
        @logger.warn { "[Worker ##{@id}] Falla #{task.name}: #{error.class} - reintento en #{'%.3f' % delay}s (attempt=#{attempt}/#{task.retry_policy.max_attempts})" }
        Instrumentation.instrument(:retry, name: task.name, attempt: attempt, delay: delay, error: error.class.name)
        sleep(delay)
        @queue << task.next_attempt
      else
        incr(:failed)
        @logger.error { "[Worker ##{@id}] Falla definitiva #{task.name}: #{error.class} - #{error.message}" }
        # liberar clave única al fallar definitivamente
        @unique_release.call(task.unique_key)
      end
    end

    def incr(key)
      @stats_mtx.synchronize { @stats[key] += 1 }
    end
  end
end
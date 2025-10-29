module WorkerPool
  # Cadena de middleware alrededor de la ejecución de cada Task
  class Middleware
    def initialize
      @stack = []
    end

    def use(klass, *args, **kwargs, &block)
      @stack << [klass, args, kwargs, block]
    end

    def build(executor)
      @stack.reverse.inject(executor) do |acc, (klass, args, kwargs, block)|
        klass.new(acc, *args, **kwargs, &block)
      end
    end
  end

  # Base para middlewares
  class Middleware::Base
    def initialize(app)
      @app = app
    end

    def call(task)
      @app.call(task)
    end
  end

  # Middleware de medición simple (tiempo)
  class Middleware::Timing < Middleware::Base
    def call(task)
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      @app.call(task)
    ensure
      t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      duration = (t1 - t0) * 1000.0
      WorkerPool.config.logger.debug { "[Timing] #{task.name} took #{format('%.2f', duration)}ms" }
    end
  end

  # Middleware de captura de errores → Instrumentation
  class Middleware::NotifyErrors < Middleware::Base
    def call(task)
      @app.call(task)
    rescue => e
      Instrumentation.instrument(:error, task: task.name, attempt: task.attempt + 1, error: e.class.name)
      raise
    end
  end
end
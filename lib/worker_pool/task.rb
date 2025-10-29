module WorkerPool
  # Tarea inmutable que envuelve un callable con contexto, política de reintentos y unique key
  class Task
    attr_reader :id, :name, :payload, :callable, :retry_policy, :attempt, :unique_key

    def self.build(name: nil, payload: {}, retry_policy: nil, unique_key: nil, &block)
      raise ArgumentError, "Task requiere un bloque o un :callable" unless block_given?
      new(name: name, payload: payload, callable: block, retry_policy: retry_policy, unique_key: unique_key)
    end

    def initialize(name:, payload: {}, callable:, retry_policy: nil, unique_key: nil, attempt: 0)
      @name         = name || callable_name(callable)
      @payload      = payload.freeze
      @callable     = callable
      @retry_policy = retry_policy || WorkerPool.config.default_retry_policy
      @attempt      = attempt
      @unique_key   = unique_key
      @id           = SecureRandom.uuid
    end

    def call
      callable.call(self)
    end

    def next_attempt
      self.class.new(
        name: name,
        payload: payload,
        callable: callable,
        retry_policy: retry_policy,
        unique_key: unique_key,
        attempt: attempt + 1
      )
    end

    private

    def callable_name(c)
      if c.respond_to?(:receiver) && c.respond_to?(:name)
        "#{c.receiver.class}##{c.name}"
      else
        "anonymous"
      end
    end
  end
end
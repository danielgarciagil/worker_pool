module WorkerPool
  # Backoff exponencial con jitter (full jitter)
  class RetryPolicy
    attr_reader :max_attempts, :base_delay, :max_delay, :jitter_ratio, :retry_on

    # retry_on: Proc|(Exception)->bool para decidir si reintenta
    def initialize(max_attempts: 5, base_delay: 0.5, max_delay: 30.0, jitter_ratio: 0.5, retry_on: nil)
      @max_attempts = max_attempts
      @base_delay   = base_delay
      @max_delay    = max_delay
      @jitter_ratio = jitter_ratio
      @retry_on     = retry_on || ->(err) { true }
    end

    def next_delay(attempt)
      return 0.0 if attempt <= 1
      exp = base_delay * (2 ** (attempt - 1))
      exp = [exp, max_delay].min
      jitter = rand * (exp * jitter_ratio)
      exp - jitter
    end

    def should_retry?(error, attempt)
      attempt < max_attempts && retry_on.call(error)
    end
  end
end
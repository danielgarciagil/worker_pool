module WorkerPool
  class Error < StandardError; end
  class RejectedTaskError < Error; end
  class StoppedError < Error; end
  class UniqueViolation < Error; end
end
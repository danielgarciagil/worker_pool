require "monitor"
module WorkerPool
  class UniqueRegistry
    def initialize
      @lock = Monitor.new
      @set  = {}
    end

    def acquire(key)
      return true if key.nil?
      @lock.synchronize do
        return false if @set[key]
        @set[key] = true
        true
      end
    end

    def release(key)
      return true if key.nil?
      @lock.synchronize { @set.delete(key) }
      true
    end
  end
end
require "active_support/notifications"

module WorkerPool
  module Instrumentation
    EVENTS = {
      scheduled: "worker_pool.scheduled",
      start:     "worker_pool.task.start",
      success:   "worker_pool.task.success",
      retry:     "worker_pool.task.retry",
      error:     "worker_pool.task.error"
    }.freeze

    def self.instrument(event, payload = {})
      ActiveSupport::Notifications.instrument(EVENTS.fetch(event), payload)
    end
  end
end
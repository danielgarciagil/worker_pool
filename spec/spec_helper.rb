# frozen_string_literal: true

require "stringio"
require "worker_pool"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    WorkerPool.configure do |c|
      c.logger = Logger.new(StringIO.new)
      c.unique_registry = WorkerPool::UniqueRegistry.new
      c.middleware = WorkerPool::Middleware.new
      c.default_retry_policy = WorkerPool::RetryPolicy.new
    end
  end

  config.after do
    WorkerPool.shutdown(graceful: false)
  end
end

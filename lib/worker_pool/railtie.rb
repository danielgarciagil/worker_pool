require "rails/railtie"

module WorkerPool
  class Railtie < ::Rails::Railtie
    config.worker_pool = ActiveSupport::OrderedOptions.new

    initializer "worker_pool.configure" do |app|
      WorkerPool.configure do |c|
        c.workers  = app.config.worker_pool.fetch(:workers, c.workers)
        c.queue_size   = app.config.worker_pool.fetch(:queue_size, c.queue_size)
        c.max_attempts = app.config.worker_pool.fetch(:max_attempts, c.max_attempts)
        c.logger   = app.config.worker_pool.fetch(:logger, c.logger)
      end
    end

    rake_tasks do
      # namespace :worker_pool do … end
    end
  end
end
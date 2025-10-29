require "rails/railtie"

module WorkerPool
  class Railtie < ::Rails::Railtie
    config.worker_pool = ActiveSupport::OrderedOptions.new

    initializer "worker_pool.configure" do |app|
      WorkerPool.configure do |c|
        c.workers  = app.config.worker_pool.fetch(:workers, c.workers)
        c.in_buf   = app.config.worker_pool.fetch(:in_buf, c.in_buf)
        c.work_buf = app.config.worker_pool.fetch(:work_buf, c.work_buf)
        c.logger   = app.config.worker_pool.fetch(:logger, c.logger)
      end
    end

    rake_tasks do
      # namespace :worker_pool do … end
    end
  end
end
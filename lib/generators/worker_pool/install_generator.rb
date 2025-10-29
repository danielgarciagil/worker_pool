require "rails/generators"

module WorkerPool
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Crea initializer para WorkerPool"
      def copy_initializer
        template "worker_pool.rb", "config/initializers/worker_pool.rb"
      end
    end
  end
end
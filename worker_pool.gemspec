# frozen_string_literal: true

require_relative "lib/worker_pool/version"

Gem::Specification.new do |spec|
  spec.name = "worker_pool"
  spec.version = WorkerPool::VERSION
  spec.authors = ["Daniel Garcia-Gil"]
  spec.email = ["danielgarciagil@gmail.com"]

  spec.summary = "Smart concurrency engine for Ruby/Rails"
  spec.description = "WorkerPool coordina workers, reintentos y ejecución concurrente de tareas con backpressure."
  spec.homepage = "https://github.com/danielgarciagil/worker_pool"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]

  # runtime dependencies
  spec.add_dependency "concurrent-ruby", ">= 1.2", "< 2.0"
  spec.add_dependency "activesupport", ">= 5.0"

  # Dev deps (opcionales por ahora)
  spec.add_development_dependency "rspec", ">= 3.12", "< 4.0"
  spec.add_development_dependency "rake", ">= 13.0"
end

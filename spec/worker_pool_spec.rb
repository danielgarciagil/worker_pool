# frozen_string_literal: true

RSpec.describe WorkerPool do
  describe ".config" do
    it "memoizes a WorkerPool::Config instance" do
      expect(WorkerPool.config).to be_a(WorkerPool::Config)
      expect(WorkerPool.config).to equal(WorkerPool.config)
    end
  end

  describe ".configure" do
    it "yields the config for customization" do
      WorkerPool.configure do |config|
        config.workers = 2
      end

      expect(WorkerPool.config.workers).to eq(2)
    end
  end

  describe ".start!" do
    let(:coordinator) { instance_double(WorkerPool::Coordinator, start: nil) }

    before do
      allow(WorkerPool::Coordinator).to receive(:new).and_return(coordinator)
    end

    it "builds and starts a coordinator when none exists" do
      WorkerPool.start!

      expect(WorkerPool::Coordinator).to have_received(:new).with(
        workers: WorkerPool.config.workers,
        logger: WorkerPool.config.logger,
        queue_size: WorkerPool.config.queue_size,
        unique_registry: WorkerPool.config.unique_registry,
        middleware: WorkerPool.config.middleware
      )
      expect(coordinator).to have_received(:start)
    end

    it "returns the existing coordinator if already started" do
      first = WorkerPool.start!

      allow(WorkerPool::Coordinator).to receive(:new).and_call_original

      expect(WorkerPool.start!).to equal(first)
    end
  end

  # describe ".coordinator" do
  #   it "raises if the worker pool has not been started" do
  #     expect { WorkerPool.coordinator }.to raise_error(RuntimeError, /no inicializado/i)
  #   end
  # end

  describe ".submit" do
    let(:coordinator) { instance_double(WorkerPool::Coordinator, submit: nil, shutdown: nil) }
    let(:task) { instance_double(WorkerPool::Task, name: "test", unique_key: nil) }

    before do
      WorkerPool.instance_variable_set(:@coordinator, coordinator)
      allow(WorkerPool::Instrumentation).to receive(:instrument)
    end

    after do
      WorkerPool.instance_variable_set(:@coordinator, nil)
    end

    it "forwards an explicit task to the coordinator" do
      expect(WorkerPool.submit(task)).to eq(task)
      expect(coordinator).to have_received(:submit).with(task)
      expect(WorkerPool::Instrumentation).to have_received(:instrument)
        .with(:scheduled, name: "test", uniq_key: nil)
    end

    it "builds a task from the provided block" do
      allow(WorkerPool::Task).to receive(:build).and_return(task)

      WorkerPool.submit(name: "example") { |t| t }

      expect(WorkerPool::Task).to have_received(:build).with(name: "example")
      expect(coordinator).to have_received(:submit).with(task)
    end
  end

  describe ".shutdown" do
    let(:coordinator) { instance_double(WorkerPool::Coordinator, shutdown: nil) }

    before do
      WorkerPool.instance_variable_set(:@coordinator, coordinator)
    end

    after do
      WorkerPool.instance_variable_set(:@coordinator, nil)
    end

    it "delegates to the coordinator and clears the singleton" do
      WorkerPool.shutdown

      expect(coordinator).to have_received(:shutdown).with(graceful: true)
      expect { WorkerPool.coordinator }.to raise_error(RuntimeError)
    end
  end
end

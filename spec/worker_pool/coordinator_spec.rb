# frozen_string_literal: true

RSpec.describe WorkerPool::Coordinator do
  def build_task(name: "job", unique_key: nil, attempt: 0, &block)
    callable = block || ->(_task) { nil }
    WorkerPool::Task.new(
      name: name,
      payload: {},
      callable: callable,
      retry_policy: WorkerPool::RetryPolicy.new(max_attempts: 1),
      unique_key: unique_key,
      attempt: attempt
    )
  end

  let(:logger) do
    double("Logger").tap do |log|
      allow(log).to receive(:info)
      allow(log).to receive(:debug) { |*args, &block| block&.call }
      allow(log).to receive(:warn) { |*args, &block| block&.call }
      allow(log).to receive(:error) { |*args, &block| block&.call }
    end
  end
  let(:unique_registry) { WorkerPool::UniqueRegistry.new }
  let(:middleware) { WorkerPool::Middleware.new }

  subject(:coordinator) do
    described_class.new(
      workers: 1,
      logger: logger,
      queue_size: 5,
      unique_registry: unique_registry,
      middleware: middleware
    )
  end

  before do
    allow(WorkerPool::Instrumentation).to receive(:instrument)
  end

  after do
    coordinator.shutdown(graceful: false)
  rescue WorkerPool::StoppedError
    # already stopped
  end

  describe "#start and #submit" do
    it "processes submitted tasks and updates stats" do
      results = Queue.new
      coordinator.start

      task = build_task(name: "job") { |t| results << t.id }
      coordinator.submit(task)

      processed_id = results.pop
      expect(processed_id).to eq(task.id)

      expect(coordinator.stats[:enqueued]).to eq(1)
      expect(coordinator.stats[:processed]).to eq(1)
      expect(WorkerPool::Instrumentation).to have_received(:instrument).with(:start, name: "job", attempt: 1)
      expect(WorkerPool::Instrumentation).to have_received(:instrument).with(:success, name: "job", attempt: 1)
    end
  end

  describe "#submit" do
    it "raises when the coordinator is not running" do
      expect { coordinator.submit(build_task) }.to raise_error(WorkerPool::StoppedError)
    end
  end

  describe "#shutdown" do
    it "waits for the queue to drain when graceful" do
      coordinator.start
      coordinator.submit(build_task { |_task| sleep 0.05 })

      coordinator.shutdown

      expect(logger).to have_received(:info).with(/Pool detenido/)
    end
  end
end

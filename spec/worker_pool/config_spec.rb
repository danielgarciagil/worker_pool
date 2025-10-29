# frozen_string_literal: true

RSpec.describe WorkerPool::Config do
  subject(:config) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("WORKER_POOL_WORKERS", 4).and_return(4)
    allow(ENV).to receive(:fetch).with("WORKER_POOL_QUEUE_SIZE", 100).and_return(100)
    allow(ENV).to receive(:fetch).with("WORKER_POOL_MAX_ATTEMPTS", 3).and_return(3)
  end

  it "initializes numeric configuration using defaults" do
    expect(config.workers).to eq(4)
    expect(config.queue_size).to eq(100)
  end

  it "provides a logger" do
    expect(config.logger).to respond_to(:info)
  end

  it "sets up a default retry policy" do
    expect(config.default_retry_policy).to be_a(WorkerPool::RetryPolicy)
  end

  it "creates a unique registry" do
    expect(config.unique_registry).to be_a(WorkerPool::UniqueRegistry)
  end

  it "builds a middleware stack with timing and error notification" do
    stack = config.middleware.instance_variable_get(:@stack)
    expect(stack.map(&:first)).to eq([
      WorkerPool::Middleware::NotifyErrors,
      WorkerPool::Middleware::Timing
    ])
  end
end

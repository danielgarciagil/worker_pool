# frozen_string_literal: true

RSpec.describe WorkerPool::Middleware do
  describe "#use and #build" do
    class RecorderMiddleware < WorkerPool::Middleware::Base
      def initialize(app, label, buffer)
        super(app)
        @label = label
        @buffer = buffer
      end

      def call(task)
        @buffer << @label
        super(task)
      end
    end

    it "wraps the executor in reverse registration order" do
      buffer = []
      middleware = described_class.new
      middleware.use(RecorderMiddleware, :first, buffer)
      middleware.use(RecorderMiddleware, :second, buffer)

      executor = middleware.build(->(_task) { buffer << :core })
      executor.call(double(:task))

      expect(buffer).to eq([:first, :second, :core])
    end
  end
end

RSpec.describe WorkerPool::Middleware::Timing do
  it "logs the execution time even if the task raises" do
    messages = []
    logger = double("Logger", info: nil, warn: nil, error: nil)
    allow(logger).to receive(:debug) { |&block| messages << block.call }
    WorkerPool.configure { |c| c.logger = logger }

    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(1.0, 1.1)

    middleware = described_class.new(->(_task) { raise ArgumentError, "boom" })

    expect { middleware.call(double(name: "job")) }.to raise_error(ArgumentError, "boom")

    expect(messages.last).to include("[Timing] job took")
  end
end

RSpec.describe WorkerPool::Middleware::NotifyErrors do
  it "instruments and re-raises errors from downstream" do
    task = double(name: "failing", attempt: 0)
    allow(WorkerPool::Instrumentation).to receive(:instrument)

    middleware = described_class.new(->(_task) { raise StandardError, "failure" })

    expect { middleware.call(task) }.to raise_error(StandardError, "failure")
    expect(WorkerPool::Instrumentation).to have_received(:instrument).with(
      :error,
      task: "failing",
      attempt: 1,
      error: "StandardError"
    )
  end
end

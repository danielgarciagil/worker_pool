# frozen_string_literal: true

RSpec.describe WorkerPool::Task do
  describe ".build" do
    it "raises when no block is given" do
      expect { described_class.build }.to raise_error(ArgumentError)
    end

    it "constructs a task with sensible defaults" do
      task = described_class.build(payload: { foo: :bar }) { |t| t }

      expect(task.name).to eq("anonymous")
      expect(task.payload).to be_frozen
      expect(task.retry_policy).to be_a(WorkerPool::RetryPolicy)
      expect(task.attempt).to eq(0)
    end

    it "honours provided attributes" do
      retry_policy = WorkerPool::RetryPolicy.new(max_attempts: 2)

      task = described_class.build(name: "custom", retry_policy: retry_policy, unique_key: "uniq") { |t| t }

      expect(task.name).to eq("custom")
      expect(task.retry_policy).to equal(retry_policy)
      expect(task.unique_key).to eq("uniq")
    end
  end

  describe "#call" do
    it "invokes the callable with itself" do
      received = nil
      task = described_class.new(
        name: "callable",
        payload: {},
        callable: ->(t) { received = t },
        retry_policy: WorkerPool::RetryPolicy.new
      )

      task.call

      expect(received).to eq(task)
    end
  end

  describe "#next_attempt" do
    it "produces a new task with incremented attempt preserving attributes" do
      task = described_class.new(
        name: "callable",
        payload: { foo: "bar" },
        callable: ->(_t) { :ok },
        retry_policy: WorkerPool::RetryPolicy.new,
        unique_key: "uniq",
        attempt: 1
      )

      next_task = task.next_attempt

      expect(next_task.attempt).to eq(2)
      expect(next_task.payload).to equal(task.payload)
      expect(next_task.unique_key).to eq("uniq")
      expect(next_task).not_to equal(task)
    end
  end
end

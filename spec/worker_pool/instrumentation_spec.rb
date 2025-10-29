# frozen_string_literal: true

RSpec.describe WorkerPool::Instrumentation do
  describe ".instrument" do
    it "delegates to ActiveSupport::Notifications with the mapped event name" do
      payload = { foo: "bar" }
      expect(ActiveSupport::Notifications).to receive(:instrument).with("worker_pool.scheduled", payload)

      described_class.instrument(:scheduled, payload)
    end

    it "raises a KeyError for unknown events" do
      expect { described_class.instrument(:missing) }.to raise_error(KeyError)
    end
  end
end

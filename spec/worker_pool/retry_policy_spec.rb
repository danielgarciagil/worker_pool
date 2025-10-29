# frozen_string_literal: true

RSpec.describe WorkerPool::RetryPolicy do
  let(:policy) do
    described_class.new(
      max_attempts: 3,
      base_delay: 1.0,
      max_delay: 10.0,
      jitter_ratio: 0.5
    )
  end

  describe "#next_delay" do
    it "returns zero for the first attempt" do
      expect(policy.next_delay(1)).to eq(0.0)
    end

    it "applies exponential backoff with jitter" do
      allow(policy).to receive(:rand).and_return(0.25)

      delay = policy.next_delay(2)

      expect(delay).to be_within(0.0001).of(1.75) # 2.0 - (2.0 * 0.5 * 0.25)
    end

    it "caps the delay at the configured maximum" do
      allow(policy).to receive(:rand).and_return(0.0)

      expect(policy.next_delay(10)).to eq(10.0)
    end
  end

  describe "#should_retry?" do
    it "honours the maximum attempts" do
      expect(policy.should_retry?(RuntimeError.new, 2)).to be(true)
      expect(policy.should_retry?(RuntimeError.new, 3)).to be(false)
    end

    it "delegates to the custom retry_on proc" do
      retry_on = ->(err) { err.is_a?(ArgumentError) }
      custom_policy = described_class.new(max_attempts: 5, retry_on: retry_on)

      expect(custom_policy.should_retry?(ArgumentError.new, 2)).to be(true)
      expect(custom_policy.should_retry?(RuntimeError.new, 2)).to be(false)
    end
  end
end

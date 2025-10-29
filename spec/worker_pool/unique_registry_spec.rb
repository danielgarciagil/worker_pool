# frozen_string_literal: true

RSpec.describe WorkerPool::UniqueRegistry do
  subject(:registry) { described_class.new }

  it "allows acquiring a key once and blocks duplicates" do
    expect(registry.acquire("foo")).to be(true)
    expect(registry.acquire("foo")).to be(false)
  end

  it "releases keys so they can be reacquired" do
    registry.acquire("foo")
    registry.release("foo")

    expect(registry.acquire("foo")).to be(true)
  end

  it "treats nil keys as always available" do
    expect(registry.acquire(nil)).to be(true)
    expect(registry.acquire(nil)).to be(true)
    expect(registry.release(nil)).to be(true)
  end
end

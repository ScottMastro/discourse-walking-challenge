# frozen_string_literal: true

RSpec.describe WalkingChallenge::Route do
  describe ".stops_reached" do
    it "counts every stop at or before the given distance" do
      pewter = described_class::LEGS.first.meters

      expect(
        [0, pewter - 1, pewter, described_class.total_meters].map do |meters|
          described_class.stops_reached(meters)
        end,
      ).to eq([0, 0, 1, described_class::LEGS.size])
    end
  end

  describe ".total_meters" do
    it "covers the full 708 mile route" do
      expect(described_class.total_meters / described_class::METERS_PER_MILE).to be_within(0.01).of(
        708,
      )
    end
  end
end

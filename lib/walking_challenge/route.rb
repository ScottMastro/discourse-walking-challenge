# frozen_string_literal: true

module WalkingChallenge
  module Route
    METERS_PER_MILE = 1609.344

    Leg =
      Data.define(:from, :to, :miles) do
        def meters
          (miles * METERS_PER_MILE).round
        end
      end

    LEGS = [
      Leg.new("Pallet Town", "Pewter City", 175),
      Leg.new("Pewter City", "Cerulean City", 99),
      Leg.new("Cerulean City", "Vermillion City", 65),
      Leg.new("Vermillion City", "Celadon City", 28),
      Leg.new("Celadon City", "Saffron City", 5),
      Leg.new("Saffron City", "Fuchsia City", 62),
      Leg.new("Fuchsia City", "Cinnabar Island", 144),
      Leg.new("Cinnabar Island", "Viridian City", 100),
      Leg.new("Viridian City", "Indigo Plateau", 30),
    ].freeze

    STOP_METERS = LEGS.map(&:meters).inject([]) { |acc, m| acc << ((acc.last || 0) + m) }.freeze

    def self.total_meters
      STOP_METERS.last
    end

    def self.stops_reached(meters)
      STOP_METERS.count { |stop| meters >= stop }
    end

    def self.stop_name(index)
      LEGS[index].to
    end

    def self.as_json
      { legs: LEGS.map { |leg| { from: leg.from, to: leg.to, meters: leg.meters } }, total_meters: }
    end
  end
end

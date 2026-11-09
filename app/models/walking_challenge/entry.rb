# frozen_string_literal: true

module WalkingChallenge
  class Entry < ActiveRecord::Base
    self.table_name = "walking_challenge_entries"

    ACTIVITIES = %w[walk run bike hike ski other].freeze
    SOURCES = %w[manual strava shortcut].freeze
    NOTE_MAX_LENGTH = 120

    belongs_to :user

    validates :distance_meters, numericality: { only_integer: true, greater_than: 0 }
    validates :activity, inclusion: { in: ACTIVITIES }
    validates :source, inclusion: { in: SOURCES }
    validates :logged_on, presence: true
    validates :note, length: { maximum: NOTE_MAX_LENGTH }

    scope :newest_first, -> { order(logged_on: :desc, id: :desc) }

    def self.total_meters_for(user)
      where(user:).sum(:distance_meters)
    end
  end
end

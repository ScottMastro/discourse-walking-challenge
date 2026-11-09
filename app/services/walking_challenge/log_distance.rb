# frozen_string_literal: true

module WalkingChallenge
  class LogDistance
    include Service::Base

    params do
      attribute :distance, :float
      attribute :unit, :string, default: "mi"
      attribute :activity, :string, default: "walk"
      attribute :logged_on, :date
      attribute :note, :string, default: ""

      validates :distance, numericality: { greater_than: 0 }
      validates :unit, inclusion: { in: %w[mi km] }
      validates :activity, inclusion: { in: Entry::ACTIVITIES }
      validates :logged_on, presence: true
      validates :note, length: { maximum: Entry::NOTE_MAX_LENGTH }
      validate :distance_within_daily_limit
      validate :logged_on_not_in_future

      def distance_meters
        (distance * (unit == "km" ? 1000 : Route::METERS_PER_MILE)).round
      end

      private

      def distance_within_daily_limit
        return if distance.blank?
        return if distance_meters <= SiteSetting.walking_challenge_max_entry_km * 1000
        errors.add(:distance, :less_than_or_equal_to, count: max_in_unit)
      end

      def max_in_unit
        km = SiteSetting.walking_challenge_max_entry_km
        unit == "km" ? km : (km * 1000 / Route::METERS_PER_MILE).floor
      end

      # A day of slack covers people whose local date is ahead of the server's.
      def logged_on_not_in_future
        return if logged_on.blank? || logged_on <= Date.tomorrow
        errors.add(:logged_on, :invalid)
      end
    end

    policy :can_log_distance

    transaction { model :entry, :create_entry }

    only_if(:arrival_announcements_enabled) { step :schedule_arrival_announcement }

    private

    def can_log_distance(guardian:)
      guardian.user.present? && !guardian.user.silenced?
    end

    def create_entry(params:, guardian:)
      Entry.create(
        user: guardian.user,
        distance_meters: params.distance_meters,
        activity: params.activity,
        logged_on: params.logged_on,
        note: params.note.to_s.strip,
        source: "manual",
      )
    end

    def arrival_announcements_enabled
      SiteSetting.walking_challenge_announce_topic_id.positive?
    end

    def schedule_arrival_announcement(guardian:)
      Jobs.enqueue(Jobs::WalkingChallenge::AnnounceArrivals, user_id: guardian.user.id)
    end
  end
end

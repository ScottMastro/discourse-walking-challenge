# frozen_string_literal: true

module WalkingChallenge
  class Standings
    Participant =
      Data.define(:user, :meters, :last_logged_on) do
        alias_method :read_attribute_for_serialization, :public_send
      end

    def participants
      totals =
        Entry.group(:user_id).pluck(
          :user_id,
          Arel.sql("SUM(distance_meters)"),
          Arel.sql("MAX(logged_on)"),
        )
      users = User.where(id: totals.map(&:first)).index_by(&:id)

      totals
        .filter_map do |user_id, meters, last_logged_on|
          user = users[user_id]
          Participant.new(user:, meters:, last_logged_on:) if user
        end
        .sort_by { |participant| -participant.meters }
    end
  end
end

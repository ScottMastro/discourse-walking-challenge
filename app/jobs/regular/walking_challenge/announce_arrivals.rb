# frozen_string_literal: true

module Jobs
  module WalkingChallenge
    class AnnounceArrivals < ::Jobs::Base
      def execute(args)
        topic = Topic.find_by(id: SiteSetting.walking_challenge_announce_topic_id)
        user = User.find_by(id: args[:user_id])
        return if topic.blank? || user.blank?

        DistributedMutex.synchronize("walking_challenge_announce_#{user.id}") do
          announced = user.custom_fields[::WalkingChallenge::ANNOUNCED_STOPS_FIELD].to_i
          meters = ::WalkingChallenge::Entry.total_meters_for(user)
          reached = ::WalkingChallenge::Route.stops_reached(meters)
          next if reached <= announced

          PostCreator.create!(
            Discourse.system_user,
            topic_id: topic.id,
            raw: arrival_post(user, (announced...reached), meters),
            skip_validations: true,
          )

          user.custom_fields[::WalkingChallenge::ANNOUNCED_STOPS_FIELD] = reached
          user.save_custom_fields
        end
      end

      private

      def arrival_post(user, stop_indexes, meters)
        miles = (meters / ::WalkingChallenge::Route::METERS_PER_MILE).round(1)
        lines =
          stop_indexes.map do |index|
            key = index == ::WalkingChallenge::Route::LEGS.size - 1 ? "finished" : "arrived"
            I18n.t(
              "walking_challenge.arrival_post.#{key}",
              username: user.username,
              place: ::WalkingChallenge::Route.stop_name(index),
            )
          end
        lines << I18n.t("walking_challenge.arrival_post.total", miles:)
        lines.join("\n\n")
      end
    end
  end
end

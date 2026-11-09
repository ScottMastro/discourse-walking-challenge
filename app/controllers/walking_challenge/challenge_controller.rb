# frozen_string_literal: true

module WalkingChallenge
  class ChallengeController < ::ApplicationController
    requires_plugin WalkingChallenge::PLUGIN_NAME

    RECENT_ACTIVITY_LIMIT = 8
    OWN_ENTRIES_LIMIT = 100

    skip_before_action :check_xhr, only: :show

    def show
      respond_to do |format|
        format.html { render "default/empty" }
        format.json { render json: state }
      end
    end

    private

    def state
      {
        route: Route.as_json,
        participants:
          serialize_data(Standings.new.participants, ParticipantSerializer, root: false),
        recent_entries:
          serialize_data(
            Entry.includes(:user).order(created_at: :desc).limit(RECENT_ACTIVITY_LIMIT),
            EntrySerializer,
            include_user: true,
          ),
        own_entries:,
        max_entry_km: SiteSetting.walking_challenge_max_entry_km,
      }
    end

    def own_entries
      return [] if current_user.blank?
      serialize_data(
        Entry.where(user: current_user).newest_first.limit(OWN_ENTRIES_LIMIT),
        EntrySerializer,
      )
    end
  end
end

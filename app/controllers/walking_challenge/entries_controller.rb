# frozen_string_literal: true

module WalkingChallenge
  class EntriesController < ::ApplicationController
    requires_plugin WalkingChallenge::PLUGIN_NAME

    before_action :ensure_logged_in
    before_action :rate_limit_logging, only: :create

    def create
      LogDistance.call(service_params) do
        on_success do |entry:|
          render json: {
                   entry: EntrySerializer.new(entry, root: false).as_json,
                   total_meters: Entry.total_meters_for(current_user),
                 },
                 status: :created
        end
        on_failed_contract do |contract|
          render_json_error(contract.errors.full_messages.join(", "), status: 422)
        end
        on_failed_policy(:can_log_distance) { raise Discourse::InvalidAccess }
        on_model_errors(:entry) do |model|
          render_json_error(model.errors.full_messages.join(", "), status: 422)
        end
      end
    end

    def destroy
      RemoveEntry.call(service_params) do
        on_success { render json: { total_meters: Entry.total_meters_for(current_user) } }
        on_failed_contract { raise Discourse::InvalidParameters.new(:entry_id) }
        on_model_not_found(:entry) { raise Discourse::NotFound }
        on_failed_policy(:can_remove_entry) { raise Discourse::InvalidAccess }
      end
    end

    private

    def rate_limit_logging
      RateLimiter.new(current_user, "walking-challenge-log", 30, 1.hour).performed!
    end
  end
end

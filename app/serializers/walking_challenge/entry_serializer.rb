# frozen_string_literal: true

module WalkingChallenge
  class EntrySerializer < ApplicationSerializer
    attributes :id, :distance_meters, :activity, :logged_on, :note, :source, :created_at

    has_one :user, serializer: BasicUserSerializer, embed: :objects

    def include_user?
      @options[:include_user]
    end

    def include_note?
      !@options[:include_user]
    end
  end
end

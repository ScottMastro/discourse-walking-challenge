# frozen_string_literal: true

module WalkingChallenge
  class ParticipantSerializer < ApplicationSerializer
    attributes :meters, :last_logged_on

    has_one :user, serializer: BasicUserSerializer, embed: :objects
  end
end

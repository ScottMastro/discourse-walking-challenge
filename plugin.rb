# frozen_string_literal: true

# name: discourse-walking-challenge
# about: Log walks, runs and rides together and watch everyone travel a shared overworld route.
# version: 0.1.0
# authors: Scott Mastromatteo
# url: https://github.com/ScottMastro/discourse-walking-challenge

enabled_site_setting :walking_challenge_enabled

register_asset "stylesheets/walk.scss"

%w[person-walking circle-check far-circle list plus user].each { |icon| register_svg_icon(icon) }

module ::WalkingChallenge
  PLUGIN_NAME = "discourse-walking-challenge"
  ANNOUNCED_STOPS_FIELD = "walking_challenge_announced_stops"
end

require_relative "lib/walking_challenge/engine"

after_initialize do
  register_user_custom_field_type(WalkingChallenge::ANNOUNCED_STOPS_FIELD, :integer)
end

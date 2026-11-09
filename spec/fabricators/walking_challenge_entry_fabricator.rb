# frozen_string_literal: true

Fabricator(:walking_challenge_entry, class_name: "WalkingChallenge::Entry") do
  user
  distance_meters 5000
  activity "walk"
  logged_on { Date.today }
end

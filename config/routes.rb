# frozen_string_literal: true

WalkingChallenge::Engine.routes.draw do
  get "/walk" => "challenge#show"
  post "/walk/entries" => "entries#create"
  delete "/walk/entries/:entry_id" => "entries#destroy"
end

Discourse::Application.routes.append { mount ::WalkingChallenge::Engine, at: "/" }

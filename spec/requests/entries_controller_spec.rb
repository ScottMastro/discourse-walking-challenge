# frozen_string_literal: true

RSpec.describe WalkingChallenge::EntriesController do
  fab!(:user)
  fab!(:other_user, :user)

  before { SiteSetting.walking_challenge_enabled = true }

  describe "#create" do
    let(:params) { { distance: 3, unit: "km", activity: "run", logged_on: Date.today.to_s } }

    it "requires a login" do
      post "/walk/entries.json", params: params

      expect(response.status).to eq(403)
    end

    it "logs the distance and returns the new total" do
      Fabricate(:walking_challenge_entry, user:, distance_meters: 1000)
      sign_in(user)

      post "/walk/entries.json", params: params

      expect(response.status).to eq(201)
      expect(response.parsed_body["entry"]["distance_meters"]).to eq(3000)
      expect(response.parsed_body["total_meters"]).to eq(4000)
    end

    it "explains what is wrong with invalid input" do
      sign_in(user)

      post "/walk/entries.json", params: params.merge(distance: -1)

      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"].join).to include("Distance")
    end
  end

  describe "#destroy" do
    fab!(:entry) { Fabricate(:walking_challenge_entry, user:) }

    it "lets the owner remove an entry" do
      sign_in(user)

      delete "/walk/entries/#{entry.id}.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["total_meters"]).to eq(0)
    end

    it "does not let other users remove it" do
      sign_in(other_user)

      delete "/walk/entries/#{entry.id}.json"

      expect(response.status).to eq(403)
      expect(WalkingChallenge::Entry.exists?(entry.id)).to eq(true)
    end
  end
end

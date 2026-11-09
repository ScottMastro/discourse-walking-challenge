# frozen_string_literal: true

RSpec.describe WalkingChallenge::ChallengeController do
  fab!(:user)
  fab!(:walker, :user)

  before { SiteSetting.walking_challenge_enabled = true }

  describe "#show" do
    it "returns the route, standings and the visitor's own entries" do
      Fabricate(:walking_challenge_entry, user: walker, distance_meters: 8000, note: "Secret")
      own = Fabricate(:walking_challenge_entry, user:, distance_meters: 3000)
      sign_in(user)

      get "/walk.json"

      expect(response.status).to eq(200)
      body = response.parsed_body
      expect(body["route"]["legs"].size).to eq(WalkingChallenge::Route::LEGS.size)
      expect(body["participants"].map { |p| [p["user"]["username"], p["meters"]] }).to eq(
        [[walker.username, 8000], [user.username, 3000]],
      )
      expect(body["own_entries"].map { |e| e["id"] }).to eq([own.id])
      expect(body["recent_entries"].map { |e| e["note"] }).to all(be_nil)
    end

    it "is readable when logged out" do
      get "/walk.json"

      expect(response.status).to eq(200)
      expect(response.parsed_body["own_entries"]).to eq([])
    end

    it "returns 404 when the plugin is disabled" do
      SiteSetting.walking_challenge_enabled = false

      get "/walk.json"

      expect(response.status).to eq(404)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Jobs::WalkingChallenge::AnnounceArrivals do
  describe "#execute" do
    subject(:execute) { described_class.new.execute(user_id: user.id) }

    fab!(:user)
    fab!(:topic) { Fabricate(:post).topic }

    let(:pewter_meters) { WalkingChallenge::Route::LEGS.first.meters }
    let(:cerulean_meters) { WalkingChallenge::Route::LEGS.first(2).sum(&:meters) }

    before do
      SiteSetting.walking_challenge_enabled = true
      SiteSetting.walking_challenge_announce_topic_id = topic.id
    end

    it "posts once for each newly reached stop" do
      Fabricate(:walking_challenge_entry, user:, distance_meters: cerulean_meters)

      expect { execute }.to change { topic.posts.count }.by(1)
      expect(topic.posts.last.raw).to include("Pewter City", "Cerulean City", "@#{user.username}")
    end

    it "does not repeat a stop that was already announced" do
      Fabricate(:walking_challenge_entry, user:, distance_meters: pewter_meters)
      described_class.new.execute(user_id: user.id)

      expect { execute }.not_to change { topic.posts.count }
    end

    it "does nothing before the first stop" do
      Fabricate(:walking_challenge_entry, user:, distance_meters: pewter_meters - 1)

      expect { execute }.not_to change { topic.posts.count }
    end
  end
end

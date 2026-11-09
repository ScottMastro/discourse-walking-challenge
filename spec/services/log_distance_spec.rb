# frozen_string_literal: true

RSpec.describe WalkingChallenge::LogDistance do
  describe described_class::Contract, type: :model do
    it { is_expected.to validate_presence_of(:logged_on) }
    it { is_expected.to validate_inclusion_of(:unit).in_array(%w[mi km]) }

    it do
      is_expected.to validate_inclusion_of(:activity).in_array(WalkingChallenge::Entry::ACTIVITIES)
    end

    it do
      is_expected.to validate_length_of(:note).is_at_most(WalkingChallenge::Entry::NOTE_MAX_LENGTH)
    end

    it "rejects distances above the per-entry limit and dates after tomorrow" do
      SiteSetting.walking_challenge_max_entry_km = 10
      contract = described_class.new(distance: 11, unit: "km", logged_on: Date.today + 3)

      expect(contract).not_to be_valid
      expect(contract.errors.attribute_names).to contain_exactly(:distance, :logged_on)
    end
  end

  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:user)

    let(:params) { { distance: 3.5, unit: "mi", activity: "walk", logged_on: Date.today.to_s } }
    let(:dependencies) { { guardian: user.guardian } }

    before { SiteSetting.walking_challenge_enabled = true }

    context "when the contract is invalid" do
      let(:params) { { distance: 0, logged_on: Date.today.to_s } }

      it { is_expected.to fail_a_contract }
    end

    context "when the user is silenced" do
      before { user.update!(silenced_till: 1.day.from_now) }

      it { is_expected.to fail_a_policy(:can_log_distance) }
    end

    context "when the user is anonymous" do
      let(:dependencies) { { guardian: Guardian.new } }

      it { is_expected.to fail_a_policy(:can_log_distance) }
    end

    context "when everything is ok" do
      it { is_expected.to run_successfully }

      it "stores the distance in meters" do
        expect(result.entry).to have_attributes(
          user:,
          distance_meters: 5633,
          activity: "walk",
          source: "manual",
        )
      end

      it "converts kilometers" do
        params[:distance] = 2
        params[:unit] = "km"

        expect(result.entry.distance_meters).to eq(2000)
      end

      it "does not schedule an announcement when no topic is configured" do
        expect { result }.not_to change { Jobs::WalkingChallenge::AnnounceArrivals.jobs.size }
      end
    end

    context "when an announcement topic is configured" do
      before { SiteSetting.walking_challenge_announce_topic_id = 1 }

      it "schedules an arrival announcement" do
        expect { result }.to change { Jobs::WalkingChallenge::AnnounceArrivals.jobs.size }.by(1)
      end
    end
  end
end

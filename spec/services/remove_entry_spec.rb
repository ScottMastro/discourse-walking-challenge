# frozen_string_literal: true

RSpec.describe WalkingChallenge::RemoveEntry do
  describe ".call" do
    subject(:result) { described_class.call(params:, **dependencies) }

    fab!(:owner, :user)
    fab!(:other_user, :user)
    fab!(:moderator)
    fab!(:entry) { Fabricate(:walking_challenge_entry, user: owner) }

    let(:params) { { entry_id: entry.id } }
    let(:dependencies) { { guardian: owner.guardian } }

    context "when the entry does not exist" do
      let(:params) { { entry_id: -1 } }

      it { is_expected.to fail_to_find_a_model(:entry) }
    end

    context "when someone else tries to remove it" do
      let(:dependencies) { { guardian: other_user.guardian } }

      it { is_expected.to fail_a_policy(:can_remove_entry) }
    end

    context "when a moderator removes it" do
      let(:dependencies) { { guardian: moderator.guardian } }

      it { is_expected.to run_successfully }
    end

    context "when the owner removes it" do
      it "deletes the entry" do
        expect { result }.to change { WalkingChallenge::Entry.exists?(entry.id) }.to(false)
      end
    end
  end
end

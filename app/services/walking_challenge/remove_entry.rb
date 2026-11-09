# frozen_string_literal: true

module WalkingChallenge
  class RemoveEntry
    include Service::Base

    params do
      attribute :entry_id, :integer

      validates :entry_id, presence: true
    end

    model :entry
    policy :can_remove_entry

    transaction { step :destroy_entry }

    private

    def fetch_entry(params:)
      Entry.find_by(id: params.entry_id)
    end

    def can_remove_entry(guardian:, entry:)
      guardian.is_staff? || guardian.user&.id == entry.user_id
    end

    def destroy_entry(entry:)
      entry.destroy!
    end
  end
end

# frozen_string_literal: true

class CreateWalkingChallengeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :walking_challenge_entries do |t|
      t.integer :user_id, null: false
      t.integer :distance_meters, null: false
      t.string :activity, null: false, limit: 20
      t.date :logged_on, null: false
      t.string :note, null: false, default: "", limit: 120
      t.string :source, null: false, default: "manual", limit: 20
      t.string :external_id, limit: 100
      t.timestamps
    end

    add_index :walking_challenge_entries, %i[user_id logged_on]
    add_index :walking_challenge_entries, :created_at
    add_index :walking_challenge_entries,
              %i[source external_id],
              unique: true,
              where: "external_id IS NOT NULL",
              name: "idx_walking_challenge_entries_on_source_external_id"
  end
end

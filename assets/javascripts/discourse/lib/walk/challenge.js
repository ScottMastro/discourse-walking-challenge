import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import RouteProgress, { formatDistance } from "./progress.js";

const UNIT_KEY = "walking_challenge_unit";

export default class WalkChallenge {
  @tracked participants;
  @tracked ownEntries;
  @tracked unit;

  #currentUser;
  #keyValueStore;

  constructor({ data, currentUser, keyValueStore }) {
    this.progress = new RouteProgress(data.route.legs);
    this.legs = data.route.legs;
    this.maxEntryKm = data.max_entry_km;
    this.participants = data.participants;
    this.ownEntries = data.own_entries;
    this.#currentUser = currentUser;
    this.#keyValueStore = keyValueStore;
    this.unit = keyValueStore.get(UNIT_KEY) === "km" ? "km" : "mi";
  }

  get start() {
    return this.legs[0].from;
  }

  get finish() {
    return this.legs.at(-1).to;
  }

  get you() {
    if (!this.#currentUser) {
      return null;
    }
    return (
      this.participants.find((p) => p.user.id === this.#currentUser.id) ?? {
        user: {
          id: this.#currentUser.id,
          username: this.#currentUser.username,
          name: this.#currentUser.name,
          avatar_template: this.#currentUser.avatar_template,
        },
        meters: 0,
        last_logged_on: null,
      }
    );
  }

  get field() {
    const you = this.you;
    const list =
      you && !you.last_logged_on
        ? [...this.participants, you]
        : this.participants;
    return [...list].sort((a, b) => b.meters - a.meters);
  }

  isYou(participant) {
    return participant.user.id === this.#currentUser?.id;
  }

  format(meters, digits = 1) {
    return formatDistance(meters, this.unit, digits);
  }

  setUnit(unit) {
    this.unit = unit;
    this.#keyValueStore.set({ key: UNIT_KEY, value: unit });
  }

  async logDistance(data) {
    const result = await ajax("/walk/entries.json", { type: "POST", data });
    const before = this.you.meters;
    const after = result.total_meters;

    this.#updateYou(after, result.entry.logged_on);
    this.ownEntries = [result.entry, ...this.ownEntries];

    const reachedBefore = this.progress.stopsReached(before);
    const reachedAfter = this.progress.stopsReached(after);
    return {
      entry: result.entry,
      arrivals: this.legs
        .slice(reachedBefore, reachedAfter)
        .map((leg) => leg.to),
    };
  }

  async removeEntry(entry) {
    const result = await ajax(`/walk/entries/${entry.id}.json`, {
      type: "DELETE",
    });
    this.ownEntries = this.ownEntries.filter((e) => e.id !== entry.id);
    this.#updateYou(result.total_meters, this.ownEntries[0]?.logged_on ?? null);
  }

  #updateYou(meters, lastLoggedOn) {
    const you = { ...this.you, meters, last_logged_on: lastLoggedOn };
    const others = this.participants.filter((p) => p.user.id !== you.user.id);
    this.participants = lastLoggedOn ? [...others, you] : others;
  }
}

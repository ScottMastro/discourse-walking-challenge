import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { i18n } from "discourse-i18n";
import RouteProgress, { formatDistance } from "./progress.js";

const UNIT_KEY = "walking_challenge_unit";
const OPENING_EVENTS = 3;

export default class WalkChallenge {
  @tracked participants;
  @tracked ownEntries;
  @tracked unit;
  @tracked message = null;
  @tracked animation = null;

  overworld = null;

  #currentUser;
  #keyValueStore;
  #messageCount = 0;

  constructor({ data, currentUser, keyValueStore }) {
    this.progress = new RouteProgress(data.route.legs);
    this.legs = data.route.legs;
    this.maxEntryKm = data.max_entry_km;
    this.participants = data.participants;
    this.ownEntries = data.own_entries;
    this.recentEntries = data.recent_entries;
    this.#currentUser = currentUser;
    this.#keyValueStore = keyValueStore;
    this.unit = keyValueStore.get(UNIT_KEY) === "km" ? "km" : "mi";
    this.say(...this.openingLines());
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
          avatar_template: this.#currentUser.avatar_template,
        },
        meters: 0,
        last_logged_on: null,
      }
    );
  }

  get standings() {
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

  say(...lines) {
    this.message = { lines, id: ++this.#messageCount };
  }

  statusLine(participant) {
    const you = this.isYou(participant);
    if (this.progress.finished(participant.meters)) {
      return you
        ? i18n("walking_challenge.events.you_finished", { place: this.finish })
        : i18n("walking_challenge.events.finished", {
            username: participant.user.username,
            place: this.finish,
          });
    }
    if (you && participant.meters === 0) {
      return i18n("walking_challenge.events.you_start", { place: this.start });
    }
    const { leg, remaining } = this.progress.locate(participant.meters);
    return i18n(`walking_challenge.events.${you ? "you_status" : "status"}`, {
      username: participant.user.username,
      distance: this.format(participant.meters),
      remaining: this.format(remaining),
      place: leg.to,
    });
  }

  openingLines() {
    const lines = this.recentEntries.slice(0, OPENING_EVENTS).map((entry) =>
      i18n("walking_challenge.events.logged", {
        username: entry.user.username,
        distance: this.format(entry.distance_meters),
        activity: i18n(
          `walking_challenge.activities.${entry.activity}`
        ).toLowerCase(),
      })
    );
    if (this.you) {
      lines.push(this.statusLine(this.you));
    }
    return lines.length ? lines : [i18n("walking_challenge.events.empty")];
  }

  async logDistance(data) {
    const result = await ajax("/walk/entries.json", { type: "POST", data });
    const before = this.you.meters;
    const after = result.total_meters;

    this.#updateYou(after, result.entry.logged_on);
    this.ownEntries = [result.entry, ...this.ownEntries];

    const lines = [
      i18n("walking_challenge.events.you_logged", {
        distance: this.format(result.entry.distance_meters),
      }),
    ];
    const reachedBefore = this.progress.stopsReached(before);
    const reachedAfter = this.progress.stopsReached(after);
    for (let i = reachedBefore; i < reachedAfter; i++) {
      const last = i === this.legs.length - 1;
      lines.push(
        i18n(
          `walking_challenge.events.${last ? "you_finished" : "you_arrived"}`,
          {
            place: this.legs[i].to,
          }
        )
      );
    }
    if (reachedAfter < this.legs.length) {
      lines.push(this.statusLine(this.you));
    }

    await this.overworld?.walk(this.you, before, after);
    this.say(...lines);
  }

  async removeEntry(entry) {
    const result = await ajax(`/walk/entries/${entry.id}.json`, {
      type: "DELETE",
    });
    this.ownEntries = this.ownEntries.filter((e) => e.id !== entry.id);
    this.#updateYou(result.total_meters, this.ownEntries[0]?.logged_on ?? null);
    this.say(
      i18n("walking_challenge.events.you_removed", {
        distance: this.format(entry.distance_meters),
      }),
      this.statusLine(this.you)
    );
  }

  #updateYou(meters, lastLoggedOn) {
    const you = { ...this.you, meters, last_logged_on: lastLoggedOn };
    const others = this.participants.filter((p) => p.user.id !== you.user.id);
    this.participants = lastLoggedOn ? [...others, you] : others;
  }
}

import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { avatarUrl } from "discourse/lib/avatar-utils";
import { userPath } from "discourse/lib/url";
import { i18n } from "discourse-i18n";
import { TOWNS } from "../../lib/walk/kanto.js";

// Avatars closer than this share a spot, so the later one moves up a lane.
const LANE_GAP_PERCENT = 2.2;
const MAX_LANES = 3;
// Rough label width as a share of the track, used to stagger labels into rows.
const PERCENT_PER_CHARACTER = 0.85;
const LABEL_PADDING_PERCENT = 1.5;

const shortName = (name) => name.replace(/ (City|Town|Island|Plateau)$/, "");

export default class WalkRaceStrip extends Component {
  get ticks() {
    const { legs, progress } = this.args.challenge;
    const places = [legs[0].from, ...legs.map((leg) => leg.to)];
    const positions = [
      0,
      ...progress.stops.map((stop) => progress.fractionOfRoute(stop) * 100),
    ];

    const rowEnds = [];
    const ticks = places.map((name, index) => {
      const percent = positions[index];
      const label = shortName(name);
      const halfWidth = (label.length * PERCENT_PER_CHARACTER) / 2;
      let row = rowEnds.findIndex((end) => percent - halfWidth > end);
      if (row === -1) {
        row = rowEnds.length;
      }
      rowEnds[row] = percent + halfWidth + LABEL_PADDING_PERCENT;
      return {
        name,
        label,
        style: trustHTML(
          `left: ${percent}%; --walk-row: ${row}; --walk-town: ${TOWNS[name]?.color ?? "currentColor"}`
        ),
      };
    });
    return ticks;
  }

  get layout() {
    const challenge = this.args.challenge;
    const laneEnds = [];

    const racers = [...challenge.field]
      .sort(
        (a, b) => a.meters - b.meters || challenge.isYou(a) - challenge.isYou(b)
      )
      .map((participant) => {
        const percent =
          challenge.progress.fractionOfRoute(participant.meters) * 100;
        let lane = laneEnds.findIndex(
          (end) => percent - end >= LANE_GAP_PERCENT
        );
        if (lane === -1) {
          lane = Math.min(laneEnds.length, MAX_LANES - 1);
        }
        laneEnds[lane] = percent;

        return {
          username: participant.user.username,
          href: userPath(participant.user.username),
          src: avatarUrl(participant.user.avatar_template, "medium"),
          isYou: challenge.isYou(participant),
          style: trustHTML(`left: ${percent}%; --walk-lane: ${lane}`),
          title: i18n("walking_challenge.map.walker_title", {
            username: participant.user.username,
            distance: challenge.format(participant.meters),
          }),
        };
      });

    return {
      racers,
      trackStyle: trustHTML(`--walk-lanes: ${Math.max(1, laneEnds.length)}`),
    };
  }

  <template>
    <section aria-labelledby="walk-race-title" class="walk-race">
      <h2 class="walk-race__title" id="walk-race-title">
        {{i18n "walking_challenge.race.title"}}
      </h2>
      <div class="walk-race__track" style={{this.layout.trackStyle}}>
        <div class="walk-race__racers">
          {{#each this.layout.racers as |racer|}}
            <a
              aria-label={{racer.title}}
              class="walk-race__racer {{if racer.isYou '--you'}}"
              data-user-card={{racer.username}}
              href={{racer.href}}
              style={{racer.style}}
              title={{racer.title}}
            >
              <img alt="" height="22" src={{racer.src}} width="22" />
            </a>
          {{/each}}
        </div>
        <div aria-hidden="true" class="walk-race__line"></div>
        <ol class="walk-race__ticks">
          {{#each this.ticks as |tick|}}
            <li
              class="walk-race__tick"
              style={{tick.style}}
              title={{tick.name}}
            >
              <span class="walk-race__label">{{tick.label}}</span>
            </li>
          {{/each}}
        </ol>
      </div>
    </section>
  </template>
}

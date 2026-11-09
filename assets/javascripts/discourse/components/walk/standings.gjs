import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { i18n } from "discourse-i18n";
import WalkMeter from "./meter.gjs";
import WalkSprite from "./sprite.gjs";

export default class WalkStandings extends Component {
  get rows() {
    const challenge = this.args.challenge;
    return challenge.standings.map((participant, index) => {
      const location = challenge.progress.locate(participant.meters);
      const finished = challenge.progress.finished(participant.meters);
      return {
        participant,
        rank: index + 1,
        isYou: challenge.isYou(participant),
        distance: challenge.format(participant.meters),
        fraction: location.fraction,
        percent: Math.round(location.fraction * 100),
        where: finished
          ? i18n("walking_challenge.card.finished", {
              place: challenge.finish,
            })
          : i18n("walking_challenge.card.to_next", {
              distance: challenge.format(location.remaining),
              place: location.leg.to,
            }),
      };
    });
  }

  @action
  show(participant) {
    this.args.challenge.overworld?.focus(participant);
    this.args.challenge.say(this.args.challenge.statusLine(participant));
  }

  <template>
    <article class="walk-standings walk-window">
      <h2 class="walk-standings__title">{{i18n
          "walking_challenge.standings.title"
        }}</h2>
      {{#if this.rows.length}}
        <ol class="walk-standings__list">
          {{#each this.rows as |row|}}
            <li class="walk-standings__row {{if row.isYou '--you'}}">
              <button
                class="walk-standings__button"
                type="button"
                {{on "click" (fn this.show row.participant)}}
              >
                <span class="walk-standings__rank">{{row.rank}}</span>
                <WalkSprite
                  @class="walk-standings__sprite"
                  @userId={{row.participant.user.id}}
                />
                <span class="walk-standings__body">
                  <span
                    class="walk-standings__name"
                  >{{row.participant.user.username}}</span>
                  <WalkMeter
                    @fraction={{row.fraction}}
                    @label={{row.where}}
                    @percent={{row.percent}}
                    @segments={{10}}
                    @small={{true}}
                  />
                  <span class="walk-standings__where">{{row.where}}</span>
                </span>
                <span class="walk-standings__distance">{{row.distance}}</span>
              </button>
            </li>
          {{/each}}
        </ol>
      {{else}}
        <p class="walk-standings__empty">{{i18n
            "walking_challenge.standings.empty"
          }}</p>
      {{/if}}
    </article>
  </template>
}

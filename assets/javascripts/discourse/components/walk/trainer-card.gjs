import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { trustHTML } from "@ember/template";
import { i18n } from "discourse-i18n";
import { TOWNS } from "../../lib/walk/geometry.js";
import { distanceIn, formatDay } from "../../lib/walk/progress.js";
import { stampImage } from "../../lib/walk/sprites.js";
import WalkMeter from "./meter.gjs";
import WalkSprite from "./sprite.gjs";

export default class WalkTrainerCard extends Component {
  get you() {
    return this.args.challenge.you;
  }

  get total() {
    return distanceIn(this.you.meters, this.args.challenge.unit).toFixed(1);
  }

  get lastLogged() {
    return formatDay(this.you.last_logged_on);
  }

  get location() {
    return this.args.challenge.progress.locate(this.you.meters);
  }

  get finished() {
    return this.args.challenge.progress.finished(this.you.meters);
  }

  get nextStop() {
    return this.finished
      ? i18n("walking_challenge.card.finished", {
          place: this.args.challenge.finish,
        })
      : i18n("walking_challenge.card.to_next", {
          distance: this.args.challenge.format(this.location.remaining),
          place: this.location.leg.to,
        });
  }

  get percent() {
    return Math.round(this.location.fraction * 100);
  }

  get stamps() {
    const reached = this.args.challenge.progress.stopsReached(this.you.meters);
    return this.args.challenge.legs.map((leg, index) => {
      const earned = index < reached;
      return {
        label: earned
          ? leg.to
          : i18n("walking_challenge.card.stamp_locked", { place: leg.to }),
        style: trustHTML(
          `background-image: url(${stampImage(index, earned, TOWNS[leg.to]?.roof ?? "#f2c230")})`
        ),
      };
    });
  }

  get stampSummary() {
    const reached = this.args.challenge.progress.stopsReached(this.you.meters);
    return reached
      ? i18n("walking_challenge.card.stamps", {
          count: reached,
          total: this.args.challenge.legs.length,
        })
      : i18n("walking_challenge.card.first_stamp", {
          place: this.args.challenge.legs[0].to,
        });
  }

  <template>
    <article class="walk-card walk-window">
      <div class="walk-card__who">
        <WalkSprite @class="walk-card__sprite" @userId={{this.you.user.id}} />
        <div>
          <h2 class="walk-card__name">{{this.you.user.username}}</h2>
          <p class="walk-card__since">
            {{#if this.you.last_logged_on}}
              {{i18n "walking_challenge.card.last_logged" date=this.lastLogged}}
            {{else}}
              {{i18n "walking_challenge.card.not_started"}}
            {{/if}}
          </p>
        </div>
      </div>

      <p class="walk-card__total">{{this.total}}<small
        >{{@challenge.unit}}</small></p>
      <p class="walk-card__next">{{this.nextStop}}</p>
      <WalkMeter
        @fraction={{this.location.fraction}}
        @label={{this.nextStop}}
        @percent={{this.percent}}
        @segments={{20}}
      />
      <div class="walk-card__legend">
        <span>{{this.location.leg.from}}</span>
        <span>{{this.location.leg.to}}</span>
      </div>

      <ul class="walk-card__stamps">
        {{#each this.stamps as |stamp|}}
          <li
            class="walk-card__stamp"
            style={{stamp.style}}
            title={{stamp.label}}
          >
            <span class="sr-only">{{stamp.label}}</span>
          </li>
        {{/each}}
      </ul>
      <p class="walk-card__stamp-summary">{{this.stampSummary}}</p>

      <div class="walk-card__actions">
        <button class="walk-button --gold" type="button" {{on "click" @onLog}}>
          {{i18n "walking_challenge.log_distance"}}
        </button>
        <button class="walk-button" type="button" {{on "click" @onShowLog}}>
          {{i18n "walking_challenge.card.see_log"}}
        </button>
      </div>

      <div class="walk-card__sync">
        <h3>{{i18n "walking_challenge.card.sync_title"}}</h3>
        <p>{{i18n "walking_challenge.card.sync_body"}}</p>
      </div>
    </article>
  </template>
}

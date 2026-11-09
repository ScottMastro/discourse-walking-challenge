import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import routeAction from "discourse/helpers/route-action";
import { i18n } from "discourse-i18n";
import WalkChallenge from "../../lib/walk/challenge.js";
import WalkLogDistance from "../modal/walk-log-distance.gjs";
import WalkMyLog from "../modal/walk-my-log.gjs";
import WalkOverworld from "./overworld.gjs";
import WalkStandings from "./standings.gjs";
import WalkTrainerCard from "./trainer-card.gjs";

export default class WalkPage extends Component {
  @service currentUser;
  @service keyValueStore;
  @service modal;

  challenge = new WalkChallenge({
    data: this.args.data,
    currentUser: this.currentUser,
    keyValueStore: this.keyValueStore,
  });

  get routeSummary() {
    return i18n("walking_challenge.route_summary", {
      from: this.challenge.start,
      to: this.challenge.finish,
      distance: this.challenge.format(this.challenge.progress.totalMeters, 0),
    });
  }

  @action
  openLog() {
    this.modal.show(WalkLogDistance, { model: { challenge: this.challenge } });
  }

  @action
  openMyLog() {
    this.modal.show(WalkMyLog, { model: { challenge: this.challenge } });
  }

  @action
  setUnit(unit) {
    this.challenge.setUnit(unit);
  }

  <template>
    {{bodyClass "walk-page"}}
    <div class="walk">
      <header class="walk__bar">
        <div class="walk__heading">
          <h1 class="walk__title">{{i18n "walking_challenge.title"}}</h1>
          <p class="walk__route">{{this.routeSummary}}</p>
        </div>
        <div
          aria-label={{i18n "walking_challenge.units"}}
          class="walk__units"
          role="group"
        >
          <button
            aria-pressed={{if (eq this.challenge.unit "mi") "true" "false"}}
            type="button"
            {{on "click" (fn this.setUnit "mi")}}
          >mi</button>
          <button
            aria-pressed={{if (eq this.challenge.unit "km") "true" "false"}}
            type="button"
            {{on "click" (fn this.setUnit "km")}}
          >km</button>
        </div>
        {{#if this.currentUser}}
          <button
            class="walk-button --gold"
            type="button"
            {{on "click" this.openLog}}
          >
            {{i18n "walking_challenge.log_distance"}}
          </button>
        {{else}}
          <button
            class="walk-button --gold"
            type="button"
            {{on "click" (routeAction "showLogin")}}
          >
            {{i18n "walking_challenge.log_in_to_join"}}
          </button>
        {{/if}}
      </header>

      <WalkOverworld @challenge={{this.challenge}} />

      <div class="walk__panels">
        {{#if this.currentUser}}
          <WalkTrainerCard
            @challenge={{this.challenge}}
            @onLog={{this.openLog}}
            @onShowLog={{this.openMyLog}}
          />
        {{/if}}
        <WalkStandings @challenge={{this.challenge}} />
      </div>
    </div>
  </template>
}

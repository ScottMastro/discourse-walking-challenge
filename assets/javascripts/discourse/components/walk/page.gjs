import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import routeAction from "discourse/helpers/route-action";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";
import WalkChallenge from "../../lib/walk/challenge.js";
import WalkLogDistance from "../modal/walk-log-distance.gjs";
import WalkMyLog from "../modal/walk-my-log.gjs";
import WalkKantoMap from "./kanto-map.gjs";
import WalkRaceStrip from "./race-strip.gjs";
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
    <div class="walk">
      <header class="walk__header">
        <div class="walk__heading">
          <h1 class="walk__title">{{i18n "walking_challenge.title"}}</h1>
          <p class="walk__summary">{{this.routeSummary}}</p>
        </div>
        <div class="walk__controls">
          <div
            aria-label={{i18n "walking_challenge.units"}}
            class="walk__units btn-group"
            role="group"
          >
            <DButton
              class="btn-small
                {{if
                  (eq this.challenge.unit 'mi')
                  'btn-primary'
                  'btn-default'
                }}"
              @action={{fn this.setUnit "mi"}}
              @ariaPressed={{eq this.challenge.unit "mi"}}
              @translatedLabel="mi"
            />
            <DButton
              class="btn-small
                {{if
                  (eq this.challenge.unit 'km')
                  'btn-primary'
                  'btn-default'
                }}"
              @action={{fn this.setUnit "km"}}
              @ariaPressed={{eq this.challenge.unit "km"}}
              @translatedLabel="km"
            />
          </div>
          {{#unless this.currentUser}}
            <DButton
              class="btn-primary"
              @action={{routeAction "showLogin"}}
              @icon="user"
              @label="walking_challenge.log_in_to_join"
            />
          {{/unless}}
        </div>
      </header>

      <WalkRaceStrip @challenge={{this.challenge}} />

      <div class="walk__body">
        <WalkKantoMap @challenge={{this.challenge}} />
        {{#if this.currentUser}}
          <WalkTrainerCard
            @challenge={{this.challenge}}
            @onLog={{this.openLog}}
            @onShowLog={{this.openMyLog}}
          />
        {{/if}}
      </div>
    </div>
  </template>
}

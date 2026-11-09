import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import DButton from "discourse/ui-kit/d-button";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";
import { formatDay } from "../../lib/walk/progress.js";

export default class WalkTrainerCard extends Component {
  get you() {
    return this.args.challenge.you;
  }

  get progress() {
    return this.args.challenge.progress;
  }

  get finished() {
    return this.progress.finished(this.you.meters);
  }

  get location() {
    return this.progress.locate(this.you.meters);
  }

  get lastLogged() {
    return this.you.last_logged_on
      ? i18n("walking_challenge.card.last_logged", {
          date: formatDay(this.you.last_logged_on),
        })
      : i18n("walking_challenge.card.not_started");
  }

  get total() {
    return this.args.challenge.format(this.you.meters);
  }

  get routeTotal() {
    return this.args.challenge.format(this.progress.totalMeters, 0);
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

  get barStyle() {
    const percent = this.progress.fractionOfRoute(this.you.meters) * 100;
    return trustHTML(`width: ${percent.toFixed(2)}%`);
  }

  get stops() {
    const reached = this.progress.stopsReached(this.you.meters);
    return this.args.challenge.legs.map((leg, index) => ({
      name: leg.to,
      at: this.args.challenge.format(this.progress.stops[index], 0),
      reached: index < reached,
      next: index === reached,
    }));
  }

  <template>
    <section class="walk-card">
      <header class="walk-card__header">
        {{dAvatar
          this.you.user
          avatarTemplatePath="avatar_template"
          usernamePath="username"
          namePath="name"
          imageSize="large"
        }}
        <div class="walk-card__who">
          <h2 class="walk-card__name">{{this.you.user.username}}</h2>
          <span class="walk-card__meta">{{this.lastLogged}}</span>
        </div>
      </header>

      <p class="walk-card__total">
        <strong>{{this.total}}</strong>
        <span>{{i18n
            "walking_challenge.card.of_total"
            total=this.routeTotal
          }}</span>
      </p>
      <div
        aria-label={{this.nextStop}}
        aria-valuemax="100"
        aria-valuemin="0"
        class="walk-card__bar"
        role="progressbar"
      >
        <span style={{this.barStyle}}></span>
      </div>
      <p class="walk-card__next">{{this.nextStop}}</p>

      <ol class="walk-card__stops">
        {{#each this.stops as |stop|}}
          <li
            class="walk-card__stop
              {{if stop.reached '--reached'}}
              {{if stop.next '--next'}}"
          >
            {{#if stop.reached}}
              {{dIcon "circle-check"}}
            {{else if stop.next}}
              {{dIcon "person-walking"}}
            {{else}}
              {{dIcon "far-circle"}}
            {{/if}}
            <span class="walk-card__stop-name">{{stop.name}}</span>
            <span class="walk-card__stop-at">{{stop.at}}</span>
          </li>
        {{/each}}
      </ol>

      <div class="walk-card__actions">
        <DButton
          class="btn-primary"
          @action={{@onLog}}
          @icon="plus"
          @label="walking_challenge.log_distance"
        />
        <DButton
          class="btn-default"
          @action={{@onShowLog}}
          @icon="list"
          @label="walking_challenge.card.see_log"
        />
      </div>
      <p class="walk-card__sync">{{i18n "walking_challenge.card.sync_soon"}}</p>
    </section>
  </template>
}

import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import { formatDay } from "../../lib/walk/progress.js";

export default class WalkMyLog extends Component {
  @service dialog;

  get entries() {
    const challenge = this.args.model.challenge;
    return challenge.ownEntries.map((entry) => ({
      entry,
      distance: challenge.format(entry.distance_meters),
      activity: i18n(`walking_challenge.activities.${entry.activity}`),
      day: formatDay(entry.logged_on),
    }));
  }

  @action
  remove(row) {
    const { entry, distance, day } = row;
    this.dialog.yesNoConfirm({
      message: i18n("walking_challenge.my_log.remove_confirm", {
        distance,
        date: day,
      }),
      didConfirm: async () => {
        try {
          await this.args.model.challenge.removeEntry(entry);
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  <template>
    <DModal
      class="walk-log-modal walk-my-log"
      @closeModal={{@closeModal}}
      @title={{i18n "walking_challenge.my_log.title"}}
    >
      <:body>
        {{#if this.entries.length}}
          <ul class="walk-my-log__list">
            {{#each this.entries as |row|}}
              <li class="walk-my-log__row">
                <span class="walk-my-log__date">{{row.day}}</span>
                <span class="walk-my-log__what">
                  <strong>{{row.distance}}</strong>
                  {{row.activity}}
                  {{#if row.entry.note}}
                    <span class="walk-my-log__note">{{row.entry.note}}</span>
                  {{/if}}
                </span>
                <DButton
                  class="btn-flat walk-my-log__remove"
                  @action={{fn this.remove row}}
                  @icon="trash-can"
                  @title="walking_challenge.my_log.remove"
                />
              </li>
            {{/each}}
          </ul>
        {{else}}
          <p>{{i18n "walking_challenge.my_log.empty"}}</p>
        {{/if}}
      </:body>
    </DModal>
  </template>
}

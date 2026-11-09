import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { popupAjaxError } from "discourse/lib/ajax-error";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

const ACTIVITIES = ["walk", "run", "bike", "hike", "ski", "other"];

function today() {
  const now = new Date();
  const offset = now.getTimezoneOffset() * 60000;
  return new Date(now - offset).toISOString().slice(0, 10);
}

export default class WalkLogDistance extends Component {
  @service toasts;

  activities = ACTIVITIES.map((value) => ({
    value,
    label: i18n(`walking_challenge.activities.${value}`),
  }));

  formData = {
    activity: "walk",
    distance: null,
    unit: this.args.model.challenge.unit,
    logged_on: today(),
    note: "",
  };

  get maxDistance() {
    const { maxEntryKm, unit } = this.args.model.challenge;
    return unit === "km" ? maxEntryKm : Math.floor(maxEntryKm / 1.609344);
  }

  @action
  async submit(data) {
    const challenge = this.args.model.challenge;
    try {
      const { entry, arrivals } = await challenge.logDistance(data);
      this.args.closeModal();
      const logged = i18n("walking_challenge.toasts.logged", {
        distance: challenge.format(entry.distance_meters),
      });
      const reached = arrivals.length
        ? i18n("walking_challenge.toasts.arrived", {
            places: arrivals.join(", "),
          })
        : "";
      this.toasts.success({
        duration: "long",
        data: { message: [logged, reached].filter(Boolean).join(" ") },
      });
    } catch (error) {
      popupAjaxError(error);
    }
  }

  <template>
    <DModal
      class="walk-log-modal"
      @closeModal={{@closeModal}}
      @title={{i18n "walking_challenge.log_modal.title"}}
    >
      <:body>
        <Form @data={{this.formData}} @onSubmit={{this.submit}} as |form|>
          <form.Field
            @format="full"
            @name="activity"
            @showTitle={{false}}
            @title={{i18n "walking_challenge.log_modal.activity"}}
            @type="radio-group"
            @validation="required"
            as |field|
          >
            <field.Control class="walk-log-modal__activities" as |group|>
              {{#each this.activities as |activity|}}
                <group.Radio
                  @value={{activity.value}}
                >{{activity.label}}</group.Radio>
              {{/each}}
            </field.Control>
          </form.Field>

          <form.Row as |row|>
            <row.Col @size={{8}}>
              <form.Field
                @format="full"
                @name="distance"
                @title={{i18n "walking_challenge.log_modal.distance"}}
                @type="input-number"
                @validation="required|number|between:0.1,{{this.maxDistance}}"
                as |field|
              >
                <field.Control inputmode="decimal" min="0.1" step="0.1" />
              </form.Field>
            </row.Col>
            <row.Col @size={{4}}>
              <form.Field
                @format="full"
                @name="unit"
                @title={{i18n "walking_challenge.log_modal.unit"}}
                @type="select"
                @validation="required"
                as |field|
              >
                <field.Control @includeNone={{false}} as |select|>
                  <select.Option @value="mi">mi</select.Option>
                  <select.Option @value="km">km</select.Option>
                </field.Control>
              </form.Field>
            </row.Col>
          </form.Row>

          <form.Field
            @format="full"
            @name="logged_on"
            @title={{i18n "walking_challenge.log_modal.date"}}
            @type="input-date"
            @validation="required"
            as |field|
          >
            <field.Control />
          </form.Field>

          <form.Field
            @format="full"
            @name="note"
            @title={{i18n "walking_challenge.log_modal.note"}}
            @type="input"
            @validation="length:0,120"
            as |field|
          >
            <field.Control
              placeholder={{i18n
                "walking_challenge.log_modal.note_placeholder"
              }}
            />
          </form.Field>

          <form.Actions>
            <form.Submit @label="walking_challenge.log_distance" />
          </form.Actions>
        </Form>
      </:body>
    </DModal>
  </template>
}

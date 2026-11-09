import { click, fillIn, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

const MILE = 1609.344;

function state() {
  return {
    route: {
      legs: [
        {
          from: "Pallet Town",
          to: "Pewter City",
          meters: Math.round(175 * MILE),
        },
        {
          from: "Pewter City",
          to: "Cerulean City",
          meters: Math.round(99 * MILE),
        },
      ],
      total_meters: Math.round(274 * MILE),
    },
    participants: [
      {
        meters: Math.round(52.3 * MILE),
        last_logged_on: "2026-11-03",
        user: {
          id: 42,
          username: "dalewilliamson",
          avatar_template: "/a/{size}.png",
        },
      },
    ],
    recent_entries: [
      {
        id: 1,
        distance_meters: Math.round(37.3 * MILE),
        activity: "run",
        logged_on: "2026-11-03",
        source: "manual",
        user: {
          id: 42,
          username: "dalewilliamson",
          avatar_template: "/a/{size}.png",
        },
      },
    ],
    own_entries: [],
    max_entry_km: 160,
  };
}

acceptance("Walking challenge | walk page", function (needs) {
  needs.user();
  needs.settings({ walking_challenge_enabled: true });

  let posted;
  needs.pretender((server, helper) => {
    server.get("/walk.json", () => helper.response(state()));
    server.post("/walk/entries.json", (request) => {
      posted = Object.fromEntries(new URLSearchParams(request.requestBody));
      return helper.response(201, {
        entry: {
          id: 9,
          distance_meters: 5000,
          activity: "walk",
          logged_on: posted.logged_on,
          note: "",
          source: "manual",
        },
        total_meters: 5000,
      });
    });
  });

  test("shows the map, the race strip and your card", async function (assert) {
    await visit("/walk");

    assert.dom(".walk__title").hasText("Let's Be He4lthy");
    assert.dom(".walk-map__town").exists({ count: 11 });
    assert.dom(".walk-map__leg").exists({ count: 2 });
    assert.dom(".walk-race__racer").exists({ count: 2 });
    assert
      .dom(".walk-race__racer.--you")
      .hasAttribute("data-user-card", "eviltrout");
    assert.dom(".walk-map__walker.--you").exists();
    assert.dom(".walk-card__total strong").hasText("0.0 mi");
    assert.dom(".walk-card__stop").exists({ count: 2 });
  });

  test("logging a distance updates your card", async function (assert) {
    await visit("/walk");
    await click(".walk-card__actions .btn-primary");
    await fillIn(".walk-log-modal input[name='distance']", "5");
    await click(".walk-log-modal button[type='submit']");

    assert.strictEqual(posted.distance, "5");
    assert.strictEqual(posted.unit, "mi");
    assert
      .dom(".walk-card__total strong")
      .hasText(`${(5000 / MILE).toFixed(1)} mi`);
    assert
      .dom(".walk-race__racer.--you")
      .hasAttribute("title", "eviltrout: 3.1 mi");
  });

  test("switching units changes every distance", async function (assert) {
    await visit("/walk");
    await click(".walk__units button:last-child");

    assert.dom(".walk__summary").includesText("441 km");
    assert
      .dom(".walk-race__racer:not(.--you)")
      .hasAttribute("title", "dalewilliamson: 84.2 km");
  });
});

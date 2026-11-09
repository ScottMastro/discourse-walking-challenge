import { setupTest } from "ember-qunit";
import { module, test } from "qunit";
import RouteProgress, {
  formatDistance,
  METERS_PER_MILE,
} from "discourse/plugins/discourse-walking-challenge/discourse/lib/walk/progress";

const LEGS = [
  { from: "Pallet Town", to: "Pewter City", meters: 1000 },
  { from: "Pewter City", to: "Cerulean City", meters: 500 },
];

module("Unit | walking challenge | route progress", function (hooks) {
  setupTest(hooks);

  test("locates a distance on the current leg", function (assert) {
    const progress = new RouteProgress(LEGS);
    const spot = progress.locate(1250);

    assert.strictEqual(spot.index, 1);
    assert.strictEqual(spot.leg.to, "Cerulean City");
    assert.strictEqual(spot.fraction, 0.5);
    assert.strictEqual(spot.remaining, 250);
  });

  test("counts stops and clamps past the finish", function (assert) {
    const progress = new RouteProgress(LEGS);

    assert.deepEqual(
      [0, 999, 1000, 1500, 9000].map((meters) => progress.stopsReached(meters)),
      [0, 0, 1, 2, 2]
    );
    assert.true(progress.finished(1500));
    assert.deepEqual(progress.locate(9000).remaining, 0);
  });

  test("formats in the chosen unit", function (assert) {
    assert.strictEqual(formatDistance(METERS_PER_MILE * 3.25, "mi"), "3.3 mi");
    assert.strictEqual(formatDistance(4200, "km"), "4.2 km");
    assert.strictEqual(
      formatDistance(708 * METERS_PER_MILE, "mi", 0),
      "708 mi"
    );
  });
});

import { trustHTML } from "@ember/template";

const segments = (fraction, count) =>
  Array.from({ length: count }, (_, i) => i < Math.round(fraction * count));

const columns = (count) => trustHTML(`--walk-meter-segments: ${count}`);

const WalkMeter = <template>
  <div
    aria-label={{@label}}
    aria-valuemax="100"
    aria-valuemin="0"
    aria-valuenow={{@percent}}
    class="walk-meter {{if @small '--small'}}"
    role="progressbar"
    style={{columns @segments}}
  >
    {{#each (segments @fraction @segments) as |filled|}}
      <i class="walk-meter__segment {{if filled '--filled'}}"></i>
    {{/each}}
  </div>
</template>;

export default WalkMeter;

import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
import { modifier } from "ember-modifier";
import { i18n } from "discourse-i18n";
import { MAP_WIDTH, TILE, TOWNS } from "../../lib/walk/geometry.js";
import { walkerFrames } from "../../lib/walk/sprites.js";
import { paintWorld } from "../../lib/walk/world.js";
import WalkTextBox from "./text-box.gjs";

const WORLD_WIDTH = MAP_WIDTH * TILE;
const CLOSE_SCALE_WIDE = 3;
const CLOSE_SCALE_NARROW = 2;
const NARROW_VIEWPORT = 700;
const CROWD_RADIUS = 10;
const CROWD_STEP = 12;
const STEP_INTERVAL_MS = 160;
const TEXT_BOX_ALLOWANCE = 60;

function clearSpot([x, y], taken) {
  const crowded = (cx) =>
    taken.some(
      ([tx, ty]) =>
        Math.abs(tx - cx) < CROWD_RADIUS && Math.abs(ty - y) < CROWD_RADIUS
    );
  let cx = x;
  for (let tries = 0; tries < 6 && crowded(cx); tries++) {
    cx += tries % 2 ? -CROWD_STEP : CROWD_STEP;
  }
  return [cx, y];
}

function prefersReducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

function closeScale() {
  return window.innerWidth < NARROW_VIEWPORT
    ? CLOSE_SCALE_NARROW
    : CLOSE_SCALE_WIDE;
}

export default class WalkOverworld extends Component {
  @tracked scale = closeScale();
  @tracked whole = false;

  paintTerrain = modifier((canvas) => {
    paintWorld(canvas);
  });
  setupViewport = modifier((element) => {
    this.#viewport = element;
    this.args.challenge.overworld = this;

    const start = this.args.challenge.progress.point(0);
    this.#scrollTo(start, false);
    const timer = setTimeout(
      () =>
        this.focus(
          this.args.challenge.you ?? this.args.challenge.standings[0],
          true
        ),
      prefersReducedMotion() ? 0 : 500
    );
    const stopDragging = this.#enableDragging(element);

    return () => {
      clearTimeout(timer);
      stopDragging();
      cancelAnimationFrame(this.#frameRequest);
      if (this.args.challenge.overworld === this) {
        this.args.challenge.overworld = null;
      }
      this.#viewport = null;
    };
  });

  #viewport = null;

  #frameRequest = null;

  get worldStyle() {
    return trustHTML(`--walk-scale: ${this.scale}`);
  }

  get towns() {
    return Object.entries(TOWNS).map(([name, town]) => ({
      name,
      final: !!town.hall,
      style: trustHTML(
        `left: ${(town.x + 1) * TILE * this.scale}px; top: ${((town.y - 4) * TILE + 6) * this.scale}px`
      ),
    }));
  }

  get walkers() {
    const challenge = this.args.challenge;
    const animation = challenge.animation;
    const taken = [];

    return challenge.standings
      .map((participant) => {
        const animating = animation?.userId === participant.user.id;
        const meters = animating ? animation.meters : participant.meters;
        return {
          participant,
          meters,
          animating,
          isYou: challenge.isYou(participant),
        };
      })
      .sort((a, b) => a.isYou - b.isYou)
      .map(({ participant, meters, animating, isYou }) => {
        const [x, y] = clearSpot(challenge.progress.point(meters), taken);
        taken.push([x, y]);

        const frames = walkerFrames(participant.user.id);
        const frame = animating ? animation.frame : 0;
        return {
          id: participant.user.id,
          participant,
          isYou,
          username: participant.user.username,
          distance: challenge.format(meters),
          label: challenge.statusLine(participant),
          style: trustHTML(
            `left: ${x * this.scale}px; top: ${y * this.scale}px; z-index: ${isYou ? 60 : 2 + Math.round(y / TILE)}; background-image: url(${frames[frame]})`
          ),
        };
      });
  }

  focus(participant, smooth = true) {
    if (participant) {
      this.#scrollTo(
        this.args.challenge.progress.point(participant.meters),
        smooth
      );
    }
  }

  walk(participant, from, to) {
    const challenge = this.args.challenge;
    const duration = prefersReducedMotion()
      ? 0
      : Math.min(2400, 700 + (to - from) / 40);

    return new Promise((resolve) => {
      const startedAt = performance.now();
      const step = (now) => {
        const progress = duration
          ? Math.min(1, (now - startedAt) / duration)
          : 1;
        const meters = from + (to - from) * progress;
        challenge.animation = {
          userId: participant.user.id,
          meters,
          frame: Math.floor(now / STEP_INTERVAL_MS) % 2,
        };
        this.#scrollTo(challenge.progress.point(meters), false);

        if (progress < 1 && this.#viewport) {
          this.#frameRequest = requestAnimationFrame(step);
        } else {
          challenge.animation = null;
          resolve();
        }
      };
      this.#frameRequest = requestAnimationFrame(step);
    });
  }

  @action
  findMe() {
    const you = this.args.challenge.you;
    if (you) {
      this.focus(you);
      this.args.challenge.say(this.args.challenge.statusLine(you));
    }
  }

  @action
  toggleWhole() {
    this.whole = !this.whole;
    this.scale = this.whole
      ? Math.min(1, (this.#viewport?.clientWidth ?? WORLD_WIDTH) / WORLD_WIDTH)
      : closeScale();
    requestAnimationFrame(() => {
      if (this.whole) {
        this.#viewport?.scrollTo(0, 0);
      } else {
        this.focus(
          this.args.challenge.you ?? this.args.challenge.standings[0],
          false
        );
      }
    });
  }

  @action
  selectWalker(participant) {
    this.args.challenge.say(this.args.challenge.statusLine(participant));
  }

  #scrollTo([x, y], smooth) {
    this.#viewport?.scrollTo({
      left: x * this.scale - this.#viewport.clientWidth / 2,
      top:
        y * this.scale - this.#viewport.clientHeight / 2 + TEXT_BOX_ALLOWANCE,
      behavior: smooth && !prefersReducedMotion() ? "smooth" : "auto",
    });
  }

  #enableDragging(element) {
    let origin = null;
    let moved = false;

    const down = (event) => {
      if (event.pointerType !== "mouse" || event.button !== 0) {
        return;
      }
      origin = {
        x: event.clientX,
        y: event.clientY,
        left: element.scrollLeft,
        top: element.scrollTop,
      };
      moved = false;
    };
    const move = (event) => {
      if (!origin) {
        return;
      }
      const dx = event.clientX - origin.x;
      const dy = event.clientY - origin.y;
      if (!moved && Math.hypot(dx, dy) < 4) {
        return;
      }
      moved = true;
      element.classList.add("is-dragging");
      element.scrollLeft = origin.left - dx;
      element.scrollTop = origin.top - dy;
    };
    const up = () => {
      origin = null;
      element.classList.remove("is-dragging");
    };
    const swallowClick = (event) => {
      if (moved) {
        event.stopPropagation();
        event.preventDefault();
        moved = false;
      }
    };

    element.addEventListener("pointerdown", down);
    window.addEventListener("pointermove", move);
    window.addEventListener("pointerup", up);
    element.addEventListener("click", swallowClick, true);

    return () => {
      element.removeEventListener("pointerdown", down);
      window.removeEventListener("pointermove", move);
      window.removeEventListener("pointerup", up);
      element.removeEventListener("click", swallowClick, true);
    };
  }

  <template>
    <section
      aria-label={{i18n "walking_challenge.map_section"}}
      class="walk-map"
    >
      <div
        aria-label={{i18n "walking_challenge.map_label"}}
        class="walk-map__viewport {{if this.whole '--whole'}}"
        tabindex="0"
        {{this.setupViewport}}
      >
        <div class="walk-map__world" style={{this.worldStyle}}>
          <canvas class="walk-map__terrain" {{this.paintTerrain}}></canvas>
          {{#each this.towns as |town|}}
            <div
              class="walk-map__town {{if town.final '--final'}}"
              style={{town.style}}
            >
              {{town.name}}
            </div>
          {{/each}}
          {{#each this.walkers key="id" as |walker|}}
            <button
              aria-label={{walker.label}}
              class="walk-map__walker {{if walker.isYou '--you'}}"
              style={{walker.style}}
              type="button"
              {{on "click" (fn this.selectWalker walker.participant)}}
            >
              <span class="walk-map__tag">{{walker.username}}
                {{walker.distance}}</span>
            </button>
          {{/each}}
        </div>
      </div>

      <div class="walk-map__controls">
        {{#if @challenge.you}}
          <button class="walk-button" type="button" {{on "click" this.findMe}}>
            {{i18n "walking_challenge.find_me"}}
          </button>
        {{/if}}
        <button
          aria-pressed={{if this.whole "true" "false"}}
          class="walk-button"
          type="button"
          {{on "click" this.toggleWhole}}
        >
          {{if
            this.whole
            (i18n "walking_challenge.close_up")
            (i18n "walking_challenge.whole_route")
          }}
        </button>
      </div>

      <WalkTextBox @message={{@challenge.message}} />
    </section>
  </template>
}

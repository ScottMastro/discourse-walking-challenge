import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { cancel, next } from "@ember/runloop";
import { modifier } from "ember-modifier";

const TYPE_INTERVAL_MS = 26;

export default class WalkTextBox extends Component {
  @tracked shown = "";
  @tracked hasMore = false;

  play = modifier((element, [message]) => {
    const start =
      message &&
      next(() => {
        this.#queue = [...message.lines];
        this.#stopTyping();
        this.#next();
      });
    return () => {
      cancel(start);
      this.#stopTyping();
    };
  });
  #queue = [];
  #line = null;

  #timer = null;

  @action
  advance() {
    if (this.#timer) {
      this.#finishLine();
    } else {
      this.#next();
    }
  }

  @action
  handleKey(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.advance();
    }
  }

  #next() {
    const line = this.#queue.shift();
    if (!line) {
      return;
    }
    this.#line = line;
    this.hasMore = false;

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.#finishLine();
      return;
    }

    let typed = 0;
    this.shown = "";
    this.#timer = setInterval(() => {
      typed++;
      this.shown = line.slice(0, typed);
      if (typed >= line.length) {
        this.#finishLine();
      }
    }, TYPE_INTERVAL_MS);
  }

  #finishLine() {
    this.#stopTyping();
    this.shown = this.#line ?? "";
    this.hasMore = this.#queue.length > 0;
  }

  #stopTyping() {
    clearInterval(this.#timer);
    this.#timer = null;
  }

  <template>
    <div
      aria-live="polite"
      class="walk-text-box walk-window"
      role="status"
      tabindex="0"
      {{this.play @message}}
      {{on "click" this.advance}}
      {{on "keydown" this.handleKey}}
    >
      <span class="walk-text-box__line">{{this.shown}}</span>
      {{#if this.hasMore}}
        <span aria-hidden="true" class="walk-text-box__more"></span>
      {{/if}}
    </div>
  </template>
}

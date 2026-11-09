import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { avatarUrl } from "discourse/lib/avatar-utils";
import { userPath } from "discourse/lib/url";
import { i18n } from "discourse-i18n";
import {
  BAYS,
  ISLANDS,
  LABEL_SIDES,
  LAND,
  LANDMARKS,
  LEG_PATHS,
  pointAlong,
  ROUTES,
  TOWNS,
  VIEW_BOX,
} from "../../lib/walk/kanto.js";

const CLUSTER_RADIUS = 0.95;
const MAX_FANNED = 3;
const LABEL_OFFSET = 0.62;

const points = (path) => path.map(([x, y]) => `${x},${y}`).join(" ");

function percentStyle(x, y) {
  const left = ((x - VIEW_BOX.x) / VIEW_BOX.width) * 100;
  const top = ((y - VIEW_BOX.y) / VIEW_BOX.height) * 100;
  return `left: ${left}%; top: ${top}%`;
}

function labelPosition(town, side) {
  switch (side) {
    case "left":
      return { x: town.x - LABEL_OFFSET, y: town.y + 0.18, anchor: "end" };
    case "right":
      return { x: town.x + LABEL_OFFSET, y: town.y + 0.18, anchor: "start" };
    case "above-right":
      return { x: town.x + 0.5, y: town.y - 0.45, anchor: "start" };
    case "below":
      return { x: town.x, y: town.y + LABEL_OFFSET + 0.35, anchor: "middle" };
    default:
      return { x: town.x, y: town.y - LABEL_OFFSET, anchor: "middle" };
  }
}

export default class WalkKantoMap extends Component {
  viewBox = `${VIEW_BOX.x} ${VIEW_BOX.y} ${VIEW_BOX.width} ${VIEW_BOX.height}`;
  land = points(LAND);
  bays = BAYS;
  islands = ISLANDS;
  roads = ROUTES.map((route) => ({ ...route, points: points(route.path) }));
  landmarks = LANDMARKS.filter((landmark) => landmark.kind !== "road").map(
    (landmark) => ({
      ...landmark,
      isMountain: landmark.kind === "mountain",
      isForest: landmark.kind === "forest",
      labelX: landmark.vertical ? landmark.x - 0.55 : landmark.x,
      labelY: landmark.vertical
        ? landmark.y
        : landmark.y + (landmark.kind === "island" ? 0.95 : 0.85),
      labelTransform: landmark.vertical
        ? `rotate(-90 ${landmark.x - 0.55} ${landmark.y})`
        : null,
      mountain: `${landmark.x - 0.42},${landmark.y + 0.3} ${landmark.x},${landmark.y - 0.4} ${landmark.x + 0.42},${landmark.y + 0.3}`,
    })
  );
  roadLabels = LANDMARKS.filter((landmark) => landmark.kind === "road");

  get legs() {
    const legs = this.args.challenge.legs;
    return legs.map((routeLeg, index) => {
      const leg = LEG_PATHS[index];
      const arrow = pointAlong(leg.path, 0.5);
      return {
        points: points(leg.path),
        sea: leg.sea,
        title: i18n("walking_challenge.map.leg_title", {
          number: index + 1,
          from: routeLeg.from,
          to: routeLeg.to,
          distance: this.args.challenge.format(routeLeg.meters, 0),
          via: leg.via,
        }),
        arrow: `translate(${arrow.x} ${arrow.y}) rotate(${arrow.angle})`,
      };
    });
  }

  get towns() {
    const stops = new Set(
      this.args.challenge.legs.flatMap((leg) => [leg.from, leg.to])
    );
    return Object.entries(TOWNS).map(([name, town]) => {
      const label = labelPosition(town, LABEL_SIDES[name]);
      return {
        name,
        ...town,
        stop: stops.has(name),
        finish: name === this.args.challenge.finish,
        labelX: label.x,
        labelY: label.y,
        anchor: label.anchor,
      };
    });
  }

  get clusters() {
    const challenge = this.args.challenge;
    const clusters = [];

    for (const participant of challenge.field) {
      const point = challenge.progress.mapPoint(participant.meters);
      const cluster = clusters.find(
        (c) => Math.hypot(c.x - point.x, c.y - point.y) < CLUSTER_RADIUS
      );
      if (cluster) {
        cluster.members.push(participant);
      } else {
        clusters.push({ x: point.x, y: point.y, members: [participant] });
      }
    }

    return clusters.map((cluster) => {
      const members = [...cluster.members].sort(
        (a, b) => challenge.isYou(b) - challenge.isYou(a) || b.meters - a.meters
      );
      const shown = members.slice(0, MAX_FANNED);
      const hidden = members.slice(MAX_FANNED);
      return {
        style: trustHTML(percentStyle(cluster.x, cluster.y)),
        avatars: shown.map((participant, index) => ({
          username: participant.user.username,
          href: userPath(participant.user.username),
          src: avatarUrl(participant.user.avatar_template, "medium"),
          isYou: challenge.isYou(participant),
          style: trustHTML(`--walk-fan: ${index}`),
          title: i18n("walking_challenge.map.walker_title", {
            username: participant.user.username,
            distance: challenge.format(participant.meters),
          }),
        })),
        more: hidden.length,
        moreTitle: hidden
          .map((p) => `${p.user.username} (${challenge.format(p.meters)})`)
          .join(", "),
      };
    });
  }

  <template>
    <figure class="walk-map">
      <div class="walk-map__canvas">
        <svg
          aria-labelledby="walk-map-title"
          class="walk-map__svg"
          role="img"
          viewBox={{this.viewBox}}
        >
          <title id="walk-map-title">{{i18n
              "walking_challenge.map.title"
            }}</title>
          <rect class="walk-map__sea" height="40" width="40" x="-10" y="-10" />
          <polygon class="walk-map__land" points={{this.land}} />
          {{#each this.bays as |bay|}}
            <ellipse
              class="walk-map__harbor"
              cx={{bay.x}}
              cy={{bay.y}}
              rx={{bay.rx}}
              ry={{bay.ry}}
            />
          {{/each}}
          {{#each this.islands as |island|}}
            <ellipse
              class="walk-map__island"
              cx={{island.x}}
              cy={{island.y}}
              rx={{island.rx}}
              ry={{island.ry}}
            />
          {{/each}}

          {{#each this.roads as |road|}}
            <polyline
              class="walk-map__road {{if road.sea '--sea'}}"
              points={{road.points}}
            ><title>{{road.name}}</title></polyline>
          {{/each}}

          {{#each this.landmarks as |landmark|}}
            <g class="walk-map__landmark --{{landmark.kind}}">
              {{#if landmark.isMountain}}
                <polygon points={{landmark.mountain}} />
              {{else if landmark.isForest}}
                <circle cx={{landmark.x}} cy={{landmark.y}} r="0.32" />
              {{/if}}
              <text
                transform={{landmark.labelTransform}}
                x={{landmark.labelX}}
                y={{landmark.labelY}}
              >{{landmark.name}}</text>
            </g>
          {{/each}}
          {{#each this.roadLabels as |road|}}
            <text
              class="walk-map__road-label"
              dy="-0.32"
              transform="rotate(-90 {{road.x}} {{road.y}})"
              x={{road.x}}
              y={{road.y}}
            >{{road.name}}</text>
          {{/each}}

          {{#each this.legs as |leg|}}
            <g class="walk-map__leg {{if leg.sea '--sea'}}">
              <title>{{leg.title}}</title>
              <polyline class="walk-map__leg-casing" points={{leg.points}} />
              <polyline class="walk-map__leg-line" points={{leg.points}} />
              <path
                class="walk-map__leg-arrow"
                d="M -0.22 -0.2 L 0.2 0 L -0.22 0.2 z"
                transform={{leg.arrow}}
              />
            </g>
          {{/each}}

          {{#each this.towns as |town|}}
            <g
              class="walk-map__town
                {{unless town.stop '--off-route'}}
                {{if town.finish '--finish'}}"
            >
              <circle cx={{town.x}} cy={{town.y}} fill={{town.color}} r="0.4" />
              <text
                text-anchor={{town.anchor}}
                x={{town.labelX}}
                y={{town.labelY}}
              >{{town.name}}</text>
            </g>
          {{/each}}
        </svg>

        <div class="walk-map__walkers">
          {{#each this.clusters as |cluster|}}
            <div class="walk-map__cluster" style={{cluster.style}}>
              {{#each cluster.avatars as |avatar|}}
                <a
                  aria-label={{avatar.title}}
                  class="walk-map__walker {{if avatar.isYou '--you'}}"
                  data-user-card={{avatar.username}}
                  href={{avatar.href}}
                  style={{avatar.style}}
                  title={{avatar.title}}
                >
                  <img alt="" height="32" src={{avatar.src}} width="32" />
                </a>
              {{/each}}
              {{#if cluster.more}}
                <span
                  class="walk-map__more"
                  title={{cluster.moreTitle}}
                >+{{cluster.more}}</span>
              {{/if}}
            </div>
          {{/each}}
        </div>
      </div>
      <figcaption class="walk-map__caption">
        {{i18n "walking_challenge.map.caption"}}
      </figcaption>
    </figure>
  </template>
}

import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { avatarUrl } from "discourse/lib/avatar-utils";
import { userPath } from "discourse/lib/url";
import { i18n } from "discourse-i18n";
import {
  BAYS,
  FORESTS,
  ISLANDS,
  LABEL_SIDES,
  LAND,
  LANDMARKS,
  LEG_PATHS,
  PEAKS,
  pointAlong,
  ROUTES,
  shorePath,
  TOWNS,
  VIEW_BOX,
} from "../../lib/walk/kanto.js";

const CLUSTER_RADIUS = 0.8;
const MAX_FANNED = 3;
const TOWN_SIZE = 0.62;
const LABEL_GAP = 0.5;
const LABEL_HEIGHT = 0.6;
const LABEL_CHAR_WIDTH = 0.225;
const LABEL_PADDING = 0.22;

// Spread of trees within a forest cluster, as offsets from its center.
const TREE_OFFSETS = [
  [0, 0],
  [0.44, 0.12],
  [-0.4, 0.16],
  [0.14, -0.38],
  [-0.16, 0.48],
  [0.52, -0.3],
  [-0.48, -0.3],
];

const points = (path) => path.map(([x, y]) => `${x},${y}`).join(" ");
const round = (value) => Math.round(value * 1000) / 1000;

function percentStyle(x, y) {
  const left = ((x - VIEW_BOX.x) / VIEW_BOX.width) * 100;
  const top = ((y - VIEW_BOX.y) / VIEW_BOX.height) * 100;
  return `left: ${left}%; top: ${top}%`;
}

function ellipsePolygon({ x, y, rx, ry }, corners = 10) {
  return Array.from({ length: corners }, (_, i) => {
    const angle = (i / corners) * Math.PI * 2;
    return [x + Math.cos(angle) * rx, y + Math.sin(angle) * ry];
  });
}

function peakShapes({ x, y, size }) {
  const w = 0.5 * size;
  const h = 0.85 * size;
  const top = [x, y - h * 0.6];
  const left = [x - w, y + h * 0.4];
  const right = [x + w, y + h * 0.4];
  const capY = top[1] + h * 0.32;
  const capW = w * 0.32;
  return {
    body: points([left, top, right]),
    shade: points([top, right, [x + w * 0.1, y + h * 0.4]]),
    cap: points([
      top,
      [x + capW, capY],
      [x + capW * 0.3, capY - h * 0.06],
      [x - capW * 0.2, capY + h * 0.02],
      [x - capW, capY],
    ]),
  };
}

function labelBox(town, side, text) {
  const width = text.length * LABEL_CHAR_WIDTH + LABEL_PADDING * 2;
  const half = TOWN_SIZE / 2;
  let left;
  let top;
  switch (side) {
    case "left":
      left = town.x - half - LABEL_GAP * 0.4 - width;
      top = town.y - LABEL_HEIGHT / 2;
      break;
    case "right":
      left = town.x + half + LABEL_GAP * 0.4;
      top = town.y - LABEL_HEIGHT / 2;
      break;
    case "below":
      left = town.x - width / 2;
      top = town.y + half + LABEL_GAP * 0.3;
      break;
    case "above-right":
      left = town.x + half * 0.6;
      top = town.y - half - LABEL_GAP * 0.3 - LABEL_HEIGHT;
      break;
    default:
      left = town.x - width / 2;
      top = town.y - half - LABEL_GAP * 0.3 - LABEL_HEIGHT;
  }
  return {
    rectX: round(left),
    rectY: round(top),
    rectWidth: round(width),
    textX: round(left + width / 2),
    textY: round(top + LABEL_HEIGHT * 0.72),
  };
}

export default class WalkKantoMap extends Component {
  viewBox = `${VIEW_BOX.x} ${VIEW_BOX.y} ${VIEW_BOX.width} ${VIEW_BOX.height}`;
  land = shorePath(LAND, { seed: 3 });
  islands = ISLANDS.map((island, index) =>
    shorePath(ellipsePolygon(island), {
      seed: 7 + index,
      step: 0.35,
      wiggle: 0.06,
    })
  );
  bays = BAYS.map((bay) =>
    shorePath(ellipsePolygon(bay, 12), { seed: 11, step: 0.4, wiggle: 0.05 })
  );
  roads = ROUTES.map((route) => ({ ...route, points: points(route.path) }));
  trees = FORESTS.flatMap((forest, f) =>
    TREE_OFFSETS.slice(0, forest.trees).map(([dx, dy], t) => {
      const r = 0.2 + ((f + t) % 3) * 0.03;
      const x = forest.x + dx;
      const y = forest.y + dy;
      return {
        x: round(x),
        y: round(y),
        r: round(r),
        lightX: round(x - r * 0.3),
        lightY: round(y - r * 0.32),
        lightR: round(r * 0.5),
        shadowY: round(y + r * 0.95),
      };
    })
  ).sort((a, b) => a.y - b.y);
  peaks = [
    ...PEAKS,
    ...LANDMARKS.filter((l) => l.kind === "mountain").map((l) => ({
      x: l.x,
      y: l.y,
      size: 0.9,
    })),
  ]
    .sort((a, b) => a.y - b.y)
    .map(peakShapes);
  landmarkLabels = LANDMARKS.filter((l) => l.kind !== "road").map((l) => {
    const below =
      l.kind === "island" ? 0.95 : l.kind === "forest" ? 0.95 : 0.85;
    return {
      name: l.name,
      x: l.labelX ?? (l.vertical ? l.x - 0.72 : l.x),
      y: l.labelY ?? (l.vertical ? l.y : l.y + below),
      transform: l.vertical ? `rotate(-90 ${l.x - 0.72} ${l.y})` : null,
    };
  });
  roadLabels = LANDMARKS.filter((l) => l.kind === "road");

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
    return Object.entries(TOWNS).map(([name, town]) => ({
      name,
      color: town.color,
      squareX: town.x - TOWN_SIZE / 2,
      squareY: town.y - TOWN_SIZE / 2,
      stop: stops.has(name),
      finish: name === this.args.challenge.finish,
      ...labelBox(town, LABEL_SIDES[name], name),
    }));
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
      const hidden = members.slice(MAX_FANNED);
      return {
        style: trustHTML(percentStyle(cluster.x, cluster.y)),
        avatars: members.slice(0, MAX_FANNED).map((participant) => ({
          username: participant.user.username,
          href: userPath(participant.user.username),
          src: avatarUrl(participant.user.avatar_template, "small"),
          isYou: challenge.isYou(participant),
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
          <defs>
            <linearGradient id="walk-sea-depth" x1="0" x2="1" y1="0" y2="1">
              <stop offset="0" stop-color="#b9e0f6" />
              <stop offset="1" stop-color="#86bfe6" />
            </linearGradient>
            <radialGradient cx="0.45" cy="0.4" id="walk-land-tone" r="0.75">
              <stop offset="0" stop-color="#e6f0c9" />
              <stop offset="1" stop-color="#cfe2a6" />
            </radialGradient>
            <pattern
              height="1.1"
              id="walk-waves"
              patternUnits="userSpaceOnUse"
              width="1.6"
            >
              <path
                class="walk-map__wave"
                d="M 0.1 0.35 q 0.15 -0.14 0.3 0 q 0.15 0.14 0.3 0 M 0.9 0.9 q 0.15 -0.14 0.3 0 q 0.15 0.14 0.3 0"
              />
            </pattern>
            <filter height="1" id="walk-grain" width="1" x="0" y="0">
              <feTurbulence
                baseFrequency="1.6"
                numOctaves="2"
                seed="4"
                type="fractalNoise"
              />
              <feColorMatrix
                values="0 0 0 0 0.32  0 0 0 0 0.42  0 0 0 0 0.18  0 0 0 0.22 0"
              />
              <feComposite in2="SourceGraphic" operator="in" />
            </filter>
            <filter height="1.4" id="walk-lift" width="1.4" x="-0.2" y="-0.2">
              <feGaussianBlur in="SourceAlpha" stdDeviation="0.06" />
              <feOffset dy="0.06" result="walk-blur" />
              <feFlood flood-color="#1d2b1a" flood-opacity="0.35" />
              <feComposite in2="walk-blur" operator="in" />
              <feMerge>
                <feMergeNode />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>
          </defs>

          <rect class="walk-map__sea" height="40" width="40" x="-10" y="-10" />
          <rect
            class="walk-map__sea-waves"
            height="40"
            width="40"
            x="-10"
            y="-10"
          />

          <path class="walk-map__shallows" d={{this.land}} />
          {{#each this.islands as |island|}}
            <path class="walk-map__shallows" d={{island}} />
          {{/each}}
          <path class="walk-map__land" d={{this.land}} />
          <path class="walk-map__grain" d={{this.land}} />
          {{#each this.islands as |island|}}
            <path class="walk-map__land --island" d={{island}} />
          {{/each}}
          {{#each this.bays as |bay|}}
            <path class="walk-map__bay" d={{bay}} />
          {{/each}}

          {{#each this.roads as |road|}}
            <polyline
              class="walk-map__road-casing {{if road.sea '--sea'}}"
              points={{road.points}}
            />
          {{/each}}
          {{#each this.roads as |road|}}
            <polyline
              class="walk-map__road {{if road.sea '--sea'}}"
              points={{road.points}}
            ><title>{{road.name}}</title></polyline>
          {{/each}}

          <g aria-hidden="true" class="walk-map__scenery">
            {{#each this.trees as |tree|}}
              <g class="walk-map__tree">
                <ellipse
                  class="walk-map__tree-shadow"
                  cx={{tree.x}}
                  cy={{tree.shadowY}}
                  rx={{tree.r}}
                  ry="0.08"
                />
                <circle cx={{tree.x}} cy={{tree.y}} r={{tree.r}} />
                <circle
                  class="walk-map__tree-light"
                  cx={{tree.lightX}}
                  cy={{tree.lightY}}
                  r={{tree.lightR}}
                />
              </g>
            {{/each}}
            {{#each this.peaks as |peak|}}
              <g class="walk-map__peak">
                <polygon points={{peak.body}} />
                <polygon class="walk-map__peak-shade" points={{peak.shade}} />
                <polygon class="walk-map__peak-cap" points={{peak.cap}} />
              </g>
            {{/each}}
          </g>

          {{#each this.landmarkLabels as |landmark|}}
            <text
              class="walk-map__landmark-label"
              transform={{landmark.transform}}
              x={{landmark.x}}
              y={{landmark.y}}
            >{{landmark.name}}</text>
          {{/each}}
          {{#each this.roadLabels as |road|}}
            <text
              class="walk-map__road-label"
              dy="-0.34"
              transform="rotate(-90 {{road.x}} {{road.y}})"
              x={{road.x}}
              y={{road.y}}
            >{{road.name}}</text>
          {{/each}}

          <g class="walk-map__route" filter="url(#walk-lift)">
            {{#each this.legs as |leg|}}
              <polyline class="walk-map__leg-casing" points={{leg.points}} />
            {{/each}}
            {{#each this.legs as |leg|}}
              <g class="walk-map__leg {{if leg.sea '--sea'}}">
                <title>{{leg.title}}</title>
                <polyline class="walk-map__leg-line" points={{leg.points}} />
                <path
                  class="walk-map__leg-arrow"
                  d="M -0.2 -0.18 L 0.2 0 L -0.2 0.18 z"
                  transform={{leg.arrow}}
                />
              </g>
            {{/each}}
          </g>

          {{#each this.towns as |town|}}
            <g
              class="walk-map__town
                {{unless town.stop '--off-route'}}
                {{if town.finish '--finish'}}"
            >
              <rect
                class="walk-map__town-marker"
                fill={{town.color}}
                filter="url(#walk-lift)"
                height="0.62"
                rx="0.12"
                width="0.62"
                x={{town.squareX}}
                y={{town.squareY}}
              />
              <rect
                class="walk-map__town-label-bg"
                height="0.6"
                rx="0.3"
                width={{town.rectWidth}}
                x={{town.rectX}}
                y={{town.rectY}}
              />
              <text
                class="walk-map__town-label"
                text-anchor="middle"
                x={{town.textX}}
                y={{town.textY}}
              >{{town.name}}</text>
            </g>
          {{/each}}

          <g
            aria-hidden="true"
            class="walk-map__compass"
            transform="translate(17.2 14.6)"
          >
            <circle r="0.62" />
            <polygon class="--north" points="0,-0.95 0.16,-0.16 -0.16,-0.16" />
            <polygon points="0,0.95 0.16,0.16 -0.16,0.16" />
            <polygon points="0.95,0 0.16,0.16 0.16,-0.16" />
            <polygon points="-0.95,0 -0.16,0.16 -0.16,-0.16" />
            <text y="-1.08">N</text>
          </g>
          <text
            aria-hidden="true"
            class="walk-map__region"
            x="16.6"
            y="-0.35"
          >Kanto</text>
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
                  title={{avatar.title}}
                >
                  <img alt="" height="24" src={{avatar.src}} width="24" />
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

import { LEG_PATHS, TILE } from "./geometry.js";

export const METERS_PER_MILE = 1609.344;
export const METERS_PER_KM = 1000;

export function distanceIn(meters, unit) {
  return meters / (unit === "km" ? METERS_PER_KM : METERS_PER_MILE);
}

export function formatDay(isoDate) {
  if (!isoDate) {
    return "";
  }
  const [year, month, day] = isoDate.split("-").map(Number);
  return new Date(year, month - 1, day).toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
  });
}

export function formatDistance(meters, unit, digits = 1) {
  return `${distanceIn(meters, unit).toFixed(digits)} ${unit}`;
}

function pathLength(path) {
  let length = 0;
  for (let i = 1; i < path.length; i++) {
    length += Math.hypot(
      path[i][0] - path[i - 1][0],
      path[i][1] - path[i - 1][1]
    );
  }
  return length;
}

export default class RouteProgress {
  constructor(legs) {
    this.legs = legs;
    this.stops = [];
    legs.reduce((sum, leg) => {
      this.stops.push(sum + leg.meters);
      return sum + leg.meters;
    }, 0);
    this.totalMeters = this.stops.at(-1) ?? 0;
    this.lengths = LEG_PATHS.map((leg) => pathLength(leg.path));
  }

  stopsReached(meters) {
    return this.stops.filter((stop) => meters >= stop).length;
  }

  finished(meters) {
    return meters >= this.totalMeters;
  }

  locate(meters) {
    const clamped = Math.max(0, Math.min(this.totalMeters, meters));
    let index = this.stops.findIndex((stop) => clamped < stop);
    if (index === -1) {
      index = this.legs.length - 1;
    }
    const start = index ? this.stops[index - 1] : 0;
    const leg = this.legs[index];
    return {
      index,
      leg,
      fraction: (clamped - start) / leg.meters,
      remaining: this.stops[index] - clamped,
    };
  }

  point(meters) {
    const { index, fraction } = this.locate(meters);
    const path = LEG_PATHS[index].path;
    let target = fraction * this.lengths[index];

    for (let i = 1; i < path.length; i++) {
      const [ax, ay] = path[i - 1];
      const [bx, by] = path[i];
      const segment = Math.hypot(bx - ax, by - ay);
      if (target <= segment || i === path.length - 1) {
        const t = segment ? Math.min(1, target / segment) : 0;
        return [
          (ax + (bx - ax) * t + 1) * TILE,
          (ay + (by - ay) * t + 1) * TILE,
        ];
      }
      target -= segment;
    }
    return [(path[0][0] + 1) * TILE, (path[0][1] + 1) * TILE];
  }
}

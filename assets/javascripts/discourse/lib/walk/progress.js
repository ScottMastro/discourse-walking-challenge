import { LEG_PATHS, pointAlong } from "./kanto.js";

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

export default class RouteProgress {
  constructor(legs) {
    this.legs = legs;
    this.stops = [];
    legs.reduce((sum, leg) => {
      this.stops.push(sum + leg.meters);
      return sum + leg.meters;
    }, 0);
    this.totalMeters = this.stops.at(-1) ?? 0;
  }

  stopsReached(meters) {
    return this.stops.filter((stop) => meters >= stop).length;
  }

  finished(meters) {
    return meters >= this.totalMeters;
  }

  fractionOfRoute(meters) {
    return this.totalMeters
      ? Math.min(1, Math.max(0, meters / this.totalMeters))
      : 0;
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

  mapPoint(meters) {
    const { index, fraction } = this.locate(meters);
    return pointAlong(LEG_PATHS[index].path, fraction);
  }
}

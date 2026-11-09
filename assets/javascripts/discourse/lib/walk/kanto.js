// Kanto geography in Gen 1 Town Map grid units (x east, y south). Town
// positions follow the in-game Town Map; routes follow the real road network.

export const VIEW_BOX = { x: -1.6, y: -1.4, width: 20, height: 17.8 };

export const TOWNS = {
  "Pallet Town": { x: 2, y: 11, color: "#f4f1e8" },
  "Viridian City": { x: 2, y: 8, color: "#3c9a5f" },
  "Pewter City": { x: 2, y: 4, color: "#8b8f97" },
  "Cerulean City": { x: 10, y: 2, color: "#2f7fd1" },
  "Saffron City": { x: 10, y: 5, color: "#e8b922" },
  "Celadon City": { x: 7, y: 5, color: "#7fbf8a" },
  "Lavender Town": { x: 14, y: 5, color: "#9b7fc7" },
  "Vermilion City": { x: 10, y: 9, color: "#e2533a" },
  "Fuchsia City": { x: 8, y: 13, color: "#d6438f" },
  "Cinnabar Island": { x: 2, y: 15, color: "#c8312b" },
  "Indigo Plateau": { x: 0, y: 2, color: "#4b4fa8" },
};

// Where each town's name sits relative to its marker, chosen to avoid roads.
export const LABEL_SIDES = {
  "Pallet Town": "left",
  "Viridian City": "left",
  "Pewter City": "left",
  "Cerulean City": "above",
  "Saffron City": "above-right",
  "Celadon City": "above",
  "Lavender Town": "above-right",
  "Vermilion City": "right",
  "Fuchsia City": "below",
  "Cinnabar Island": "below",
  "Indigo Plateau": "above",
};

export const LANDMARKS = [
  { name: "Viridian Forest", x: 2, y: 6, kind: "forest" },
  { name: "Mt. Moon", x: 6, y: 3, kind: "mountain" },
  { name: "Rock Tunnel", x: 14, y: 3, kind: "mountain" },
  { name: "Victory Road", x: 0, y: 3.6, kind: "mountain", vertical: true },
  { name: "Seafoam Islands", x: 5, y: 15, kind: "island" },
  { name: "Cycling Road", x: 4, y: 9, kind: "road" },
];

export const LAND = [
  [-0.7, -0.6],
  [15.7, -0.6],
  [15.7, 11.4],
  [14.9, 12.2],
  [13.0, 12.4],
  [13.0, 14.3],
  [3.4, 14.3],
  [3.4, 12.0],
  [2.7, 11.7],
  [1.3, 11.7],
  [1.3, 8.7],
  [-0.7, 8.7],
];

// Vermilion's harbor, a bay just south of the city.
export const BAYS = [{ x: 10.7, y: 10.15, rx: 0.95, ry: 0.55 }];

export const ISLANDS = [
  { x: 2, y: 15, rx: 0.85, ry: 0.65 },
  { x: 4.7, y: 15.1, rx: 0.45, ry: 0.35 },
  { x: 5.4, y: 14.9, rx: 0.35, ry: 0.3 },
];

// The full road network, drawn faintly behind the challenge route.
export const ROUTES = [
  {
    name: "Route 1",
    path: [
      [2, 11],
      [2, 8],
    ],
  },
  {
    name: "Route 2",
    path: [
      [2, 8],
      [2, 4],
    ],
  },
  {
    name: "Route 3",
    path: [
      [2, 4],
      [5, 4],
      [5, 3],
      [7, 3],
    ],
  },
  {
    name: "Route 4",
    path: [
      [7, 3],
      [7, 2],
      [10, 2],
    ],
  },
  {
    name: "Route 24",
    path: [
      [10, 2],
      [10, 0.3],
    ],
  },
  {
    name: "Route 25",
    path: [
      [10, 0.3],
      [13, 0.3],
    ],
  },
  {
    name: "Route 5",
    path: [
      [10, 2],
      [10, 5],
    ],
  },
  {
    name: "Route 6",
    path: [
      [10, 5],
      [10, 9],
    ],
  },
  {
    name: "Route 7",
    path: [
      [7, 5],
      [10, 5],
    ],
  },
  {
    name: "Route 8",
    path: [
      [10, 5],
      [14, 5],
    ],
  },
  {
    name: "Route 9",
    path: [
      [10, 2],
      [14, 2],
    ],
  },
  {
    name: "Route 10",
    path: [
      [14, 2],
      [14, 5],
    ],
  },
  {
    name: "Route 11",
    path: [
      [10, 9],
      [14, 9],
    ],
  },
  {
    name: "Route 12",
    path: [
      [14, 5],
      [14, 11],
    ],
  },
  {
    name: "Route 13",
    path: [
      [14, 11],
      [12, 11],
    ],
  },
  {
    name: "Route 14",
    path: [
      [12, 11],
      [12, 13],
    ],
  },
  {
    name: "Route 15",
    path: [
      [12, 13],
      [8, 13],
    ],
  },
  {
    name: "Route 16",
    path: [
      [7, 5],
      [4, 5],
    ],
  },
  {
    name: "Route 17",
    path: [
      [4, 5],
      [4, 13],
    ],
  },
  {
    name: "Route 18",
    path: [
      [4, 13],
      [8, 13],
    ],
  },
  {
    name: "Route 19",
    path: [
      [8, 13],
      [8, 15],
    ],
    sea: true,
  },
  {
    name: "Route 20",
    path: [
      [8, 15],
      [2, 15],
    ],
    sea: true,
  },
  {
    name: "Route 21",
    path: [
      [2, 15],
      [2, 11],
    ],
    sea: true,
  },
  {
    name: "Route 22",
    path: [
      [2, 8],
      [0, 8],
    ],
  },
  {
    name: "Route 23",
    path: [
      [0, 8],
      [0, 2],
    ],
  },
];

// One entry per server leg, in the order of WalkingChallenge::Route::LEGS.
// Legs that retrace a road run in a slightly offset lane so both passes show.
export const LEG_PATHS = [
  {
    via: "Route 1, Route 2",
    path: [
      [2, 11],
      [2, 8],
      [2, 4],
    ],
  },
  {
    via: "Route 3, Mt. Moon, Route 4",
    path: [
      [2, 4],
      [5, 4],
      [5, 3],
      [7, 3],
      [7, 2],
      [10, 2],
    ],
  },
  {
    via: "Route 5, Underground Path, Route 6",
    path: [
      [10, 2],
      [10, 4.2],
      [10.55, 4.6],
      [10.55, 5.4],
      [10, 5.8],
      [10, 9],
    ],
  },
  {
    via: "Route 6, Route 7",
    path: [
      [10, 9],
      [9.8, 8.7],
      [9.8, 5.7],
      [9.5, 5.25],
      [7, 5.25],
    ],
  },
  {
    via: "Route 7",
    path: [
      [7, 5],
      [10, 5],
    ],
  },
  {
    via: "Route 8, Lavender Town, Routes 12 to 15",
    path: [
      [10, 5],
      [14, 5],
      [14, 11],
      [12, 11],
      [12, 13],
      [8, 13],
    ],
  },
  {
    via: "Routes 19 and 20",
    path: [
      [8, 13],
      [8, 15],
      [2, 15],
    ],
    sea: true,
  },
  {
    via: "Route 21, Pallet Town, Route 1",
    path: [
      [2, 15],
      [2.2, 14.6],
      [2.2, 8.3],
      [2, 8],
    ],
    sea: true,
  },
  {
    via: "Route 22, Route 23, Victory Road",
    path: [
      [2, 8],
      [0, 8],
      [0, 2],
    ],
  },
];

export function pathLength(path) {
  let length = 0;
  for (let i = 1; i < path.length; i++) {
    length += Math.hypot(
      path[i][0] - path[i - 1][0],
      path[i][1] - path[i - 1][1]
    );
  }
  return length;
}

export function pointAlong(path, fraction) {
  let remaining = Math.max(0, Math.min(1, fraction)) * pathLength(path);
  for (let i = 1; i < path.length; i++) {
    const [ax, ay] = path[i - 1];
    const [bx, by] = path[i];
    const segment = Math.hypot(bx - ax, by - ay);
    if (remaining <= segment || i === path.length - 1) {
      const t = segment ? Math.min(1, remaining / segment) : 0;
      return {
        x: ax + (bx - ax) * t,
        y: ay + (by - ay) * t,
        angle: (Math.atan2(by - ay, bx - ax) * 180) / Math.PI,
      };
    }
    remaining -= segment;
  }
  const [x, y] = path.at(-1);
  return { x, y, angle: 0 };
}

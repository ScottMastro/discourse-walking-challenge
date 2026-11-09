export const TILE = 16;
export const MAP_WIDTH = 96;
export const MAP_HEIGHT = 52;

export const TOWNS = {
  "Pallet Town": { x: 14, y: 46, roof: "#c8483c" },
  "Viridian City": { x: 14, y: 34, roof: "#3a9a6a" },
  "Pewter City": { x: 14, y: 8, roof: "#8a8f9c" },
  "Cerulean City": { x: 56, y: 8, roof: "#3d6fc4" },
  "Vermillion City": { x: 66, y: 36, roof: "#d0742a" },
  "Celadon City": { x: 40, y: 22, roof: "#4fa24a" },
  "Saffron City": { x: 54, y: 22, roof: "#d9a520" },
  "Fuchsia City": { x: 54, y: 46, roof: "#b4508e" },
  "Cinnabar Island": { x: 30, y: 46, roof: "#c23b2e", island: true },
  "Indigo Plateau": { x: 6, y: 22, roof: "#e8b730", hall: true },
};

// One entry per server leg, in the same order as WalkingChallenge::Route::LEGS.
export const LEG_PATHS = [
  {
    path: [
      [14, 46],
      [14, 34],
      [14, 28],
      [22, 28],
      [22, 18],
      [10, 18],
      [10, 12],
      [14, 12],
      [14, 8],
    ],
  },
  {
    path: [
      [14, 8],
      [28, 8],
      [28, 4],
      [44, 4],
      [44, 8],
      [56, 8],
    ],
  },
  {
    path: [
      [56, 8],
      [66, 8],
      [66, 36],
    ],
  },
  {
    path: [
      [66, 36],
      [40, 36],
      [40, 22],
    ],
  },
  {
    path: [
      [40, 22],
      [54, 22],
    ],
  },
  {
    path: [
      [54, 22],
      [54, 46],
    ],
  },
  {
    path: [
      [54, 46],
      [30, 46],
    ],
    sea: true,
  },
  {
    path: [
      [30, 46],
      [20, 46],
      [20, 34],
      [14, 34],
    ],
  },
  {
    path: [
      [14, 34],
      [6, 34],
      [6, 22],
    ],
  },
];

export function townCenter(name) {
  const town = TOWNS[name];
  return town ? [(town.x + 1) * TILE, (town.y + 1) * TILE] : null;
}

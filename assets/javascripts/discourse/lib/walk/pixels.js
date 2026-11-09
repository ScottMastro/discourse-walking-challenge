export const PALETTE = {
  ink: "#232a44",
  white: "#fbfbf4",
  gold: "#f2c230",
  grass: "#68b04f",
  grassDark: "#4f9440",
  grassLight: "#86c766",
  grassTall: "#3e8238",
  grassTallBase: "#5ea547",
  lawn: "#78bd5c",
  lawnDark: "#64a94c",
  flowerRed: "#f06a5c",
  flowerWhite: "#f7f4ea",
  fence: "#f4efe0",
  fenceLine: "#8a7b62",
  path: "#e3c07e",
  pathDark: "#c49a5a",
  pathLight: "#f0d49a",
  sea: "#3f86cf",
  seaDark: "#2f6fb6",
  seaLight: "#6aa8e6",
  foam: "#d6ecfb",
  buoy: "#e0473b",
  plank: "#a5743f",
  plankDark: "#7a522b",
  plankPost: "#5a3c20",
  sand: "#eedc9f",
  sandDark: "#d8c27f",
  rock: "#c9b48a",
  rockDark: "#a8956c",
  rockLight: "#dcc9a0",
  dryGrass: "#8f9a52",
  stone: "#9097a3",
  stoneLight: "#c3c8d0",
  stoneDark: "#6c7280",
  leaf: "#3f8a3c",
  leafDark: "#2c6a34",
  leafLight: "#79c25d",
  leafOutline: "#1f4a2c",
  treeShadow: "#4a8a3e",
  trunk: "#7a5230",
  wall: "#f3e9d2",
  wallDark: "#d9caa6",
  glass: "#9fd3f5",
  glassShine: "#e6f5ff",
  door: "#7a5230",
  skin: "#f3c9a0",
  trousers: "#3a4470",
  stampBlank: "#e2e0cf",
  stampBlankLight: "#f4f2e6",
  stampBlankLine: "#b9b7a4",
};

// Integer avalanche hash; the bit mixing is the point, so bitwise ops are intended.
/* eslint-disable no-bitwise */
export function hash(x, y, seed = 0) {
  let n =
    Math.imul(x, 374761393) +
    Math.imul(y, 668265263) +
    Math.imul(seed, 982451653);
  n = Math.imul(n ^ (n >>> 13), 1274126177);
  return ((n ^ (n >>> 16)) >>> 0) / 4294967295;
}
/* eslint-enable no-bitwise */

export function valueNoise(x, y, cell, seed) {
  const gx = Math.floor(x / cell);
  const gy = Math.floor(y / cell);
  const fx = x / cell - gx;
  const fy = y / cell - gy;
  const sx = fx * fx * (3 - 2 * fx);
  const sy = fy * fy * (3 - 2 * fy);
  const a = hash(gx, gy, seed);
  const b = hash(gx + 1, gy, seed);
  const c = hash(gx, gy + 1, seed);
  const d = hash(gx + 1, gy + 1, seed);
  return a + (b - a) * sx + (c - a) * sy + (a - b - c + d) * sx * sy;
}

export function shade(hex, amount) {
  const channel = (offset) => {
    const value = parseInt(hex.slice(offset, offset + 2), 16) + amount;
    return Math.max(0, Math.min(255, value)).toString(16).padStart(2, "0");
  };
  return `#${channel(1)}${channel(3)}${channel(5)}`;
}

export function drawRows(canvas, rows, colors) {
  canvas.width = rows[0].length;
  canvas.height = rows.length;
  const ctx = canvas.getContext("2d");
  rows.forEach((row, y) => {
    [...row].forEach((ch, x) => {
      if (colors[ch]) {
        ctx.fillStyle = colors[ch];
        ctx.fillRect(x, y, 1, 1);
      }
    });
  });
  return ctx;
}

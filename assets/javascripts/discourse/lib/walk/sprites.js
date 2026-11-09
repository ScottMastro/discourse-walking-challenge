import { drawRows, PALETTE, shade } from "./pixels.js";

const STANDING = [
  "....oooooooo....",
  "...occcccccco...",
  "..oCCCCCCCCCCo..",
  "...osssssssso...",
  "...ossossosso...",
  "...osssssssso...",
  "....osssssso....",
  "...otttttttto...",
  "..osttttttttso..",
  "..osttttttttso..",
  "..oottttttttoo..",
  "...oppppppppo...",
  "...oppo..oppo...",
  "...oppo..oppo...",
  "...owwo..oppo...",
  "....oo...owwo...",
];
const STEPPING = STANDING.slice(0, 14).concat([
  "...oppo..owwo...",
  "...owwo...oo....",
]);

const OUTFITS = [
  ["#d6453a", "#3b62b8"],
  ["#2f8f6b", "#e8b92e"],
  ["#7c4bb5", "#5aa0e0"],
  ["#e07a2e", "#2c3e78"],
  ["#1f8fa6", "#d6453a"],
  ["#c84f86", "#f1e2b4"],
  ["#516b2b", "#c87a3a"],
  ["#2c3e78", "#e8e4d0"],
  ["#b8862b", "#4a8f4f"],
  ["#8d3b2f", "#9cc6e8"],
];

const STAMP_SHAPES = [
  [
    "....oooo....",
    "..oo####oo..",
    ".o##HH####o.",
    ".o#HH#####o.",
    "o####oo####o",
    "o###o##o###o",
    "o###o##o###o",
    "o####oo####o",
    ".o########o.",
    ".o########o.",
    "..oo####oo..",
    "....oooo....",
  ],
  [
    ".....oo.....",
    "....o##o....",
    "...o#HH#o...",
    "..o#HH###o..",
    ".o###oo###o.",
    "o###o##o###o",
    ".o###oo###o.",
    "..o######o..",
    "...o####o...",
    "....o##o....",
    ".....oo.....",
    "............",
  ],
];

const cache = new Map();

function memo(key, build) {
  if (!cache.has(key)) {
    cache.set(key, build());
  }
  return cache.get(key);
}

function walkerCanvas(rows, outfit) {
  const [cap, shirt] = OUTFITS[outfit];
  const canvas = document.createElement("canvas");
  const ctx = drawRows(canvas, rows, {
    o: PALETTE.ink,
    c: cap,
    C: shade(cap, -45),
    s: PALETTE.skin,
    t: shirt,
    p: PALETTE.trousers,
    w: PALETTE.white,
  });
  ctx.fillStyle = shade(shirt, -40);
  ctx.fillRect(4, 10, 8, 1);
  return canvas;
}

export function outfitFor(userId) {
  return Math.abs(userId * 2654435761) % OUTFITS.length;
}

export function walkerFrames(userId) {
  const outfit = outfitFor(userId);
  return memo(`walker:${outfit}`, () => [
    walkerCanvas(STANDING, outfit).toDataURL(),
    walkerCanvas(STEPPING, outfit).toDataURL(),
  ]);
}

export function stampImage(index, earned, color) {
  return memo(`stamp:${index}:${earned}:${color}`, () => {
    const canvas = document.createElement("canvas");
    drawRows(canvas, STAMP_SHAPES[index % STAMP_SHAPES.length], {
      o: earned ? PALETTE.ink : PALETTE.stampBlankLine,
      "#": earned ? color : PALETTE.stampBlank,
      H: earned ? shade(color, 60) : PALETTE.stampBlankLight,
    });
    return canvas.toDataURL();
  });
}

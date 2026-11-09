import { LEG_PATHS, MAP_HEIGHT, MAP_WIDTH, TILE, TOWNS } from "./geometry.js";
import { hash, PALETTE as C, shade, valueNoise } from "./pixels.js";

const W = MAP_WIDTH;
const H = MAP_HEIGHT;

const isWater = (v) => v === "water" || v === "lane" || v === "pier";
const isWalkway = (v) => v === "path" || v === "lane" || v === "pier";
const isTown = (v) => v === "lawn" || v === "fence" || v === "building";

class Grid {
  constructor() {
    this.cells = Array.from({ length: H }, () => new Array(W).fill("grass"));
  }

  inside(x, y) {
    return x >= 0 && y >= 0 && x < W && y < H;
  }

  get(x, y) {
    return this.inside(x, y) ? this.cells[y][x] : "edge";
  }

  set(x, y, value) {
    if (this.inside(x, y)) {
      this.cells[y][x] = value;
    }
  }

  fill(x0, y0, x1, y1, value, rough = 0) {
    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) {
        const edge = x === x0 || x === x1 || y === y0 || y === y1;
        if (!(rough && edge && hash(x, y, 7) < rough)) {
          this.set(x, y, value);
        }
      }
    }
  }
}

function layRegions(grid) {
  grid.fill(24, 1, 48, 13, "rock");
  grid.fill(22, 38, 49, 51, "water", 0.5);
  grid.fill(76, 27, 95, 51, "water", 0.5);
  grid.fill(71, 2, 91, 12, "water", 0.6);
  grid.fill(26, 42, 35, 50, "grass");
  grid.fill(27, 41, 34, 41, "grass", 0.5);
}

function layPaths(grid) {
  const brush = (x, y) => {
    for (let dy = 0; dy < 2; dy++) {
      for (let dx = 0; dx < 2; dx++) {
        const current = grid.get(x + dx, y + dy);
        grid.set(
          x + dx,
          y + dy,
          current === "water" || current === "lane" ? "lane" : "path"
        );
      }
    }
  };

  LEG_PATHS.forEach(({ path }) => {
    for (let i = 1; i < path.length; i++) {
      const [ax, ay] = path[i - 1];
      const [bx, by] = path[i];
      const steps = Math.max(Math.abs(bx - ax), Math.abs(by - ay));
      for (let s = 0; s <= steps; s++) {
        brush(ax + Math.sign(bx - ax) * s, ay + Math.sign(by - ay) * s);
      }
    }
  });

  for (let x = 71; x <= 80; x++) {
    grid.set(x, 36, "pier");
    grid.set(x, 37, "pier");
  }
  grid.fill(70, 34, 75, 39, "grass");
  for (let x = 70; x <= 75; x++) {
    grid.set(x, 36, "path");
    grid.set(x, 37, "path");
  }
}

function layTowns(grid) {
  const buildings = [];

  const place = (hx, hy, w, h, details) => {
    for (let dy = 0; dy < h; dy++) {
      for (let dx = 0; dx < w; dx++) {
        if (grid.get(hx + dx, hy + dy) !== "lawn") {
          return false;
        }
      }
    }
    for (let dy = 0; dy < h; dy++) {
      for (let dx = 0; dx < w; dx++) {
        grid.set(hx + dx, hy + dy, "building");
      }
    }
    const door = hx + Math.floor(w / 2) - 1;
    for (let dx = 0; dx < 2; dx++) {
      if (grid.get(door + dx, hy + h) === "lawn") {
        grid.set(door + dx, hy + h, "path");
      }
    }
    buildings.push({ x: hx, y: hy, w, h, ...details });
    return true;
  };

  Object.values(TOWNS).forEach(({ x: cx, y: cy, roof, island, hall }) => {
    const x0 = cx - (island ? 4 : 5);
    const x1 = cx + (island ? 5 : 6);
    const y0 = cy - 4;
    const y1 = cy + (island ? 4 : 5);

    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) {
        const current = grid.get(x, y);
        if (current === "edge" || isWalkway(current) || isWater(current)) {
          continue;
        }
        const edge = x === x0 || x === x1 || y === y0 || y === y1;
        grid.set(x, y, edge && !hall ? "fence" : "lawn");
      }
    }

    if (hall) {
      place(cx - 1, cy - 3, 4, 3, { roof, hall: true });
      return;
    }

    const spots = [
      [cx - 4, cy - 3],
      [cx + 4, cy - 3],
      [cx - 4, cy + 2],
      [cx + 4, cy + 2],
      [cx - 2, cy - 3],
      [cx + 2, cy + 2],
    ];
    let placed = 0;
    for (const [hx, hy] of spots) {
      if (placed >= 3) {
        break;
      }
      const tint = placed === 0 ? roof : shade(roof, placed === 1 ? -26 : 22);
      if (place(hx, hy, 2, 2, { roof: tint })) {
        placed++;
      }
    }
  });

  return buildings;
}

function distancesFromWalkways(grid) {
  const dist = Array.from({ length: H }, () => new Array(W).fill(99));
  const queue = [];
  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      if (isWalkway(grid.cells[y][x]) || isTown(grid.cells[y][x])) {
        dist[y][x] = 0;
        queue.push([x, y]);
      }
    }
  }
  for (let i = 0; i < queue.length; i++) {
    const [x, y] = queue[i];
    for (const [dx, dy] of [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ]) {
      const nx = x + dx;
      const ny = y + dy;
      if (grid.inside(nx, ny) && dist[ny][nx] > dist[y][x] + 1) {
        dist[ny][nx] = dist[y][x] + 1;
        queue.push([nx, ny]);
      }
    }
  }
  return dist;
}

function decorate(grid) {
  const dist = distancesFromWalkways(grid);

  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      const v = grid.cells[y][x];
      if (v !== "grass" && v !== "rock") {
        continue;
      }
      const d = dist[y][x];
      let nearWater = false;
      for (let dy = -1; dy <= 1; dy++) {
        for (let dx = -1; dx <= 1; dx++) {
          nearWater ||= grid.get(x + dx, y + dy) === "water";
        }
      }
      if (nearWater && v === "grass") {
        grid.cells[y][x] = "sand";
        continue;
      }

      const border = x < 2 || y < 2 || x >= W - 2 || y >= H - 2;
      const clump = valueNoise(x, y, 5, 3);
      const speck = hash(x, y, 11);

      if (v === "rock") {
        if (border || (d >= 2 && (clump > 0.42 || d >= 4) && speck > 0.2)) {
          grid.cells[y][x] = "boulder";
        }
        continue;
      }

      const forest = x < 30 && y > 10 && y < 42;
      if (border && d > 1) {
        grid.cells[y][x] = "tree";
      } else if (d <= 1) {
        if (speck > 0.86) {
          grid.cells[y][x] = "flowers";
        }
      } else if (forest ? clump > 0.32 || d >= 4 : clump > 0.58 && d >= 2) {
        grid.cells[y][x] = "tree";
      } else if (d <= 4 && valueNoise(x, y, 3, 9) > 0.56) {
        grid.cells[y][x] = "tall";
      } else if (speck > 0.93) {
        grid.cells[y][x] = "flowers";
      }
    }
  }
}

class TilePainter {
  constructor(ctx, grid) {
    this.ctx = ctx;
    this.grid = grid;
    this.ox = 0;
    this.oy = 0;
  }

  at(tx, ty) {
    this.ox = tx * TILE;
    this.oy = ty * TILE;
    return this;
  }

  px(x, y, color, w = 1, h = 1) {
    this.ctx.fillStyle = color;
    this.ctx.fillRect(this.ox + x, this.oy + y, w, h);
  }

  edges(tx, ty, test) {
    const g = this.grid;
    return {
      n: !test(g.get(tx, ty - 1)),
      s: !test(g.get(tx, ty + 1)),
      w: !test(g.get(tx - 1, ty)),
      e: !test(g.get(tx + 1, ty)),
    };
  }

  grass(tx, ty) {
    this.px(0, 0, C.grass, 16, 16);
    for (let k = 0; k < 5; k++) {
      const x = Math.floor(hash(tx, ty, k) * 15);
      const y = 1 + Math.floor(hash(tx, ty, k + 20) * 14);
      this.px(x, y, C.grassDark);
      this.px(x + 1, y - 1, C.grassDark);
    }
    for (let k = 0; k < 2; k++) {
      this.px(
        Math.floor(hash(tx, ty, k + 40) * 16),
        Math.floor(hash(tx, ty, k + 60) * 16),
        C.grassLight
      );
    }
  }

  tall(tx) {
    this.px(0, 0, C.grassTallBase, 16, 16);
    for (let row = 0; row < 2; row++) {
      for (let i = 0; i < 16; i += 2) {
        const h = 4 + ((i * 7 + tx * 3 + row * 5) % 3);
        const base = row * 8 + 8;
        this.px(i, base - h, C.grassTall, 1, h);
        this.px(i + 1, base - h + 2, C.grassDark, 1, h - 2);
        this.px(i, base - h, C.grassLight);
      }
    }
  }

  flower(fx, fy, color) {
    this.px(fx + 1, fy, color);
    this.px(fx, fy + 1, color);
    this.px(fx + 2, fy + 1, color);
    this.px(fx + 1, fy + 2, color);
    this.px(fx + 1, fy + 1, C.gold);
  }

  flowers(tx, ty) {
    this.grass(tx, ty);
    const color = hash(tx, ty, 5) > 0.5 ? C.flowerRed : C.flowerWhite;
    this.flower(3, 4, color);
    this.flower(10, 10, color);
  }

  lawn(tx, ty) {
    this.px(0, 0, C.lawn, 16, 16);
    for (let k = 0; k < 3; k++) {
      this.px(
        Math.floor(hash(tx, ty, k) * 15),
        1 + Math.floor(hash(tx, ty, k + 20) * 14),
        C.lawnDark,
        2,
        1
      );
    }
    if (hash(tx, ty, 77) > 0.9) {
      this.flower(5, 6, hash(tx, ty, 78) > 0.5 ? C.flowerRed : C.flowerWhite);
    }
  }

  fence(tx, ty) {
    this.lawn(tx, ty);
    const g = this.grid;
    const isFence = (v) => v === "fence";
    const left = isFence(g.get(tx - 1, ty));
    const right = isFence(g.get(tx + 1, ty));
    const up = isFence(g.get(tx, ty - 1));
    const down = isFence(g.get(tx, ty + 1));

    if (left || right || !(up || down)) {
      const l = left ? 0 : 6;
      const r = right ? 16 : 10;
      for (const y of [7, 10]) {
        this.px(l, y - 1, C.fenceLine, r - l, 1);
        this.px(l, y, C.fence, r - l, 1);
      }
    }
    if (up || down) {
      const t = up ? 0 : 4;
      const b = down ? 16 : 13;
      this.px(6, t, C.fenceLine, 1, b - t);
      this.px(7, t, C.fence, 2, b - t);
      this.px(9, t, C.fenceLine, 1, b - t);
    }
    this.px(6, 4, C.ink, 4, 9);
    this.px(7, 5, C.fence, 2, 7);
    this.px(7, 5, C.white, 2, 1);
  }

  path(tx, ty) {
    this.px(0, 0, C.path, 16, 16);
    for (let k = 0; k < 4; k++) {
      this.px(
        Math.floor(hash(tx, ty, k) * 16),
        Math.floor(hash(tx, ty, k + 9) * 16),
        hash(tx, ty, k + 3) > 0.5 ? C.pathDark : C.pathLight
      );
    }
    const e = this.edges(tx, ty, isWalkway);
    for (let i = 0; i < 16; i++) {
      const j = (i + tx + ty) % 3 === 0 ? 1 : 0;
      if (e.n) {
        this.px(i, 0, C.grass, 1, 1 + j);
        this.px(i, 1 + j, C.pathDark);
      }
      if (e.s) {
        this.px(i, 15 - j, C.grass, 1, 1 + j);
        this.px(i, 14 - j, C.pathDark);
      }
      if (e.w) {
        this.px(0, i, C.grass, 1 + j, 1);
        this.px(1 + j, i, C.pathDark);
      }
      if (e.e) {
        this.px(15 - j, i, C.grass, 1 + j, 1);
        this.px(14 - j, i, C.pathDark);
      }
    }
  }

  water(tx, ty, lane = false) {
    this.px(0, 0, C.sea, 16, 16);
    for (let k = 0; k < 2; k++) {
      const x = Math.floor(hash(tx, ty, k + 70) * 12);
      const y = 2 + Math.floor(hash(tx, ty, k + 80) * 12);
      this.px(x, y, C.seaLight, 4, 1);
      this.px(x + 1, y - 1, C.seaLight, 2, 1);
    }
    this.px(
      Math.floor(hash(tx, ty, 90) * 16),
      Math.floor(hash(tx, ty, 91) * 16),
      C.seaDark,
      2,
      1
    );

    if (lane) {
      const e = this.edges(tx, ty, (v) => isWalkway(v) || isTown(v));
      for (let i = 0; i < 16; i += 4) {
        if (e.n) {
          this.px(i, 1, C.foam, 2, 1);
        }
        if (e.s) {
          this.px(i + 2, 14, C.foam, 2, 1);
        }
        if (e.w) {
          this.px(1, i, C.foam, 1, 2);
        }
        if (e.e) {
          this.px(14, i + 2, C.foam, 1, 2);
        }
      }
      if ((tx + ty) % 7 === 0 && (e.n || e.s)) {
        const by = e.n ? 2 : 9;
        this.px(6, by, C.ink, 4, 5);
        this.px(7, by + 1, C.buoy, 2, 1);
        this.px(7, by + 2, C.white, 2, 1);
        this.px(7, by + 3, C.buoy, 2, 1);
      }
    }

    const g = this.grid;
    const land = (v) => !isWater(v) && v !== "edge";
    if (land(g.get(tx, ty - 1))) {
      this.px(0, 0, C.foam, 16, 2);
      this.px(0, 2, C.seaLight, 16, 1);
    }
    if (land(g.get(tx, ty + 1))) {
      this.px(0, 14, C.foam, 16, 2);
    }
    if (land(g.get(tx - 1, ty))) {
      this.px(0, 0, C.foam, 2, 16);
    }
    if (land(g.get(tx + 1, ty))) {
      this.px(14, 0, C.foam, 2, 16);
    }
  }

  pier(tx, ty) {
    this.water(tx, ty);
    this.px(0, 0, C.plank, 16, 16);
    for (let i = 0; i < 16; i += 4) {
      this.px(i, 0, C.plankDark, 1, 16);
    }
    const g = this.grid;
    const joined = (v) => v === "pier" || v === "path";
    if (!joined(g.get(tx, ty - 1))) {
      this.px(0, 0, C.ink, 16, 2);
    }
    if (!joined(g.get(tx, ty + 1))) {
      this.px(0, 14, C.ink, 16, 2);
      this.px(2, 14, C.plankPost, 2, 2);
      this.px(12, 14, C.plankPost, 2, 2);
    }
  }

  sand(tx, ty) {
    this.px(0, 0, C.sand, 16, 16);
    for (let k = 0; k < 5; k++) {
      this.px(
        Math.floor(hash(tx, ty, k) * 16),
        Math.floor(hash(tx, ty, k + 5) * 16),
        C.sandDark
      );
    }
  }

  rock(tx, ty) {
    this.px(0, 0, C.rock, 16, 16);
    for (let k = 0; k < 5; k++) {
      const x = Math.floor(hash(tx, ty, k) * 13);
      const y = 1 + Math.floor(hash(tx, ty, k + 5) * 14);
      this.px(x, y, C.rockDark, 2, 1);
      this.px(x + 1, y - 1, C.rockLight);
    }
    if (hash(tx, ty, 31) > 0.6) {
      const x = 3 + Math.floor(hash(tx, ty, 32) * 9);
      this.px(x, 10, C.dryGrass, 1, 3);
      this.px(x + 2, 9, C.dryGrass, 1, 4);
      this.px(x + 4, 11, C.dryGrass, 1, 2);
    }
  }

  boulder(tx, ty) {
    this.rock(tx, ty);
    for (let y = 0; y < 16; y++) {
      for (let x = 0; x < 16; x++) {
        const dx = (x - 7.5) / 7.2;
        const dy = (y - 8.5) / 6.6;
        const d = dx * dx + dy * dy;
        if (d > 1) {
          continue;
        }
        let color = C.stone;
        if (d > 0.78) {
          color = C.ink;
        } else if (dx + dy < -0.7) {
          color = C.stoneLight;
        } else if (dx + dy > 0.55) {
          color = C.stoneDark;
        }
        this.px(x, y, color);
      }
    }
    this.px(5, 6, C.stoneLight, 3, 1);
    this.px(9, 11, C.stoneDark, 2, 1);
  }

  tree(tx, ty) {
    this.grass(tx, ty);
    this.px(3, 13, C.treeShadow, 10, 2);
    for (let y = 0; y < 14; y++) {
      for (let x = 0; x < 16; x++) {
        const dx = (x - 7.5) / 7.6;
        const dy = (y - 6.6) / 6.9;
        const d = dx * dx + dy * dy;
        if (d > 1) {
          continue;
        }
        let color = C.leaf;
        if (d > 0.8) {
          color = C.leafOutline;
        } else if (dx + dy * 0.8 < -0.55) {
          color = C.leafLight;
        } else if (dx * 0.5 + dy > 0.4) {
          color = C.leafDark;
        }
        this.px(x, y, color);
      }
    }
    this.px(4, 3, C.leafLight, 2, 1);
    this.px(9, 6, C.leafDark, 2, 1);
    this.px(6, 8, C.leafDark);
    this.px(6, 12, C.ink, 4, 4);
    this.px(7, 12, C.trunk, 2, 3);
  }

  building(b) {
    this.ox = b.x * TILE;
    this.oy = b.y * TILE;
    const w = b.w * TILE;
    const h = b.h * TILE;
    const roofH = Math.round(h * 0.5);
    const roofDark = shade(b.roof, -40);
    const roofLight = shade(b.roof, 34);

    this.px(0, 2, C.ink, w, roofH + 1);
    this.px(1, 3, b.roof, w - 2, roofH - 1);
    for (let y = 6; y < roofH + 1; y += 4) {
      this.px(1, y, roofDark, w - 2, 1);
    }
    this.px(1, 3, roofLight, w - 2, 1);
    this.px(2, 0, C.ink, w - 4, 3);
    this.px(3, 1, roofLight, w - 6, 1);

    const wy = roofH + 2;
    this.px(2, wy, C.ink, w - 4, h - wy);
    this.px(3, wy, C.wall, w - 6, h - wy - 1);
    this.px(3, wy, C.wallDark, w - 6, 2);

    const dw = b.hall ? 10 : 6;
    const dx = Math.round(w / 2 - dw / 2);
    this.px(dx - 1, h - 11, C.ink, dw + 2, 11);
    this.px(dx, h - 10, C.door, dw, 10);
    this.px(dx + dw - 2, h - 6, C.gold);

    const windows = b.hall ? [6, 16, w - 22, w - 12] : [6, w - 12];
    for (const x of windows) {
      this.px(x - 1, wy + 3, C.ink, 7, 7);
      this.px(x, wy + 4, C.glass, 5, 5);
      this.px(x, wy + 6, C.ink, 5, 1);
      this.px(x + 1, wy + 4, C.glassShine, 1, 2);
    }
    if (b.hall) {
      this.px(w / 2 - 3, 6, C.white, 6, 6);
      this.px(w / 2 - 1, 7, b.roof, 2, 4);
    }
  }
}

let cachedWorld;

export function buildWorld() {
  if (!cachedWorld) {
    const grid = new Grid();
    layRegions(grid);
    layPaths(grid);
    const buildings = layTowns(grid);
    decorate(grid);
    cachedWorld = { grid, buildings };
  }
  return cachedWorld;
}

export function paintWorld(canvas) {
  const { grid, buildings } = buildWorld();
  canvas.width = W * TILE;
  canvas.height = H * TILE;
  const painter = new TilePainter(canvas.getContext("2d"), grid);

  for (let y = 0; y < H; y++) {
    for (let x = 0; x < W; x++) {
      painter.at(x, y);
      switch (grid.cells[y][x]) {
        case "tall":
          painter.tall(x, y);
          break;
        case "flowers":
          painter.flowers(x, y);
          break;
        case "tree":
          painter.tree(x, y);
          break;
        case "path":
          painter.path(x, y);
          break;
        case "lawn":
        case "building":
          painter.lawn(x, y);
          break;
        case "fence":
          painter.fence(x, y);
          break;
        case "water":
          painter.water(x, y);
          break;
        case "lane":
          painter.water(x, y, true);
          break;
        case "pier":
          painter.pier(x, y);
          break;
        case "sand":
          painter.sand(x, y);
          break;
        case "rock":
          painter.rock(x, y);
          break;
        case "boulder":
          painter.boulder(x, y);
          break;
        default:
          painter.grass(x, y);
      }
    }
  }
  buildings.forEach((building) => painter.building(building));
}

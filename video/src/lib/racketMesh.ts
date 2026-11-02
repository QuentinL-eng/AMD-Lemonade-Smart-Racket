// Geometry for the CGI racket, built from real dimensions (metres, measured from the butt, head
// toward +Y, strings facing +Z). Generic and unbranded: 27" long, ~100 sq in head, 16x19.
//
// The frame is one surface, not tubes stuck together: the shaft, the two throat arms and the hoop
// (whose bottom is the bridge) are each a signed distance field of a rounded-box beam swept along
// a centreline, joined with a smooth minimum so the throat gets real fillets where the arms split
// from the shaft and where they flow into the hoop. The field is meshed with surface nets.
// Strings, grommets, the bumper strip and the handle parts are built directly.
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

export const D = {
  length: 0.685,
  // hoop centreline: superellipse, a little wider at the top than at the bridge (egg)
  headA: 0.1245, // half-width to beam centre
  headB: 0.164, // half-length to beam centre
  headY: 0.516,
  n: 2.3,
  egg: 0.045,
  // throat
  shaft: [0.18, 0.262] as const, // shaft centreline y range (bottom hidden in the collar)
  armFrom: 0.222, // arms leave from inside the shaft
  armJoin: -0.98, // hoop angle (right side) the arm runs into, tangentially
  // strings
  mains: 16,
  crosses: 19,
  mainGap: 0.0128,
  crossGap: 0.0158,
  string: 0.00065, // radius (1.3 mm gauge)
  // handle
  grip: [0.013, 0.198] as const,
  gripApothem: 0.0169, // grip 4 3/8"
};

const sp = (v: number, p: number) => Math.sign(v) * Math.abs(v) ** p;
const smoothstep = (a: number, b: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - a) / (b - a)));
  return t * t * (3 - 2 * t);
};
const smin = (a: number, b: number, k: number) => {
  const h = Math.max(k - Math.abs(a - b), 0) / k;
  return Math.min(a, b) - h * h * k * 0.25;
};
/** Signed distance to a 2D rounded box (half sizes hx, hy, corner radius r). */
const roundBox = (x: number, y: number, hx: number, hy: number, r: number) => {
  const qx = Math.abs(x) - (hx - r), qy = Math.abs(y) - (hy - r);
  return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
};

/** 1 at the bridge (bottom of the hoop), falling off either side. */
const bridgeWeight = (t: number) => {
  const a = ((((t + Math.PI / 2) % (2 * Math.PI)) + 3 * Math.PI) % (2 * Math.PI)) - Math.PI; // angle from the bottom
  return Math.exp(-((a / 0.42) ** 2));
};
/** Hoop centreline: squarer over the top (an isometric-style head), flatter along the bridge. */
export const hoopPoint = (t: number): [number, number] => {
  const n = D.n + 0.25 * Math.max(0, Math.sin(t)) + 0.45 * bridgeWeight(t);
  return [D.headA * sp(Math.cos(t), 2 / n) * (1 + D.egg * Math.sin(t)), D.headY + D.headB * sp(Math.sin(t), 2 / n)];
};

// ---------- frame centrelines with their beam sizes ----------
type Piece = { x: Float64Array; y: Float64Array; hw: Float64Array; hd: Float64Array; t: Float64Array; closed: boolean };
const piece = (pts: [number, number][], hw: (i: number, p: [number, number]) => number, hd: (i: number, p: [number, number]) => number, closed: boolean, t?: number[]): Piece => ({
  x: Float64Array.from(pts, (p) => p[0]),
  y: Float64Array.from(pts, (p) => p[1]),
  hw: Float64Array.from(pts, (p, i) => hw(i, p)),
  hd: Float64Array.from(pts, (p, i) => hd(i, p)),
  t: Float64Array.from(t ?? pts.map((_, i) => i)),
  closed,
});

const HOOP_N = 1200;
const hoopT = Array.from({ length: HOOP_N }, (_, i) => -Math.PI / 2 + (2 * Math.PI * i) / HOOP_N);
/** Face half-width along the hoop: 13 mm at the top, a little more down the sides, slim bridge. */
const hoopHW = (t: number) => {
  const s = Math.sin(t);
  const bridge = bridgeWeight(t);
  return (0.0066 + 0.0007 * (1 - s) / 2) * (1 - 0.2 * bridge);
};
/** Beam half-depth: 23 mm at the top, 25 mm through the sides and throat, a thinner bridge. */
const hoopHD = (t: number) => {
  const s = Math.sin(t);
  const bridge = bridgeWeight(t);
  return (0.0115 + 0.001 * (1 - s) / 2) * (1 - 0.3 * bridge);
};

function framePieces(): Piece[] {
  const hoopPts = hoopT.map(hoopPoint);
  const hoop = piece(hoopPts, (i) => hoopHW(hoopT[i]), (i) => hoopHD(hoopT[i]), true, hoopT);

  // Arms: a cubic from straight up out of the shaft into the hoop's tangent, then a stretch
  // along the hoop so the two surfaces run together.
  const arm = (side: 1 | -1) => {
    const tj = side > 0 ? D.armJoin : Math.PI - D.armJoin;
    const dir = side > 0 ? 1 : -1; // direction of increasing height along the hoop
    const P3 = hoopPoint(tj);
    const e = 1e-4, Pn = hoopPoint(tj + dir * e);
    const T = [(Pn[0] - P3[0]) / e, (Pn[1] - P3[1]) / e];
    const l = Math.hypot(T[0], T[1]);
    T[0] /= l; T[1] /= l;
    const P0: [number, number] = [0, D.armFrom];
    const P1: [number, number] = [0, D.armFrom + 0.05];
    const P2: [number, number] = [P3[0] - T[0] * 0.055, P3[1] - T[1] * 0.055];
    const pts: [number, number][] = [];
    const M = 220;
    for (let i = 0; i <= M; i++) {
      const s = i / M, u = 1 - s;
      pts.push([
        u * u * u * P0[0] + 3 * u * u * s * P1[0] + 3 * u * s * s * P2[0] + s * s * s * P3[0],
        u * u * u * P0[1] + 3 * u * u * s * P1[1] + 3 * u * s * s * P2[1] + s * s * s * P3[1],
      ]);
    }
    // past the join the arm runs on along the hoop, tapering until it is inside it
    for (let i = 1; i <= 60; i++) pts.push(hoopPoint(tj + dir * 0.3 * (i / 60)));
    const n = pts.length - 1;
    const tAt = (i: number) => Math.min(1, i / M);
    const tail = (i: number) => Math.max(0, (i - M) / 60);
    return piece(
      pts,
      (i) => (0.0088 + (hoopHW(tj) - 0.0088) * smoothstep(0, 1, tAt(i))) * (1 - 0.6 * smoothstep(0, 1, tail(i))),
      (i) => 0.0124 + (hoopHD(tj) - 0.0124) * smoothstep(0.6, 1, tAt(i)),
      false,
      pts.map((_, i) => i / n),
    );
  };

  const S = 40;
  const shaftPts = Array.from({ length: S + 1 }, (_, i): [number, number] => [0, D.shaft[0] + ((D.shaft[1] - D.shaft[0]) * i) / S]);
  const shaft = piece(shaftPts, (_, p) => 0.0112 - 0.02 * (p[1] - D.shaft[0]), () => 0.0125, false);
  return [hoop, arm(1), arm(-1), shaft];
}

// ---------- the field on a grid ----------
const H = 0.0006; // grid step (0.6 mm)
const BOUNDS = { x: [-0.146, 0.146], y: [0.172, 0.694], z: [-0.0152, 0.0152] };

/**
 * Per column (x, y) and per piece: distance to the centreline in the XY plane, which side of it,
 * and where along it (to look up the beam size). Rasterised segment by segment within a band.
 */
function nearest(pieces: Piece[], nx: number, ny: number) {
  const cols = nx * ny;
  return pieces.map((p) => {
    const dist = new Float32Array(cols).fill(1);
    const side = new Int8Array(cols);
    const at = new Float32Array(cols); // segment index + fraction
    const m = p.x.length, segs = p.closed ? m : m - 1;
    for (let s = 0; s < segs; s++) {
      const a = s, b = (s + 1) % m;
      const ax = p.x[a], ay = p.y[a], bx = p.x[b], by = p.y[b];
      const band = Math.max(p.hw[a], p.hw[b]) + 0.005;
      const i0 = Math.max(0, Math.floor((Math.min(ax, bx) - band - BOUNDS.x[0]) / H)), i1 = Math.min(nx - 1, Math.ceil((Math.max(ax, bx) + band - BOUNDS.x[0]) / H));
      const j0 = Math.max(0, Math.floor((Math.min(ay, by) - band - BOUNDS.y[0]) / H)), j1 = Math.min(ny - 1, Math.ceil((Math.max(ay, by) + band - BOUNDS.y[0]) / H));
      const dx = bx - ax, dy = by - ay, len2 = dx * dx + dy * dy;
      for (let j = j0; j <= j1; j++) {
        const y = BOUNDS.y[0] + j * H;
        for (let i = i0; i <= i1; i++) {
          const x = BOUNDS.x[0] + i * H;
          // past an open end the distance is to the end point, which rounds the beam off
          const fc = Math.min(1, Math.max(0, ((x - ax) * dx + (y - ay) * dy) / len2));
          const px = ax + dx * fc, py = ay + dy * fc;
          const d = Math.hypot(x - px, y - py);
          const c = j * nx + i;
          if (d < dist[c]) {
            dist[c] = d;
            at[c] = s + fc;
            side[c] = (x - px) * dy - (y - py) * dx >= 0 ? 1 : -1; // right of travel
          }
        }
      }
    }
    return { dist, side, at };
  });
}

const lookup = (arr: Float64Array, at: number, closed: boolean) => {
  const m = arr.length, i = Math.floor(at), f = at - i;
  const a = arr[closed ? i % m : Math.min(i, m - 1)], b = arr[closed ? (i + 1) % m : Math.min(i + 1, m - 1)];
  return a + (b - a) * f;
};

/** Surface-nets mesh of the frame, with vertex normals from the field and a paint-zone weight. */
export function buildFrame() {
  const pieces = framePieces();
  const nx = Math.round((BOUNDS.x[1] - BOUNDS.x[0]) / H) + 1;
  const ny = Math.round((BOUNDS.y[1] - BOUNDS.y[0]) / H) + 1;
  const nz = Math.round((BOUNDS.z[1] - BOUNDS.z[0]) / H) + 1;
  const near = nearest(pieces, nx, ny);
  const [hoopN] = near;
  const hoop = pieces[0];

  // The pieces are joined in the face-on outline only (smooth union of the 2D distances), so the
  // throat gets fillets without the beam swelling where pieces overlap; the outline is then given
  // depth with rounded edges, which keeps the faces flat like a moulded frame.
  const cols = nx * ny;
  const plan = new Float32Array(cols).fill(1), depth = new Float32Array(cols), round = new Float32Array(cols);
  const grooveAt = new Float32Array(cols), grooveU = new Float32Array(cols), grooveW = new Float32Array(cols);
  const K = [0, 0.005, 0.005, 0.007]; // fillet size joining each piece onto the ones before it
  for (let c = 0; c < cols; c++) {
    let d = 1, wsum = 0, hd = 0, r = 0, any = false;
    const ds: number[] = [];
    pieces.forEach((p, pi) => {
      const n = near[pi];
      if (n.dist[c] > 0.03) { ds.push(1); return; }
      any = true;
      const hw = lookup(p.hw, n.at[c], p.closed);
      const di = n.dist[c] - hw;
      ds.push(di);
      d = pi === 0 || d === 1 ? Math.min(d, di) : smin(d, di, K[pi]);
    });
    if (!any) continue;
    pieces.forEach((p, pi) => {
      if (ds[pi] === 1) return;
      const w = Math.exp(-(ds[pi] - d) / 0.003);
      const hw = lookup(p.hw, near[pi].at[c], p.closed);
      hd += w * lookup(p.hd, near[pi].at[c], p.closed);
      r += w * Math.min(0.0042, hw * 0.62);
      wsum += w;
    });
    plan[c] = d; depth[c] = hd / wsum; round[c] = r / wsum;
    // string groove round the outside of the head, fading out toward the throat and the bridge
    if (ds[0] !== 1 && hoopN.side[c] > 0 && ds[0] - d < 0.0005) {
      const t = lookup(hoop.t, hoopN.at[c], true);
      grooveAt[c] = smoothstep(-0.86, -0.62, Math.sin(t)); // 0..1 strength
      grooveU[c] = hoopN.dist[c];
      grooveW[c] = lookup(hoop.hw, hoopN.at[c], true);
    }
  }

  const OUT = 0.004;
  /** One layer of the field (all x, z at row j). */
  const layer = (j: number, out: Float32Array) => {
    for (let i = 0; i < nx; i++) {
      const c = j * nx + i;
      if (plan[c] > 0.01) { for (let k = 0; k < nz; k++) out[i * nz + k] = OUT; continue; }
      const d2 = plan[c], hd = depth[c], r = round[c], gd = grooveAt[c];
      for (let k = 0; k < nz; k++) {
        const z = BOUNDS.z[0] + k * H;
        const qx = d2 + r, qy = Math.abs(z) - hd + r;
        let d = Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
        if (gd > 0) d = Math.max(d, -roundBox(grooveU[c] - grooveW[c], z, 0.0021 * gd, 0.0023 * Math.sqrt(gd), 0.0007 * gd));
        out[i * nz + k] = d;
      }
    }
  };

  const pos: number[] = [], nor: number[] = [], zone: number[] = [], idx: number[] = [];
  let L0 = new Float32Array(nx * nz), L1 = new Float32Array(nx * nz);
  // cell vertex ids: this row of cells (V0) and the previous one (Vp)
  let V0 = new Int32Array(nx * nz).fill(-1), Vp = new Int32Array(nx * nz).fill(-1);
  const quad = (a: number, b: number, c: number, d: number, flip: boolean) => {
    if (a < 0 || b < 0 || c < 0 || d < 0) return;
    if (flip) idx.push(a, c, b, a, d, c);
    else idx.push(a, b, c, a, c, d);
  };
  layer(0, L0);
  const corner = new Float32Array(8);
  const EDGES = [[0, 1], [2, 3], [4, 5], [6, 7], [0, 2], [1, 3], [4, 6], [5, 7], [0, 4], [1, 5], [2, 6], [3, 7]];
  // corner c: bit0 = +x, bit1 = +z, bit2 = +y
  for (let j = 0; j < ny - 1; j++) {
    layer(j + 1, L1);
    for (let i = 0; i < nx - 1; i++) {
      for (let k = 0; k < nz - 1; k++) {
        let mask = 0;
        for (let c = 0; c < 8; c++) {
          const L = c & 4 ? L1 : L0;
          const v = L[(i + (c & 1)) * nz + k + ((c >> 1) & 1)];
          corner[c] = v;
          if (v < 0) mask |= 1 << c;
        }
        if (mask === 0 || mask === 255) continue;
        // vertex: mean of the edge crossings
        let sx = 0, sy = 0, sz = 0, cnt = 0;
        for (const [a, b] of EDGES) {
          const va = corner[a], vb = corner[b];
          if (va < 0 === vb < 0) continue;
          const f = va / (va - vb);
          sx += (a & 1) + ((b & 1) - (a & 1)) * f;
          sz += ((a >> 1) & 1) + (((b >> 1) & 1) - ((a >> 1) & 1)) * f;
          sy += ((a >> 2) & 1) + (((b >> 2) & 1) - ((a >> 2) & 1)) * f;
          cnt++;
        }
        const fx = sx / cnt, fy = sy / cnt, fz = sz / cnt;
        // normal: gradient of the trilinear field at that point
        const g = (c: number) => corner[c];
        const lerp = (a: number, b: number, t: number) => a + (b - a) * t;
        const gx = lerp(lerp(g(1) - g(0), g(3) - g(2), fz), lerp(g(5) - g(4), g(7) - g(6), fz), fy);
        const gz = lerp(lerp(g(2) - g(0), g(3) - g(1), fx), lerp(g(6) - g(4), g(7) - g(5), fx), fy);
        const gy = lerp(lerp(g(4) - g(0), g(5) - g(1), fx), lerp(g(6) - g(2), g(7) - g(3), fx), fz);
        const gl = Math.hypot(gx, gy, gz) || 1;
        const X = BOUNDS.x[0] + (i + fx) * H, Y = BOUNDS.y[0] + (j + fy) * H, Z = BOUNDS.z[0] + (k + fz) * H;
        V0[i * nz + k] = pos.length / 3; // this cell's vertex (layer j lives in V0)
        pos.push(X, Y, Z);
        nor.push(gx / gl, gy / gl, gz / gl);
        // paint zone: the +x throat arm from the split to about halfway up (the real racket's
        // light blue panel), with crisp edges
        zone.push(smoothstep(0.0005, 0.0025, X) * smoothstep(0.262, 0.266, Y) * (1 - smoothstep(0.334, 0.338, Y)));

        // faces: for each edge leaving this cell's lower corner, the four cells around it
        const s0 = corner[0] < 0;
        const vid = (ii: number, kk: number, prev: boolean) => (prev ? Vp : V0)[ii * nz + kk];
        // edge along y (corner 0 -> 4): cells (i-1..i, j, k-1..k)
        if (i > 0 && k > 0 && s0 !== corner[4] < 0) quad(vid(i - 1, k - 1, false), vid(i, k - 1, false), vid(i, k, false), vid(i - 1, k, false), s0);
        // edge along x (corner 0 -> 1): cells (i, j-1..j, k-1..k)
        if (j > 0 && k > 0 && s0 !== corner[1] < 0) quad(vid(i, k - 1, true), vid(i, k, true), vid(i, k, false), vid(i, k - 1, false), s0);
        // edge along z (corner 0 -> 2): cells (i-1..i, j-1..j, k)
        if (i > 0 && j > 0 && s0 !== corner[2] < 0) quad(vid(i - 1, k, true), vid(i - 1, k, false), vid(i, k, false), vid(i, k, true), s0);
      }
    }
    // the cells of row j are done: they become the previous row
    const tv = Vp; Vp = V0; V0 = tv; V0.fill(-1);
    const tl = L0; L0 = L1; L1 = tl;
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('normal', new THREE.Float32BufferAttribute(nor, 3));
  g.setAttribute('zone', new THREE.Float32BufferAttribute(zone, 1));
  g.setIndex(idx);
  return g;
}

// ---------- strings and grommets ----------
/** Hoop inner face as a closed polyline (centreline moved inward by the face half-width). */
const innerFace = () => {
  const N = 1600;
  return Array.from({ length: N }, (_, i) => {
    const t = -Math.PI / 2 + (2 * Math.PI * i) / N, e = 1e-4;
    const [x, y] = hoopPoint(t), [x2, y2] = hoopPoint(t + e);
    const tx = x2 - x, ty = y2 - y, l = Math.hypot(tx, ty);
    const w = hoopHW(t);
    return [x - (ty / l) * w, y + (tx / l) * w] as [number, number];
  });
};
/** Where a line x = c (axis 0) or y = c (axis 1) crosses a closed polyline: [low, high]. */
const span = (poly: [number, number][], axis: 0 | 1, c: number) => {
  const hits: number[] = [];
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    if ((a[axis] - c) * (b[axis] - c) <= 0 && a[axis] !== b[axis]) {
      const f = (c - a[axis]) / (b[axis] - a[axis]);
      hits.push(a[1 - axis] + (b[1 - axis] - a[1 - axis]) * f);
    }
  }
  return hits.length >= 2 ? [Math.min(...hits), Math.max(...hits)] : null;
};

export function buildStrings() {
  const inner = innerFace();
  const amp = D.string * 0.9;
  const x0 = -((D.mains - 1) / 2) * D.mainGap;
  const y0 = D.headY - ((D.crosses - 1) / 2) * D.crossGap;
  const tubes: THREE.BufferGeometry[] = [];
  const ends: { p: THREE.Vector3; dir: THREE.Vector3 }[] = [];
  const IN = 0.0015; // strings run this far into the beam
  for (let i = 0; i < D.mains; i++) {
    const x = x0 + i * D.mainGap, sg = i % 2 ? -1 : 1, sp2 = span(inner, 0, x);
    if (!sp2) continue;
    const [lo, hi] = [sp2[0] - IN, sp2[1] + IN];
    const pts: THREE.Vector3[] = [];
    for (let k = 0; k <= 60; k++) {
      const y = lo + ((hi - lo) * k) / 60;
      pts.push(new THREE.Vector3(x, y, sg * amp * Math.cos((Math.PI * (y - y0)) / D.crossGap)));
    }
    tubes.push(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 180, D.string, 6));
    ends.push({ p: new THREE.Vector3(x, sp2[0], 0), dir: new THREE.Vector3(0, -1, 0) }, { p: new THREE.Vector3(x, sp2[1], 0), dir: new THREE.Vector3(0, 1, 0) });
  }
  for (let j = 0; j < D.crosses; j++) {
    const y = y0 + j * D.crossGap, sg = j % 2 ? -1 : 1, sp2 = span(inner, 1, y);
    if (!sp2) continue;
    const [lo, hi] = [sp2[0] - IN, sp2[1] + IN];
    const pts: THREE.Vector3[] = [];
    for (let k = 0; k <= 48; k++) {
      const x = lo + ((hi - lo) * k) / 48;
      pts.push(new THREE.Vector3(x, y, -sg * amp * Math.cos((Math.PI * (x - x0)) / D.mainGap)));
    }
    tubes.push(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 144, D.string, 6));
    ends.push({ p: new THREE.Vector3(sp2[0], y, 0), dir: new THREE.Vector3(-1, 0, 0) }, { p: new THREE.Vector3(sp2[1], y, 0), dir: new THREE.Vector3(1, 0, 0) });
  }
  // a grommet where each string goes into the frame: a short sleeve standing off the inner face
  const up = new THREE.Vector3(0, 1, 0);
  const grommets = ends.map(({ p, dir }) => {
    const g = new THREE.CylinderGeometry(0.0013, 0.0016, 0.0022, 12, 1);
    g.applyQuaternion(new THREE.Quaternion().setFromUnitVectors(up, dir));
    g.translate(p.x - dir.x * 0.0004, p.y - dir.y * 0.0004, 0);
    return g;
  });
  return { strings: mergeGeometries(tubes), grommets: mergeGeometries(grommets) };
}

/** The grommet strip in the outside groove, thick over the top of the head (the bumper). */
export function buildBumper() {
  const t0 = -0.72, t1 = Math.PI + 0.72, N = 500, R = 24;
  const pos: number[] = [], idx: number[] = [];
  for (let i = 0; i <= N; i++) {
    const t = t0 + ((t1 - t0) * i) / N, e = 1e-4;
    const [x, y] = hoopPoint(t), [x2, y2] = hoopPoint(t + e);
    const tx = x2 - x, ty = y2 - y, l = Math.hypot(tx, ty);
    const nx = ty / l, ny = -tx / l; // outward
    const top = smoothstep(0.55, 0.8, Math.sin(t)); // the bumper proper over the top
    const ends = smoothstep(0, 0.06, Math.min(t - t0, t1 - t));
    const proud = (0.0006 + 0.0016 * top) * ends; // how far it stands out of the groove
    const half = 0.0021 + 0.0012 * top; // half height (along z)
    const base = hoopHW(t) - 0.0021; // groove floor
    for (let r = 0; r < R; r++) {
      const a = (2 * Math.PI * r) / R;
      // rounded rectangle in (out, z)
      const cx = Math.cos(a), cz = Math.sin(a);
      const o = base + (0.0021 + proud) / 2 + ((0.0021 + proud) / 2) * sp(cx, 0.35);
      const z = half * sp(cz, 0.35);
      pos.push(x + nx * o, y + ny * o, z);
    }
  }
  for (let i = 0; i < N; i++)
    for (let r = 0; r < R; r++) {
      const a = i * R + r, b = i * R + ((r + 1) % R), c = (i + 1) * R + r, d = (i + 1) * R + ((r + 1) % R);
      idx.push(a, c, b, b, c, d);
    }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}

// ---------- handle ----------
/** Rounded octagon (apothem a) in polar form, a bevel facing +Z like a real handle. */
const octagon = (th: number, a: number) => {
  const seg = Math.PI / 4;
  const phi = ((((th + seg / 2) % seg) + seg) % seg) - seg / 2;
  const r = a / Math.cos(phi);
  const cap = a * 1.045; // round the corners off
  return r > cap ? cap + (r - cap) * 0.25 : r;
};
/** Polar rounded box (the shaft's cross-section) with half sizes hx (x) and hz (z). */
const box = (th: number, hx: number, hz: number) => 1 / ((Math.abs(Math.cos(th)) / hx) ** 3 + (Math.abs(Math.sin(th)) / hz) ** 3) ** (1 / 3);

/** A surface of revolution-like mesh around Y: radius(theta, y) over rows of y. */
function lathe(ys: number[], radius: (th: number, y: number) => number, R = 128, capBottom = false) {
  const pos: number[] = [], idx: number[] = [];
  ys.forEach((y) => {
    for (let r = 0; r <= R; r++) {
      const th = (2 * Math.PI * r) / R, rr = radius(th, y);
      pos.push(rr * Math.cos(th), y, rr * Math.sin(th));
    }
  });
  for (let i = 0; i < ys.length - 1; i++)
    for (let r = 0; r < R; r++) {
      const a = i * (R + 1) + r, b = a + 1, c = a + R + 1, d = c + 1;
      idx.push(a, c, b, b, c, d);
    }
  if (capBottom) {
    const centre = pos.length / 3;
    pos.push(0, ys[0], 0);
    for (let r = 0; r < R; r++) idx.push(centre, r, r + 1);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setIndex(idx);
  g.computeVertexNormals();
  return g;
}
const rows = (a: number, b: number, n: number) => Array.from({ length: n + 1 }, (_, i) => a + ((b - a) * i) / n);

export function buildHandle() {
  const [g0, g1] = D.grip, A = D.gripApothem;
  const PITCH = 0.027; // one turn of overgrip
  // overgrip: octagon with the spiral overlap ridge, a slight flare at the butt
  const grip = lathe(rows(g0, g1 - 0.010, 520), (th, y) => {
    const s = (((y - g0) / PITCH - th / (2 * Math.PI)) % 1 + 1) % 1;
    const ridge = 0.00055 * smoothstep(0, 0.06, s) * (1 - 0.7 * s);
    const flare = 0.0012 * Math.exp(-(y - g0) / 0.012);
    const taper = smoothstep(g1 - 0.02, g1 - 0.01, y) * -0.0003;
    return octagon(th, A + flare + taper) + ridge;
  }, 192);
  // finishing tape at the top of the grip
  const tape = lathe(rows(g1 - 0.011, g1, 6), (th, y) => octagon(th, A + 0.0004) * (1 - 0.04 * smoothstep(g1 - 0.003, g1, y)), 128);
  // collar: octagon to the shaft's section
  const collar = lathe(rows(g1 - 0.001, g1 + 0.016, 24), (th, y) => {
    const t = smoothstep(g1, g1 + 0.016, y);
    return (1 - t) * octagon(th, A + 0.0006) + t * (box(th, 0.0101, 0.0124) + 0.0004);
  }, 128);
  // butt cap with a chamfered edge, closed underneath
  const cap = lathe([0, 0.0012, 0.003, 0.0105, g0 + 0.0005], (th, y) => octagon(th, A + 0.0019) * (y < 0.003 ? 0.9 + 0.1 * (y / 0.003) : 1), 128, true);
  return { grip, tape, collar, cap };
}

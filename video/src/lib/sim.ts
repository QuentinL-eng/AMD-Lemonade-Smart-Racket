// The app's what-if physics, so every example number on screen is what the simulator would really return.
// Mirrors ShotSimulator.simulate (apple/RacketKit) and ml/coach_sim.py.
const bounded = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

export type SimInput = { swingKmh: number; pathDeg: number; faceDeg: number; contactXcm: number; contactYcm: number; incomingKmh: number };
export type SimDeltas = { swingPercent?: number; pathDeg?: number; faceDeg?: number; contactXcm?: number; contactYcm?: number };

export const simulate = (p: SimInput) => {
  const swing = bounded(p.swingKmh, 0, 200);
  const distance = Math.hypot(bounded(p.contactXcm, -12, 12), bounded(p.contactYcm, -14, 14));
  const e = 0.42 * Math.max(0.55, 1 - 0.035 * distance);
  const brush = (swing / 3.6) * Math.sin(((bounded(p.pathDeg, -80, 80) - bounded(p.faceDeg, -60, 60)) * Math.PI) / 180);
  const spinRpm = ((0.7 * Math.abs(brush)) / 0.0335) * (60 / (2 * Math.PI));
  return {
    ballKmh: e * bounded(p.incomingKmh, 0, 200) + (1 + e) * swing,
    spinRpm,
    spinType: spinRpm < 600 ? 'flat' : brush > 0 ? 'topspin' : 'slice',
    sweetSpot: distance <= 4,
  };
};

export const applyDeltas = (p: SimInput, d: SimDeltas): SimInput => ({
  ...p,
  swingKmh: p.swingKmh * (1 + (d.swingPercent ?? 0) / 100),
  pathDeg: p.pathDeg + (d.pathDeg ?? 0),
  faceDeg: p.faceDeg + (d.faceDeg ?? 0),
  contactXcm: p.contactXcm + (d.contactXcm ?? 0),
  contactYcm: p.contactYcm + (d.contactYcm ?? 0),
});

export const toMph = (kmh: number) => kmh * 0.621371;

// The swing film's fixed look (docs/SWING_FILM.md). Muse never sets anything in this file: the script
// (config/swingFilm.json) only carries the change, three short texts and the simulator's numbers.
import type { V3 } from '../hype/kit';

export const FILM = {
  fps: 30,
  frames: 240, // 8 s
  yours: [0, 90] as const, // "Your swing"
  tryThis: [90, 180] as const, // "Try this", with your swing as a ghost
  card: [180, 240] as const, // before/after numbers
  contactAt: 48, // frame of contact inside each swing half
  slowMo: 0.16, // real seconds per film second, the same in both halves
} as const;

export const CAMERA = { pos: [-5.2, 4.6, 9.4] as V3, target: [0.9, -0.3, -1.2] as V3, fov: 36 };

// Scene units: the Racket component is 3 units for 0.685 m.
export const M = 3 / 0.685;
export const CM = M / 100;

/** The swing template: a fixed pivot (the arm) and a racket that turns about it. Only the five racket numbers
 *  (speed, path, face, contact across/along) change between films. */
export const SWING = {
  pivotToHeadM: 1.1, // shoulder to string-bed centre at contact
  headOffset: 0.76, // racket origin to string-bed centre, scene units
  maxTurn: 2.0, // radians either side of contact (backswing / follow-through)
  incomingKmh: 43.2, // ShotSimulator's groundstroke assumption
  ballR: 0.0335 * M,
  ballShowS: 0.11, // real seconds the ball stays on screen after contact (no flight is modelled)
} as const;

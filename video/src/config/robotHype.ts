// The robot-arm X clip (~27 s): real footage from the 2026-10-29 arm session cut against
// CGI from the real CAD. Every word, clip and beat position lives here.
// Post caption: "Ever wondered how an AI powered tennis racket is trained?" The clip answers it.
// Clips are files in public/footage/, made by scripts/cut-footage.mjs (rh-*).
import type { Cue } from './sound.ts';

export const robotHype = {
  // "Ten" (Anno Domini Beats), 126.0 BPM. The tempo and the drop were measured from the
  // drums (analyze-song.mjs reads this track as 125.3, which drifts off by the drop):
  // the 808 comes in at 38.095 s, after a bar with no bass. We start three bars earlier.
  song: { src: 'audio/ten.mp3', bpm: 126.017, start: 32.381, volume: 0.8 }, // the track is mastered to 0 dBFS: leave room for the hits
  beats: 56, // 14 bars ≈ 26.7 s

  // 1. One phrase per two beats over real cuts.
  hook: {
    at: [0, 8],
    shots: [
      { clip: 'rh-epson', word: 'WE PUT' },
      { clip: 'rh-rim', word: 'OUR AI RACKET' },
      { clip: 'rh-swingin', word: 'ON A' },
      { clip: 'rh-arm', word: 'ROBOT ARM.', accent: true },
    ],
  },

  // 2. The bar with no bass: the real arm, a whip-pan cut to its CGI twin (same side of the
  //    racket, the real room still moving behind it), a scan pass, then a swing through
  //    contact exactly on the drop (beat 12).
  twin: { at: [8, 14], clip: 'rh-reveal', whip: 10, scan: [10.25, 11.25], contact: 12, real: '●  REAL', cgiLabel: '◆  CGI  ·  BUILT FROM OUR CAD', cgi: 'DIGITAL TWIN.', tags: ['EPSON C8', '6 AXES', 'SMART HANDLE'] },

  // 3. What the racket measures: one real cut per beat.
  measures: {
    at: [14, 24],
    shots: [
      { clip: 'rh-strings', tag: 'FACE ANGLE' },
      { clip: 'rh-throat', tag: 'SWING PATH' },
      { clip: 'rh-face', tag: 'CONTACT POINT' },
      { clip: 'rh-over', tag: 'SWING SPEED' },
      { clip: 'rh-pod', tag: 'SPIN' },
      { clip: 'rh-low', tag: 'SHOT TYPE' },
      { clip: 'rh-pan', tag: 'IMPACT' },
      { clip: 'rh-past', tag: 'ALL OF IT.', beats: 3 },
    ],
  },

  // 4. Push into the real handle; match cut to the CGI handle in the same spot; it opens.
  handle: { at: [24, 30], clip: 'rh-handle', cut: 26, big: '1,000', line: 'READINGS A SECOND', sub: 'from the sensor inside the handle' },

  // 5. Real arm (portrait) beside its CGI twin, which swings on the peaks of the racket's own gyro trace.
  truth: { at: [30, 38], clip: 'rh-panel', lines: ['THE ROBOT SWINGS.', 'THE RACKET RECORDS.', 'EVERY SWING LABELLED.', 'THE AI LEARNS.'], trace: 'GYRO  ·  RAD/S  ·  REAL RECORDING' },

  // 6. Wall of test clips, then the line.
  matrix: { at: [38, 46], tiles: ['rh-t1', 'rh-t2', 'rh-t3', 'rh-t4', 'rh-t5', 'rh-t6', 'rh-t7', 'rh-t8', 'rh-t9'], line: ['ZERO', 'GUESSWORK.'], lineAt: 42 },

  // 7. Down the throat at the arm, match cut to the CGI racket, then the name.
  finale: { at: [46, 56], clip: 'rh-pov', pov: ['TRAINED BY', 'A ROBOT.'], cut: 50, name: 'TENNIS BUDDEE', line: 'The racket that learns your game.', cta: 'Coming soon' },
};

/** Sound effects on beats (converted to frames in RobotHype.tsx). */
export const robotHypeCues: (Omit<Cue, 'at'> & { beat: number })[] = [
  { sfx: 'whoosh', beat: 2, volume: 0.4 },
  { sfx: 'impact', beat: 6, volume: 0.8 },
  { sfx: 'servo', beat: 9.5, volume: 0.55 },
  { sfx: 'riser', beat: 12, volume: 0.45 },
  { sfx: 'impact', beat: 12, volume: 1 },
  { sfx: 'whoosh', beat: 14, volume: 0.3 },
  ...[15, 16, 17, 18, 19, 20, 21].map((beat) => ({ sfx: 'tap' as const, beat, volume: 0.7 })),
  { sfx: 'impact', beat: 22, volume: 0.8 },
  { sfx: 'whoosh', beat: 26, volume: 0.3 },
  { sfx: 'boom', beat: 26, volume: 0.4 },
  { sfx: 'swipe', beat: 30, volume: 0.5 },
  ...[32, 34, 36].map((beat) => ({ sfx: 'blip' as const, beat, volume: 0.4 })),
  ...[0, 1, 2, 3, 4, 5, 6, 7, 8].map((i) => ({ sfx: 'blip' as const, beat: 38 + i * 0.4375, volume: 0.22 })),
  { sfx: 'impact', beat: 42, volume: 0.9 },
  { sfx: 'whoosh', beat: 50, volume: 0.3 },
  { sfx: 'boom', beat: 50, volume: 0.45 },
];

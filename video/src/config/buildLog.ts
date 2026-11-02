// BuildLog (~26 s X clip): how the racket was built, as a numbered how-to. Real footage from the
// bench (Oct 26-28), the robot session (Oct 29), the indoor session (Oct 28) and the court
// (Oct 17), with CGI where the CAD takes over. Clips are files in public/footage/, made by scripts/cut-footage.mjs (bt-*, rh-*).
// Suggested post: "We built an AI tennis racket from scratch. Here's the build log."
import type { Cue } from './sound.ts';

export const buildLog = {
  // "Comin Wit It" (Anno Domini Beats), 130.67 BPM, flat-out from bar one. scripts/prep-songs.mjs
  // cuts bars from 18.52 s and muffles the first two, so the full mix drops on beat 8.
  song: { src: 'audio/comin-wit-it.wav', bpm: 130.67, volume: 0.8 },
  beats: 56, // 14 bars ≈ 25.7 s

  // 1. Muffled intro: the title over the bench.
  intro: { at: [0, 8], shots: [{ clip: 'bt-smoke', at: [0, 4] }, { clip: 'bt-bench', at: [4, 8] }], kicker: 'BUILD LOG', title: ['HOW TO BUILD', 'AN AI TENNIS RACKET'] },

  // 2. The steps. Every step: a counter top left, its title slammed bottom left.
  steps: [
    { at: [8, 12], title: 'SOLDER THE BRAIN.', shots: [{ clip: 'bt-solder', beats: 2 }, { clip: 'bt-solder2', beats: 2 }] },
    // real board into the printed pod, push into the pod's end, open up inside the CAD handle
    { at: [12, 18], title: 'BUILD THE HANDLE.', pcb: 'bt-pcb', pod: 'bt-pod', push: 14, cut: 15.5, podOrigin: '76% 52%', tags: ['MOTION SENSOR', 'MICROPHONE', 'PROCESSOR'] },
    { at: [18, 22], title: 'WRITE THE CODE.', shots: [{ clip: 'bt-code', beats: 2 }, { clip: 'bt-code2', beats: 2 }] },
    // push into the CAD of the rig on the monitor, into the CGI arm, whip to the real one
    { at: [22, 28], title: 'PUT IT ON A ROBOT.', cad: 'bt-cad', monitor: '72% 44%', cut: 24.5, whip: 26, real: 'rh-arm' },
    { at: [28, 36], title: 'SWING. RECORD. REPEAT.', words: ['SWING.', 'RECORD.', 'REPEAT.'], shots: ['bt-wired', 'rh-over', 'bt-room', 'rh-swingin', 'bt-wired2', 'rh-pan', 'bt-room2', 'rh-face'] },
    // four indoor hits, one per beat, then the hero shot at the gate
    { at: [36, 44], title: 'TAKE IT TO COURT.', hits: ['bt-in1', 'bt-in2', 'bt-in3', 'bt-in4'], gate: 'bt-gate' },
  ],

  // 3. The gate shot carries on: push in on the racket he's holding up, cut to the CGI racket
  //    (head up, like his), then the name.
  finale: { at: [44, 56], clip: 'bt-gate2', racket: '47% 32%', cut: 47, name: 'TENNIS BUDDEE', line: 'Built from scratch.', cta: 'Coming soon' },
} as const;

/** Sound effects on beats. */
export const buildLogCues: (Omit<Cue, 'at'> & { beat: number })[] = [
  { sfx: 'riser', beat: 8, volume: 0.45 },
  { sfx: 'impact', beat: 8, volume: 1 },
  { sfx: 'boom', beat: 8, volume: 0.4 },
  { sfx: 'swipe', beat: 12, volume: 0.5 },
  { sfx: 'whoosh', beat: 15.5, volume: 0.3 },
  ...[16, 16.5, 17].map((beat) => ({ sfx: 'blip' as const, beat, volume: 0.3 })),
  { sfx: 'swipe', beat: 18, volume: 0.5 },
  { sfx: 'whoosh', beat: 24.5, volume: 0.3 },
  { sfx: 'servo', beat: 25, volume: 0.5 },
  { sfx: 'whoosh', beat: 26, volume: 0.3 },
  ...[28, 29, 30, 31, 32, 33, 34, 35].map((beat) => ({ sfx: 'tap' as const, beat, volume: 0.6 })),
  ...[36, 37, 38, 39].map((beat) => ({ sfx: 'impact' as const, beat, volume: 0.55 })),
  { sfx: 'whoosh', beat: 40, volume: 0.25 },
  { sfx: 'whoosh', beat: 47, volume: 0.3 },
  { sfx: 'boom', beat: 47, volume: 0.45 },
];

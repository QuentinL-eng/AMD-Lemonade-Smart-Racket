// EverySwing (~29 s X clip): the racket on court. Real play, mostly from the indoor session
// (Oct 28) with a few Oct 17 outdoor shots, under a viewfinder HUD; a CGI swing that shows the
// contact point; the app on the phone; then the name. Tagline: "Be better." Clips are files in
// public/footage/ (ev-*), made by scripts/cut-footage.mjs.
// Suggested post: "Every swing, measured. Be better."
import type { Cue } from './sound.ts';

export const everySwing = {
  // "Not My First Rodeo" (Dyalla), 92 BPM. The section from 9.14 s: two quiet beats, the drums
  // come in on beat 3 and the full groove lands on beat 4 (11.75 s in the song).
  song: { src: 'audio/not-my-first-rodeo.wav', bpm: 92, volume: 0.8 },
  beats: 44, // ≈ 28.7 s

  // 1. Serve in silhouette: toss, trophy, contact on the drop.
  hook: { at: [0, 6], shots: [{ clip: 'ev-toss', at: [0, 2], word: 'WHAT IF YOUR RACKET' }, { clip: 'ev-toss2', at: [2, 4], word: 'COULD SEE' }, { clip: 'ev-serve', at: [4, 6], word: 'EVERYTHING.', accent: true }] },

  // 2. One real shot per beat under the HUD, each tagged with what the racket measures; the last
  //    is the whole indoor hall playing.
  montage: {
    at: [6, 14],
    shots: [
      { clip: 'ev-1', tag: 'FACE ANGLE' },
      { clip: 'ev-2', tag: 'SWING PATH' },
      { clip: 'ev-3', tag: 'SWING SPEED' },
      { clip: 'ev-4', tag: 'CONTACT POINT' },
      { clip: 'ev-5', tag: 'SPIN' },
      { clip: 'ev-6', tag: 'SHOT TYPE' },
      { clip: 'ev-7', tag: 'IMPACT' },
      { clip: 'ev-8', tag: 'EVERY SHOT.' },
    ],
  },

  // 3. CGI: the racket swings through two balls over the court; the contact point lights up.
  feel: { at: [14, 20], plate: 'ev-plate-court', contacts: [16, 18], lines: ['IT FEELS', 'EVERY HIT.'], label: 'CONTACT POINT' },

  // 4. The app: the session on the phone, racket in the other hand.
  phone: { at: [20, 26], shots: [{ clip: 'ev-phone', at: [20, 24] }, { clip: 'ev-check', at: [24, 26] }], lines: ['EVERY SESSION.', 'IN YOUR POCKET.'] },

  // 5. Serve against the sky, then four quick indoor hits.
  train: { at: [26, 34], sky: 'ev-sky2', line: 'KNOW YOUR GAME.', hits: ['ev-9', 'ev-10', 'ev-11', 'ev-12'], words: ['TRAIN.', 'TRACK.', 'IMPROVE.'] },

  // 6. The racket at the net, cut to CGI, the name and the tagline.
  finale: { at: [34, 44], clip: 'ev-net', cut: 36, name: 'TENNIS BUDDEE', tagline: 'BE BETTER.', cta: 'Coming soon' },
} as const;

/** Sound effects on beats. */
export const everySwingCues: (Omit<Cue, 'at'> & { beat: number })[] = [
  { sfx: 'riser', beat: 4, volume: 0.45 },
  { sfx: 'impact', beat: 4, volume: 1 },
  { sfx: 'boom', beat: 4, volume: 0.35 },
  ...[7, 8, 9, 10, 11, 12].map((beat) => ({ sfx: 'tap' as const, beat, volume: 0.6 })),
  { sfx: 'impact', beat: 13, volume: 0.7 },
  { sfx: 'whoosh', beat: 14, volume: 0.3 },
  { sfx: 'impact', beat: 16, volume: 0.8 },
  { sfx: 'impact', beat: 18, volume: 0.8 },
  { sfx: 'swipe', beat: 20, volume: 0.5 },
  { sfx: 'blip', beat: 22, volume: 0.35 },
  { sfx: 'whoosh', beat: 26, volume: 0.3 },
  ...[30, 31, 32, 33].map((beat) => ({ sfx: 'impact' as const, beat, volume: 0.5 })),
  { sfx: 'whoosh', beat: 36, volume: 0.3 },
  { sfx: 'boom', beat: 36, volume: 0.45 },
];

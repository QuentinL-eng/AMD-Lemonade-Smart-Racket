// Possessed (~27 s X clip, for Halloween): "this racket is possessed... by an AI". Found-footage
// intro at the net, glitch cuts over the indoor session (played in costume), an X-ray into the CAD
// handle, the robot that trained it, the name. Clips are files in public/footage/ (hw-*), made by scripts/cut-footage.mjs.
// Suggested post: "Happy Halloween 🎃 Our racket is possessed (by AI)."
import type { Cue } from './sound.ts';

export const possessed = {
  // "Whoop" (Anno Domini Beats), 105.3 BPM. scripts/prep-songs.mjs cuts from 55.07 s (the
  // sparse bars) and muffles the first two, so the full mix drops on beat 8.
  song: { src: 'audio/whoop.wav', bpm: 105.335, volume: 0.8 },
  beats: 48, // ≈ 27.3 s

  // 1. Found footage: creeping up on the racket at the net, music behind the wall.
  intro: { at: [0, 8], shots: [{ clip: 'hw-net', at: [0, 4] }, { clip: 'hw-creep', at: [4, 8] }], lines: [{ at: 1, text: 'THIS RACKET' }, { at: 5, text: 'IS POSSESSED.' }], rec: 'CAM 02  ·  OCT 31' },
  // 2. The drop.
  drop: { at: [8, 10], clip: 'hw-grip', text: '...BY AN AI.' },
  // 3. It watches every swing: a lock-on reticle per shot.
  watch: { at: [10, 16], shots: [{ clip: 'hw-sw1', word: 'IT WATCHES' }, { clip: 'hw-sw2', word: 'EVERY' }, { clip: 'hw-sw3', word: 'SWING.' }] },
  // 4. Push into the grip, X-ray into the CAD handle.
  inside: { at: [16, 24], clip: 'hw-xray', origin: '78% 35%', cut: 18, plate: 'hw-plate-net', lines: ['IT LIVES', 'IN THE HANDLE.'], tags: ['MOTION SENSOR', 'MICROPHONE', 'PROCESSOR'] },
  // 5. Where it learned: the robot.
  trained: { at: [24, 32], clips: ['hw-robot1', 'hw-robot2', 'hw-robot3', 'hw-robot4'], lines: [{ at: 24, text: 'IT WAS TRAINED' }, { at: 28, text: 'BY A ROBOT.' }] },
  // 6. What it wants: the costumed line-up watching, then a player lunging for one.
  wants: { at: [32, 40], shots: [{ clip: 'hw-lineup', at: [32, 36], word: 'NOW IT WANTS' }, { clip: 'hw-lunge', at: [36, 40], word: 'YOUR GAME.' }] },
  // 7. A ball rolls across the empty court; the racket rises; the name.
  finale: { at: [40, 48], clip: 'hw-ball', cut: 42, name: 'TENNIS BUDDEE', line: 'Happy Halloween.', cta: 'Coming soon' },
} as const;

/** Sound effects on beats. */
export const possessedCues: (Omit<Cue, 'at'> & { beat: number })[] = [
  { sfx: 'riser', beat: 8, volume: 0.5 },
  { sfx: 'impact', beat: 8, volume: 1 },
  { sfx: 'boom', beat: 8, volume: 0.45 },
  ...[10, 12, 14].map((beat) => ({ sfx: 'whoosh' as const, beat, volume: 0.25 })),
  { sfx: 'boom', beat: 18, volume: 0.35 },
  ...[20.5, 21, 21.5].map((beat) => ({ sfx: 'blip' as const, beat, volume: 0.3 })),
  ...[24, 26, 28, 30].map((beat) => ({ sfx: 'servo' as const, beat, volume: 0.45 })),
  { sfx: 'whoosh', beat: 32, volume: 0.3 },
  { sfx: 'impact', beat: 36, volume: 0.7 },
  { sfx: 'whoosh', beat: 42, volume: 0.3 },
  { sfx: 'boom', beat: 42, volume: 0.5 },
];

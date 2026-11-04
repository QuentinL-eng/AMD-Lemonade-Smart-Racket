// The order and length of every beat. Edit these lists to re-cut the videos.
//
// An entry is either:
//   { scene: '<id>', seconds }                  CGI scene from src/scenes
//   { footage: '<id>', seconds, ... }           real footage slot
//
// Footage: save the clip as public/footage/<id>.mp4 and it is used automatically. Until then the slot plays, in
// order: `clips` (short cuts already in public/footage), `fallback` (a CGI scene), or a placeholder with the shot notes.
// `from` trims the start of the clip (seconds). `caption` is burned in at the bottom.
// Scenes take `skip` (frames) to start a scene part-way in, e.g. so its key moment lands on a beat.
// Any entry takes `overlays`: text and cards over the picture, drawn by src/components/Overlays.tsx.

import type { SceneId } from '../scenes';
import { music, type Music } from './sound.ts'; // .ts so scripts can import it with plain node
import { voiceover, type VoLine } from './voiceover.ts';

/** `at` and `seconds` are relative to the entry. `text` is a key of copy.overlays. */
export type Overlay =
  | { type: 'headline'; text: 'hook'; at: number; seconds: number }
  | { type: 'shotCard'; at: number; seconds: number }
  | { type: 'badge'; text: 'deviceBadge' | 'filmBadge'; at: number; seconds: number; x?: number; y?: number }
  | { type: 'callouts'; text: 'museCallouts'; at: number; every: number }
  | { type: 'lowerThird'; text: 'testimonial1' | 'testimonial2'; at: number; seconds: number };

export type SceneEntry = {
  scene: SceneId;
  seconds: number;
  skip?: number;
  overlays?: Overlay[];
  /** The scene plays its own song: the cut's music goes silent under it. */
  ownMusic?: boolean;
};
export type FootageEntry = {
  footage: string;
  seconds: number;
  file?: string; // only to use a name other than <footage>.mp4
  from?: number;
  muted?: boolean;
  caption?: string;
  shot: string; // what to film, shown on the placeholder
  /** Plays until the real clip exists: [clip name, seconds, optional playback rate]. */
  clips?: [string, number, number?][];
  /** The clips above are a stand-in, not the final shot: tags the frame and `npm run check` lists it. */
  standIn?: boolean;
  /** CGI scene to show until the real clip exists. */
  fallback?: SceneId;
  /** 'phone': a portrait screen recording in an iPhone frame, ungraded. Default: full frame, graded. */
  layout?: 'full' | 'phone';
  playbackRate?: number;
  overlays?: Overlay[];
};
export type Entry = SceneEntry | FootageEntry;

// Crossfade between beats, in seconds. Set to 0 for hard cuts.
export const transitionSeconds = 0.4;

// Optional: turn on once ShotSimulator returns launch angle/flight.
export const features = { showBallFlight: false };

// ~60 s CGI-only reveal: the X/LinkedIn post and the opening of the demo.
export const reveal: Entry[] = [
  { scene: 'hook', seconds: 3.5 },
  { scene: 'racketReveal', seconds: 6 },
  { scene: 'insideHandle', seconds: 9 },
  { scene: 'impact', seconds: 6.5 },
  { scene: 'robotLab', seconds: 8 },
  { scene: 'devices', seconds: 7 },
  { scene: 'score', seconds: 5.5 },
  { scene: 'whatIf', seconds: 11 },
  { scene: 'together', seconds: 5.5 },
  { scene: 'endcard', seconds: 5 },
];

// The 3:00 hackathon submission (script: video/DEMO_SCRIPT.md). Spoken lines live in voiceover.ts and follow their
// entry, so you can reorder this list freely. `npm run timeline` prints the cut; `npm run check` tells you what's left.
export const demoTransition = 0.25;
// The song fades out at about 2:05. Jump back from bar 49 to bar 9, where it's just as full, on a bar line.
const songBar = (n: number) => 0.386 + ((n - 1) * 4 * 60) / 95;
const demoMusic: Music = { ...music, jump: { at: songBar(49), to: songBar(9) } };
export const demo: Entry[] = [
  { footage: 'cold-open', seconds: 8, standIn: true, clips: [['ev-toss', 3.2, 0.5], ['ev-serve', 4.8, 0.3]],
    overlays: [{ type: 'headline', text: 'hook', at: 0.4, seconds: 3.6 }, { type: 'shotCard', at: 4.6, seconds: 3.4 }],
    shot: 'Your serve at the court: toss, then contact. Film 240 fps slow-mo from the side. Phone on the Live tab so the card numbers are real.' },
  { scene: 'racketReveal', seconds: 6 },
  { footage: 'talk-intro', seconds: 9, muted: false,
    caption: 'I built a smart racket that combines Meta AI with real data from your own swings, so you can see what a change will do before you make it.',
    shot: 'Bedroom, landscape, racket in hand. One line on the problem, one on what you built. Say what the caption says, in your own words, and change the caption to match.' },
  { scene: 'insideHandle', seconds: 8 },
  { footage: 'build-montage', seconds: 6, clips: [['bt-smoke', 1.2], ['bt-solder', 1], ['bt-pcb', 1], ['bt-pod', 0.7], ['bt-code', 1.1], ['bt-wired', 0.6], ['bt-cad', 0.4]],
    shot: 'Already cut from the build footage. Replace only if you have something better.' },
  // The first 24 beats of the X clip, on its own song. It stops before the claims the Demo doesn't make.
  { scene: 'robotShort', seconds: 11.25, ownMusic: true },
  { scene: 'twoModels', seconds: 8.75 },
  { scene: 'evidence', seconds: 9 },
  { scene: 'devices', seconds: 6, overlays: [{ type: 'badge', text: 'deviceBadge', at: 1.6, seconds: 4.2, x: 1560, y: 300 }] },
  { footage: 'glasses-pov', seconds: 7, fallback: 'glassesPov',
    shot: 'Optional: through the lens of the real Ray-Ban Display. Until then, the simulated-view CGI plays, and says so.' },
  { scene: 'museAgent', seconds: 12 },
  // The real app carries the what-if here, so the CGI whatIf scene is out of this cut.
  { footage: 'muse-screen-recording', seconds: 32, layout: 'phone',
    overlays: [{ type: 'callouts', text: 'museCallouts', at: 1, every: 7.5 }],
    shot: 'iPhone screen recording, about a minute, slowly: Muse tab, What if, ask it, wait for the numbers. Then Next drill, then Start on Watch. Set playbackRate to speed it up and move the callouts to match.' },
  { footage: 'drill-on-watch', seconds: 7.5,
    shot: 'Close on the Watch: the to-go count drops as you hit. Finish on the phone Live tab saying Drill complete!' },
  { scene: 'samTrack', seconds: 6.75 },
  { scene: 'swingFilm', seconds: 7, overlays: [{ type: 'badge', text: 'filmBadge', at: 0.3, seconds: 6.5, x: 960, y: 40 }] },
  // Made by scripts/testimonials.py, which cleans the audio. The files are full length: pick each line with `from` and `seconds`.
  { footage: 'testimonial-1', seconds: 12, from: 15, muted: false, overlays: [{ type: 'lowerThird', text: 'testimonial1', at: 0.4, seconds: 4 }],
    shot: 'npm run testimonials' },
  { footage: 'testimonial-2', seconds: 12, from: 1.5, muted: false, overlays: [{ type: 'lowerThird', text: 'testimonial2', at: 0.4, seconds: 4 }],
    shot: 'npm run testimonials' },
  { footage: 'simulator', seconds: 10,
    shot: 'Screen record tennisbuddy.net/emulator in landscape: pick a match, Start Session on Live, let a few hits land, then open Muse and What if.' },
  { scene: 'endcard', seconds: 6 },
];

// ---------------------------------------------------------------------------
// Cut to "Keep It Movin'" (Jahdean): 95 BPM, first downbeat 0.386 s, bar = 2.526 s.
// Found with scripts/analyze-song.mjs. Every scene is a whole number of bars and
// cuts hard on the downbeat; the song fills out at bar 9, where the ball impact lands.
export const song: Music & { bpm: number } = { src: 'audio/keep-it-movin.mp3', from: 0.386, bpm: 95, volume: 0.7 };
const bars = (n: number) => (n * 4 * 60) / song.bpm;

export const revealSong: Entry[] = [
  { scene: 'hook', seconds: bars(2) }, // bars 1-2, riser peaks on the cut
  { scene: 'racketReveal', seconds: bars(3), skip: 24 }, // title + boom on bar 4's downbeat
  { scene: 'insideHandle', seconds: bars(3) },
  { scene: 'impact', seconds: bars(3), skip: 3 }, // starts on the lift (bar 9); ball hits on beat 4
  { scene: 'robotLab', seconds: bars(3) }, // racket meets the ball on beats
  { scene: 'devices', seconds: bars(3) },
  { scene: 'score', seconds: bars(2) },
  { scene: 'whatIf', seconds: bars(4) },
  { scene: 'together', seconds: bars(2) },
  { scene: 'endcard', seconds: bars(2), skip: 4 }, // logo pop + boom on the downbeat
];

/** Every cut: its entries, crossfade length and music. Root.tsx makes one composition each. */
export type Cut = { entries: Entry[]; transition: number; music: Music; voiceover?: VoLine[] };
export const cuts: Record<'Reveal' | 'RevealSong' | 'Demo', Cut> = {
  Reveal: { entries: reveal, transition: transitionSeconds, music },
  RevealSong: { entries: revealSong, transition: 0, music: song },
  Demo: { entries: demo, transition: demoTransition, music: demoMusic, voiceover },
};

// Every spoken line in the Demo, and its burned-in caption. Rewrite a line here and the caption follows.
//
// - `at`: the entry in timeline.ts it starts on (a scene id or footage id), so a line moves with its shot.
// - `lead`: seconds after that entry starts. Default 0.3.
// - Record a line: save it as public/audio/vo/<id>.wav (or .mp3, .m4a). It plays on its own and the music ducks.
// - `seconds`: how long the line runs, for captions and ducking. Default: from the word count.
//   `npm run check` warns when a line would run into the next one.
//
// Say "smart racket" and "predicts". The hackathon's anti-project list bans the other words (see ../../README.md).

export type VoLine = { id: string; at: string; lead?: number; seconds?: number; text: string };

/** Comfortable reading pace, words per second. */
export const WORDS_PER_SECOND = 2.6;
export const voSeconds = (l: VoLine) => l.seconds ?? l.text.split(/\s+/).length / WORDS_PER_SECOND;

export const voiceover: VoLine[] = [
  { id: 'open', at: 'cold-open', lead: 0.6, text: 'Hundreds of hits per match, but which ones are good, and where can you improve?' },
  { id: 'reveal', at: 'racketReveal', lead: 1.2, text: 'This is Tennis Buddee: a smart racket that feels every shot.' },
  // talk-intro is you on camera, and robotShort plays on its own song: no line on either.
  { id: 'hardware', at: 'insideHandle', text: 'A sensor insert replaces the foam in the handle: a thousand samples a second, up to 320 g, and a microphone that hears where the ball met the strings. It computes every shot itself.' },
  // The on-racket model is ridge regression (firmware/src/sweetspot.cpp). Don't call it a neural net until one ships.
  { id: 'models', at: 'twoModels', text: 'On the racket, our own ML model runs on the ESP32. In the app, Meta\'s open Muse Spark, served by Baseten.' },
  { id: 'evidence', at: 'evidence', text: 'The firmware matches Python on every clip, distance error stays under two centimeters, and Muse passes a strict test 88 percent of the time.' },
  { id: 'everywhere', at: 'devices', lead: 0.8, text: 'Every shot lands on your phone, your Apple Watch, and Meta Ray-Ban Display, through the Meta Wearables toolkit, in a UI you can read at a glance.' },
  { id: 'agent', at: 'museAgent', text: 'Muse Spark isn\'t a chat box here. It\'s an agent with ten tools, over your shots and the live racket. Every number it reports has to come from a tool.' },
  { id: 'whatif', at: 'muse-screen-recording', text: 'Ask what if, and it runs a physics simulation on your own average stroke, and predicts what the change does to speed and spin.' },
  { id: 'drill', at: 'muse-screen-recording', lead: 25.5, text: 'Then it plans a drill, and then your wearable tracks it.' },
  { id: 'sam', at: 'samTrack', text: 'SAM 3.1 tracks the racket through real video, frame by frame, and pre-fills the contact labels.' },
  { id: 'film', at: 'swingFilm', text: 'And Muse directs this swing film from the simulator\'s numbers, so it can\'t invent a swing.' },
  { id: 'end', at: 'endcard', lead: 0.8, text: 'Try our online simulator, and feel like a tennis pro.' },
];

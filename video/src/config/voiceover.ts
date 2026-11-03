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
  { id: 'open', at: 'cold-open', lead: 0.6, text: 'Every player hits hundreds of balls a night. Nobody knows which ones were good.' },
  { id: 'reveal', at: 'racketReveal', lead: 1.2, text: 'This is Tennis Buddee: a smart racket that feels every shot.' },
  // talk-intro is you on camera: no line here.
  { id: 'hardware', at: 'insideHandle', text: 'A sensor insert replaces the foam in the handle: a thousand samples a second, up to 320 g, and a microphone that hears where the ball met the strings.' },
  { id: 'club', at: 'clubFinding', text: 'On a real court, only seventeen percent of the raw stream reached the phone. So now the racket computes every shot itself, and keeps what it can\'t send.' },
  { id: 'robot', at: 'robot-arm', lead: 1.4, text: 'We put it on a real robot arm, and known motion helped catch a gyro reading twice too high.' },
  { id: 'evidence', at: 'evidence', text: 'We publish the weak numbers too. Distance error is under two centimeters. The yes-or-no call isn\'t clear of its baseline yet.' },
  { id: 'everywhere', at: 'devices', text: 'Every shot lands on your phone, your Apple Watch, and Meta Ray-Ban Display, through the Meta Wearables toolkit.' },
  { id: 'agent', at: 'museAgent', text: 'Muse Spark isn\'t a chat box here. It\'s an agent with ten tools, over your shots and the live racket. Every number it reports has to come from a tool.' },
  { id: 'whatif', at: 'whatIf', text: 'Ask what if, and it runs a physics simulator on your own average stroke, and predicts what the change does to speed and spin.' },
  { id: 'drill', at: 'muse-screen-recording', lead: 12, text: 'Then it plans a drill, and the Watch and the glasses track it. If the network fails, a built-in engine answers, and the app says so.' },
  { id: 'sam', at: 'samTrack', text: 'SAM 3.1 tracks the racket through real video, frame by frame, and pre-fills the contact labels.' },
  { id: 'film', at: 'swingFilm', text: 'And Muse directs this swing film from the simulator\'s numbers, so it can\'t invent a swing.' },
  { id: 'built', at: 'builtProof', text: 'Every commit is public, and the tests are there to run. Try it on TestFlight in two minutes. No racket needed.' },
];

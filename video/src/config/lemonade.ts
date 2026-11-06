// The Lemonade Developer Challenge cut: every word and number on screen. Built in src/hype/LemonadeCut.tsx.
// Judged on community impact, technical depth and creativity, with bonus points for a recorded demo. Story: the racket
// measures, the simulator does the maths, Lemonade runs the model on hardware the player owns.
// Pre-submit checks for what's on screen: ../../LEMONADE_CUT.md. Numbers come from docs/ and evaluation/.
export const LEMON = '#FFE14A';

export const lemonade = {
  // "Comin Wit It" from its first bass note. The bass runs alone for six bars and the full beat lands on bar 7.
  song: { src: 'audio/comin-wit-it-full.mp3', bpm: 130.65, firstNote: 1.971, volume: 0.8, under: 0.2 },
  bars: 64,

  captions: {
    open: 'There are hundreds of hits per match, but which ones are good, and where can you improve?',
    reveal: 'This is Tennis Buddee, a smart racket that feels every shot.',
    talk: [
      { to: 4.9, text: "I'm Quentin Lynch, and I built Tennis Buddee, the smartest racket that you will ever use." },
      { to: 8.8, text: 'Tennis Buddee can hear and feel every shot you take.' },
    ],
    hardware: [
      { to: 2.4, text: 'A sensor insert replaces the foam in the handle.' },
      { to: 5.1, text: 'A thousand samples a second, up to 320 g,' },
      { to: 8.7, text: 'and a microphone that hears where the ball hit the strings, not just when.' },
      { to: 12.6, text: 'It computes every single shot itself on the racket.' },
    ],
    esp32: 'On the racket, my own machine learning model runs on the ESP32.',
    whatif: 'It runs a physics simulation on your average stroke, and predicts what the change does to the speed and the spin.',
  },

  question: 'But where should its brain live?',
  reveal: { name: 'Lemonade', sub: 'AMD’s open-source local AI server. On your own machine.' },
  promise: 'A smart racket. A local brain.',
  tags: ['1,000 SAMPLES / SEC', 'UP TO 320 G', 'HEARS WHERE IT HIT'],
  twin: [
    { chip: 'REAL TIME', title: 'The racket has the numbers.' },
    { chip: '1/2 SPEED', title: 'Same swing. Same moment.' },
    { chip: '1/2 SPEED', title: 'A player asks: what if?', accent: true },
  ],

  // Verbatim from the CLI on the machine that made this video. Only the status table's last column (a local path) is dropped.
  terminal: [
    { cmd: 'winget install --id AMD.LemonadeServer --exact', out: [] as string[] },
    { cmd: 'lemonade --version', out: ['lemonade version 2026.45.3'] },
    { cmd: 'lemonade list', out: [
      'Model Name                 Downloaded   Size (GB)   Details',
      'Qwen3-1.7B-GGUF            Yes          0.98        llamacpp',
      'TennisBuddee-R4            Yes          1.53        llamacpp',
    ] },
    { cmd: 'lemonade status', out: [
      'Server is running on port 8000',
      '',
      'Model             Type   Device   Recipe     Ctx    Status',
      'TennisBuddee-R4   llm    gpu      llamacpp   8192   ready',
    ] },
  ],
  terminalTitle: ['One install.', 'Our own model. Loaded.'],

  engine: {
    kicker: 'WHY IT’S INTEGRAL',
    title: 'One local endpoint. Everything talks to it.',
    clients: ['iPhone app', 'Browser demo', '243-case evaluator'],
    endpoint: 'POST /api/v1/chat/completions',
    server: 'Lemonade',
    where: 'on your laptop, on your network',
    model: 'TennisBuddee-R4',
    tools: 'simulate_change',
    toolsNote: 'Physics simulator. Code supplies every number.',
    foot: 'OpenAI-compatible, so swapping engines is a base-URL change.',
  },

  demo: {
    kicker: 'RECORDED ON THE LOCAL SERVER',
    intro: 'The app, running on Lemonade.',
    first: 'It finds your best change.',
    second: 'Then you try it in 3D.',
    chip: 'Lemonade · local server',
    // The app's own numbers in this take.
    stat: '+7% ball speed',
    statNote: 'An estimate, from the physics model',
  },

  // A real question and answer from the Lemonade evaluation run, evaluation/lemonade-tuned-r4-default-sampling.json.
  answer: {
    kicker: 'THE TUNED MODEL, SERVED BY LEMONADE',
    q: 'If I close the face 2° and swing 10% faster on the forehand, what happens?',
    tools: ['get_session_digest', 'simulate_change'],
    a: 'Estimated for your forehand: spin goes from 2,490 rpm to about 2,990 rpm, and ball speed goes from 189 km/h to about 212 km/h. That’s a decisive gain in both spin and pace. It’s an estimate, so check it with 10 forehands next session.',
    rule: 'The model picks the tool. The simulator supplies the number.',
  },

  privacy: { title: 'Your swings stay home.', sub: 'No account. No third-party processor. The server is the one you chose.' },

  loop: {
    kicker: 'THE LOOP LEMONADE MAKES POSSIBLE',
    title: 'Test. Fix. Retrain. Repeat.',
    facts: ['243 test cases', '0 request errors', 'About 6 minutes a run', 'No per-request bill'],
    // Strict all-pass on the same 243 validation cases: docs/LEMONADE_EVAL.md, docs/ADAPTER_EVAL.md.
    bars: [
      { label: 'Stock Qwen3 1.7B on Lemonade', n: 124 },
      { label: 'Our fine-tune, round 1', n: 169 },
      { label: 'Our fine-tune, round 4', n: 212, best: true },
    ],
    of: 243,
    finds: [
      { big: '62 → 0', small: 'errors, after the logs led us to 377 broken training chats' },
      { big: 'Key order', small: 'Lemonade sorts tool-schema keys. We train on that order now, and wrote it up for other fine-tuners' },
      { big: '1.5 GB', small: 'our tuned GGUF, loaded as a Lemonade custom model' },
    ],
    foot: 'Strict all-pass on the same 243 validation cases, same scorer every time.',
  },

  reach: { big: '4 GB', title: 'An old RX 580 runs it too.', sub: 'The Lemonade container loaded a 1.7B model on Vulkan in 1.59 GB of VRAM. A short smoke test, not a benchmark.' },

  people: {
    lead: 'Real players.',
    list: [
      { clip: 'vx-kellam', name: 'Kellam Adams', detail: 'Part-time tennis coach', line: 'It’s super awesome. It helps my play a lot better.' },
      { clip: 'vx-josh', name: 'Josh Do', detail: '', line: 'Tennis Buddee’s got me ten times better.' },
    ],
  },

  open: {
    kicker: 'OPEN SOURCE · MIT',
    title: 'One command. No racket. No account.',
    cmd: 'node tools/judge-demo.mjs',
    items: ['Setup guide for Lemonade', 'grounded-answer.js: reusable “numbers from code” rule', 'The evaluator and every result file'],
    next: 'Next: a tuned 7B model on the same scorer, on Ryzen AI Max+.',
  },

  end: {
    first: 'When life gives you swings,',
    second: 'make Lemonade.',
    name: 'Tennis Buddee',
    tag: 'Built on Lemonade',
    cta: 'Open source. Try it today.',
    url: 'github.com/QuentinL-eng/Tennis-Buddy-Smart-Racket',
  },
};

// Cuts the section each X clip uses out of its song (marketing/Music) into public/audio/*.wav.
// Songs that run flat-out from bar one get a built-in drop: the first `muffle` beats play
// through a low-pass (as if from the next room), the last quarter beat before the drop is
// silent, then the full mix hits on the downbeat.
// Tempo and beat phase were measured from the drums (onset comb + waveform checks); `start`
// is a downbeat, so beat 0 of the clip lands on one.
//
//   FFMPEG=path/to/ffmpeg node scripts/prep-songs.mjs [--src ../marketing/Music]
import { spawnSync } from 'node:child_process';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';

const args = process.argv.slice(2);
const srcAt = args.indexOf('--src');
const SRC = resolve(srcAt >= 0 ? args[srcAt + 1] : '../marketing/Music');
const FFMPEG = process.env.FFMPEG ?? 'ffmpeg';

// out name -> song file, tempo, first beat used (s), beats used, muffled intro beats
export const SONGS = {
  'comin-wit-it': { src: 'Comin Wit It - Anno Domini Beats.mp3', bpm: 130.67, start: 18.524, beats: 56, muffle: 8 }, // BuildLog
  'not-my-first-rodeo': { src: 'Not My First Rodeo - Dyalla.mp3', bpm: 92, start: 9.142, beats: 44, muffle: 0 }, // EverySwing: drums in on beat 3, drop on 4
  whoop: { src: 'Whoop - Anno Domini Beats.mp3', bpm: 105.335, start: 55.066, beats: 48, muffle: 8 }, // Possessed
};

mkdirSync(resolve('public/audio'), { recursive: true });
for (const [name, s] of Object.entries(SONGS)) {
  const beat = 60 / s.bpm;
  const len = s.beats * beat + 1.5; // a little tail for the fade
  const drop = s.muffle * beat;
  const filter = s.muffle
    ? `[0:a]atrim=${s.start}:${s.start + len},asetpts=PTS-STARTPTS,asplit[a][b];` +
      `[a]atrim=0:${drop - beat / 4},lowpass=f=380,lowpass=f=380,volume=1.6,apad=whole_dur=${drop}[intro];` +
      `[b]atrim=${drop},asetpts=PTS-STARTPTS[main];[intro][main]concat=n=2:v=0:a=1[out]`
    : `[0:a]atrim=${s.start}:${s.start + len},asetpts=PTS-STARTPTS[out]`;
  const r = spawnSync(FFMPEG, ['-hide_banner', '-loglevel', 'error', '-y', '-i', resolve(SRC, s.src), '-filter_complex', filter, '-map', '[out]', '-ar', '48000', resolve('public/audio', `${name}.wav`)], { stdio: 'inherit' });
  console.log(`${r.status === 0 ? 'ok  ' : 'FAIL'} ${name}.wav  (${len.toFixed(2)} s${s.muffle ? `, drop at ${drop.toFixed(3)} s` : ''})`);
}

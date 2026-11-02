// Possessed (~27 s X clip, Halloween): "this racket is possessed... by an AI", on "Whoop".
// Timed in beats; copy, clips and beats come from src/config/possessed.ts. Everything gets a
// colder, darker grade than the other cuts; the brand lime does the haunting (glow, reticles,
// the X-ray). Glitch cuts slice the frame into displaced bands for a few frames.
import React from 'react';
import { AbsoluteFill, Audio, Easing, Sequence, interpolate, random, staticFile, useCurrentFrame } from 'remotion';
import { Effect } from '../components/Timeline';
import { colors, fonts } from '../config/brand';
import { possessed as P, possessedCues } from '../config/possessed';
import { Big, Center, Grain, useSlam } from './Hype';
import { Clip, Flash, Plate, SHADOW, Shade, Vignette, beatClock, clamp, makeDuck } from './kit';
import { HandleCGI, PushToBlack, RacketFinale, Tags } from './pieces';

const { BEAT, f, pulse, Shot } = beatClock(P.song.bpm); // ~17.09 frames per beat
export const possessedFrames = f(P.beats);

// Cold and dark: crushed, desaturated, pushed toward teal.
const HAUNT = 'contrast(1.3) saturate(0.4) brightness(0.72) hue-rotate(-14deg)';

/** Glitch: for `len` frames from `at`, the frame splits into bands that jump sideways. */
const Glitch: React.FC<{ at: number; len?: number; children: React.ReactNode }> = ({ at, len = 6, children }) => {
  const frame = useCurrentFrame();
  const on = frame >= at && frame < at + len;
  if (!on) return <>{children}</>;
  const k = 1 - (frame - at) / len;
  const bands = Array.from({ length: 5 }, (_, i) => {
    const y = random(`y${frame}-${i}`) * 1000;
    const h = 20 + random(`h${frame}-${i}`) * 120;
    const dx = (random(`x${frame}-${i}`) - 0.5) * 240 * k;
    return { y, h, dx };
  });
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{ transform: `translateX(${(random(`s${frame}`) - 0.5) * 30 * k}px)` }}>{children}</AbsoluteFill>
      {bands.map((b, i) => (
        <AbsoluteFill key={i} style={{ clipPath: `inset(${b.y}px 0 ${Math.max(0, 1080 - b.y - b.h)}px 0)`, transform: `translateX(${b.dx}px)`, filter: i % 2 ? 'hue-rotate(90deg) saturate(2)' : undefined }}>{children}</AbsoluteFill>
      ))}
      <AbsoluteFill style={{ background: colors.accent, opacity: 0.12 * k, mixBlendMode: 'screen' }} />
    </AbsoluteFill>
  );
};

/** Found-footage overlay: REC, a running clock, scanlines, a green night-vision cast. */
const FoundFootage: React.FC<{ label: string; offset?: number }> = ({ label, offset = 0 }) => {
  const frame = useCurrentFrame() + offset;
  const s = 57 + Math.floor(frame / 30);
  const clock = `23:59:${String(Math.min(59, s)).padStart(2, '0')}`;
  return (
    <AbsoluteFill style={{ pointerEvents: 'none' }}>
      <AbsoluteFill style={{ background: '#5f8f4a', mixBlendMode: 'color', opacity: 0.45 }} />
      <AbsoluteFill style={{ background: 'repeating-linear-gradient(0deg, rgba(0,0,0,0.18) 0 2px, transparent 2px 4px)' }} />
      <div style={{ position: 'absolute', left: 110, top: 96, display: 'flex', alignItems: 'center', gap: 16, fontFamily: fonts.mono, fontSize: 30, color: colors.text }}>
        <div style={{ width: 18, height: 18, borderRadius: 9, background: '#ff3b30', opacity: frame % 20 < 12 ? 1 : 0.15 }} />
        REC
      </div>
      <div style={{ position: 'absolute', right: 110, top: 96, fontFamily: fonts.mono, fontSize: 30, color: colors.text }}>{label}</div>
      <div style={{ position: 'absolute', right: 110, bottom: 96, fontFamily: fonts.mono, fontSize: 30, color: colors.text }}>{clock}</div>
    </AbsoluteFill>
  );
};

/** A line slammed in at local frame `at`, a little shaky, glowing lime when `accent`. */
const Line: React.FC<{ at: number; text: string; accent?: boolean; size?: number }> = ({ at, text, accent, size = 180 }) => {
  const frame = useCurrentFrame();
  const slam = useSlam(at);
  if (frame < at) return null;
  const jitter = Math.sin(frame * 3.1) * 1.5;
  return <Big size={size} color={accent ? colors.accent : colors.text} style={{ ...slam, translate: `${jitter}px 0`, textShadow: accent ? `0 0 40px ${colors.accent}, ${SHADOW}` : SHADOW }}>{text}</Big>;
};

// ---------- 1. Intro ----------
const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const i = P.intro;
  // a failing light: mostly steady, the odd dip
  const flicker = random(`fl${Math.floor(frame / 2)}`) < 0.12 ? 0.45 : 0.9 + 0.1 * Math.sin(frame * 0.9);
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{ filter: `brightness(${flicker})` }}>
        {i.shots.map((s) => (
          <Sequence key={s.clip} from={f(s.at[0])} durationInFrames={f(s.at[1]) - f(s.at[0])}>
            <Clip name={s.clip} len={f(4)} zoom={[1.1, 1.22]} grade={HAUNT} />
          </Sequence>
        ))}
      </AbsoluteFill>
      <FoundFootage label={i.rec} />
      <Shade amount={0.45} />
      <Center style={{ flexDirection: 'column' }}>
        {i.lines.map((l, k) => <Line key={k} at={f(l.at)} text={l.text} accent={k === 1} size={150} />)}
      </Center>
    </AbsoluteFill>
  );
};

// ---------- 2. Drop ----------
const Drop: React.FC = () => (
  <AbsoluteFill>
    <Glitch at={0} len={8}>
      <Clip name={P.drop.clip} len={f(2)} zoom={[1.3, 1.1]} grade={HAUNT} />
      <AbsoluteFill style={{ background: `radial-gradient(ellipse 40% 60% at 75% 55%, rgba(221,232,91,0.25), transparent 70%)`, mixBlendMode: 'screen' }} />
    </Glitch>
    <Shade amount={0.4} />
    <Center><Line at={0} text={P.drop.text} accent size={240} /></Center>
    <Flash at={0} len={8} peak={0.6} />
  </AbsoluteFill>
);

// ---------- 3. Watch: a lock-on reticle per swing ----------
const Reticle: React.FC = () => {
  const frame = useCurrentFrame();
  const lock = interpolate(frame, [0, 8], [1.8, 1], { ...clamp, easing: Easing.out(Easing.back(2)) });
  return (
    <svg width={1920} height={1080} style={{ position: 'absolute', inset: 0 }}>
      <g transform={`translate(960 540) scale(${lock}) rotate(${frame * 2})`} stroke={colors.accent} strokeWidth={3} fill="none" style={{ filter: `drop-shadow(0 0 8px ${colors.accent})` }}>
        <circle r={150} strokeDasharray="40 22" />
        <circle r={6} fill={colors.accent} />
        {[0, 90, 180, 270].map((a) => <line key={a} x1={170} x2={230} transform={`rotate(${a})`} />)}
      </g>
      <text x={960 + 190} y={540 - 160} fill={colors.accent} style={{ font: `26px ${fonts.mono}`, letterSpacing: 3 }}>{frame % 10 < 6 ? 'TRACKING' : ''}</text>
    </svg>
  );
};
const Watch: React.FC = () => (
  <>
    {P.watch.shots.map((s, i) => (
      <Sequence key={s.clip} from={f(i * 2)} durationInFrames={f(i * 2 + 2) - f(i * 2)}>
        <Glitch at={0} len={4}>
          <Clip name={s.clip} len={f(2)} zoom={[1.2, 1.04]} grade={HAUNT} />
        </Glitch>
        <Shade amount={0.35} />
        <Reticle />
        <Center style={{ alignItems: 'flex-end', justifyContent: 'flex-end', padding: '0 110px 100px' }}>
          <Line at={0} text={s.word} accent={i === 2} size={170} />
        </Center>
      </Sequence>
    ))}
  </>
);

// ---------- 4. Inside: push into the grip, X-ray into the CAD handle ----------
const Inside: React.FC = () => {
  const frame = useCurrentFrame();
  const n = P.inside;
  const b = (beat: number) => f(beat - n.at[0]);
  const cut = b(n.cut), end = b(n.at[1]);
  const k = frame - cut;
  const explode = interpolate(k, [0, f(2)], [0.1, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  const move = interpolate(k, [0, end - cut], [0, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  const heart = pulse(frame, 2) * 0.8 + 0.2; // a slow heartbeat, every other beat
  const up = interpolate(k, [0, 7], [1, 0], clamp);
  return (
    <AbsoluteFill>
      {frame < cut ? (
        <PushToBlack clip={n.clip} len={cut} origin={n.origin} zoom={3.2} grade={HAUNT} />
      ) : (
        <AbsoluteFill>
          <Plate name={n.plate} blur={28} dim={0.7} zoom={1.5} grade={HAUNT} />
          <AbsoluteFill style={{ background: 'repeating-linear-gradient(0deg, rgba(221,232,91,0.05) 0 2px, transparent 2px 6px)' }} />
          <AbsoluteFill style={{ filter: 'contrast(1.1) saturate(0.7)' }}>
            <HandleCGI explode={explode} move={move} glow={heart} rim={colors.accent} xray />
          </AbsoluteFill>
          <div style={{ position: 'absolute', right: 110, top: 100, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.accent }}>◆ X-RAY · CAD</div>
          <div style={{ position: 'absolute', left: 110, bottom: 100 }}>
            <Line at={cut} text={n.lines[0]} size={130} />
            <Line at={cut + f(2)} text={n.lines[1]} accent size={130} />
          </div>
          <div style={{ position: 'absolute', right: 110, bottom: 110 }}>
            <Tags tags={n.tags} at={cut + f(2.5)} every={f(0.5)} />
          </div>
          <AbsoluteFill style={{ background: '#050504', opacity: up }} />
        </AbsoluteFill>
      )}
    </AbsoluteFill>
  );
};

// ---------- 5. Trained by a robot ----------
const Trained: React.FC = () => {
  const t = P.trained;
  return (
    <AbsoluteFill>
      {t.clips.map((clip, i) => (
        <Sequence key={clip} from={f(i * 2)} durationInFrames={f(i * 2 + 2) - f(i * 2)}>
          <Glitch at={0} len={4}>
            <Clip name={clip} len={f(2)} zoom={[1.18, 1.04]} grade={HAUNT} />
          </Glitch>
        </Sequence>
      ))}
      <Shade amount={0.45} />
      <Center style={{ flexDirection: 'column' }}>
        {t.lines.map((l, k) => <Line key={k} at={f(l.at - t.at[0])} text={l.text} accent={k === 1} size={170} />)}
      </Center>
    </AbsoluteFill>
  );
};

// ---------- 6. Wants your game ----------
const Wants: React.FC = () => {
  const w = P.wants;
  return (
    <>
      {w.shots.map((s, i) => (
        <Sequence key={s.clip} from={f(s.at[0] - w.at[0])} durationInFrames={f(s.at[1]) - f(s.at[0])}>
          <Glitch at={0} len={i ? 5 : 0}>
            <Clip name={s.clip} len={f(4)} zoom={[1.0, 1.14]} grade={HAUNT} />
          </Glitch>
          <Shade amount={0.35} />
          <Center><Line at={2} text={s.word} accent={i === 1} size={200} /></Center>
        </Sequence>
      ))}
    </>
  );
};

// ---------- 7. Finale ----------
const Finale: React.FC = () => {
  const frame = useCurrentFrame();
  const fin = P.finale;
  const cut = f(fin.cut - fin.at[0]);
  return (
    <AbsoluteFill>
      {frame < cut ? (
        <AbsoluteFill>
          <Clip name={fin.clip} len={cut} zoom={[1.05, 1.2]} grade={HAUNT} />
          <FoundFootage label="CAM 02  ·  COURT 4" offset={f(40)} />
        </AbsoluteFill>
      ) : (
        <Sequence from={cut} layout="none">
          <Glitch at={0} len={6}>
            <RacketFinale beat={BEAT} finish="red" name={fin.name} line={fin.line} cta={fin.cta} room={fin.clip} grade={HAUNT} glow={(k) => 0.6 + 0.4 * pulse(k + cut, 2)} />
          </Glitch>
        </Sequence>
      )}
      <Flash at={cut - 1} len={8} peak={0.55} />
    </AbsoluteFill>
  );
};

const duck = makeDuck(possessedCues, f);

export const Possessed: React.FC = () => {
  const s = P.song;
  return (
    <AbsoluteFill style={{ background: colors.bg, color: colors.text, fontFamily: fonts.sans, overflow: 'hidden' }}>
      <Shot at={P.intro.at}><Intro /></Shot>
      <Shot at={P.drop.at}><Drop /></Shot>
      <Shot at={P.watch.at}><Watch /></Shot>
      <Shot at={P.inside.at}><Inside /></Shot>
      <Shot at={P.trained.at}><Trained /></Shot>
      <Shot at={P.wants.at}><Wants /></Shot>
      <Shot at={P.finale.at}><Finale /></Shot>
      <Vignette strength={0.7} />
      <Grain />
      <Audio src={staticFile(s.src)} volume={(fr) => s.volume * duck(fr) * interpolate(fr, [possessedFrames - 24, possessedFrames], [1, 0], clamp)} />
      {possessedCues.map((c, i) => <Effect key={i} cue={{ ...c, at: 0 }} frame={f(c.beat)} />)}
    </AbsoluteFill>
  );
};

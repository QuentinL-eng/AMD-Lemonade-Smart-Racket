// EverySwing (~29 s X clip): on court with the racket, on "Not My First Rodeo". Timed in beats;
// copy, clips and beats come from src/config/everySwing.ts. Same treatment as RobotHype: one
// grade, grain and vignette over real and CGI, CGI over a blurred plate of the same court.
import React from 'react';
import { AbsoluteFill, Audio, Easing, Sequence, interpolate, staticFile, useCurrentFrame } from 'remotion';
import { Effect } from '../components/Timeline';
import { Racket } from '../components/Racket';
import { Stage3D } from '../components/Stage3D';
import { colors, fonts } from '../config/brand';
import { everySwing as E, everySwingCues } from '../config/everySwing';
import { gyroTrace } from '../config/gyro-trace';
import { Big, Center, Grain, useSlam } from './Hype';
import { Brackets, Clip, Flash, GRADE, Plate, SHADOW, Shade, Vignette, beatClock, clamp, makeDuck, type V3, whipIn, whipOut } from './kit';
import { RacketFinale, WordShot } from './pieces';

const { BEAT, f, pulse, Shot } = beatClock(E.song.bpm); // ~19.57 frames per beat
export const everySwingFrames = f(E.beats);

// ---------- 1. Hook: the serve, contact on the drop ----------
const Hook: React.FC = () => (
  <>
    {E.hook.shots.map((s) => (
      <Sequence key={s.clip} from={f(s.at[0])} durationInFrames={f(s.at[1]) - f(s.at[0])}>
        <WordShot clip={s.clip} len={f(2)} word={s.word} accent={'accent' in s} size={'accent' in s ? 230 : 150} zoom={'accent' in s ? [1.25, 1.05] : [1.12, 1.02]} />
      </Sequence>
    ))}
    <Flash at={f(4)} len={8} peak={0.55} />
  </>
);

// ---------- 2. Montage: one shot per beat under a viewfinder HUD ----------
/** The racket's own gyro trace, scrolling: a live readout in the corner. */
const Sparkline: React.FC<{ offset: number; width?: number; height?: number }> = ({ offset, width = 420, height = 90 }) => {
  const n = 120, max = Math.max(...gyroTrace);
  const pts = Array.from({ length: n }, (_, i) => gyroTrace[(offset + i) % gyroTrace.length]);
  const d = pts.map((v, i) => `${i ? 'L' : 'M'}${((i / (n - 1)) * width).toFixed(1)},${(height - (v / max) * (height - 6)).toFixed(1)}`).join(' ');
  return (
    <svg width={width} height={height} style={{ overflow: 'visible' }}>
      <line x1={0} x2={width} y1={height} y2={height} stroke="rgba(243,245,236,0.3)" strokeWidth={2} />
      <path d={d} stroke={colors.accent} strokeWidth={3} fill="none" strokeLinejoin="round" />
    </svg>
  );
};
const MontageShot: React.FC<{ i: number }> = ({ i }) => {
  const frame = useCurrentFrame();
  const shot = E.montage.shots[i];
  const slam = useSlam(0);
  const last = i === E.montage.shots.length - 1;
  const t = (f(E.montage.at[0] + i) + frame) / 30;
  return (
    <AbsoluteFill style={i === 0 ? whipIn(frame, 0) : undefined}>
      <Clip name={shot.clip} len={f(1)} zoom={[1.22, 1.06]} ease={Easing.out(Easing.cubic)} />
      {last ? (
        <>
          <Shade amount={0.45} />
          <Center><Big size={230} color={colors.accent} style={{ ...slam, textShadow: SHADOW }}>{shot.tag}</Big></Center>
        </>
      ) : (
        <>
          <AbsoluteFill style={{ background: 'linear-gradient(0deg, rgba(0,0,0,0.55), transparent 45%)' }} />
          <Brackets />
          <div style={{ position: 'absolute', left: 110, top: 100, fontFamily: fonts.mono, fontSize: 26, color: colors.text, display: 'flex', gap: 16, alignItems: 'center' }}>
            <div style={{ width: 16, height: 16, borderRadius: 8, background: colors.accent, opacity: frame % 12 < 8 ? 1 : 0.25 }} />
            LIVE  00:{t.toFixed(2).padStart(5, '0')}
          </div>
          <div style={{ position: 'absolute', right: 110, top: 100, fontFamily: fonts.mono, fontSize: 26, color: colors.accent }}>SHOT {String(i + 1).padStart(2, '0')}</div>
          <div style={{ position: 'absolute', left: 110, bottom: 110 }}>
            <div style={{ fontFamily: fonts.mono, fontSize: 26, letterSpacing: 4, color: colors.accent, marginBottom: 10 }}>MEASURING ▸</div>
            <Big size={140} style={{ ...slam, transformOrigin: 'left center', textShadow: SHADOW }}>{shot.tag}</Big>
          </div>
          <div style={{ position: 'absolute', right: 110, bottom: 120 }}>
            <Sparkline offset={(i * 70 + frame * 3) % gyroTrace.length} />
          </div>
        </>
      )}
    </AbsoluteFill>
  );
};

// ---------- 3. Feel: the CGI racket swings through two balls; the contact point lights up ----------
// Camera looks straight at the string bed. The racket turns about a "wrist" below the frame,
// so its head sweeps across the frame: forehand left -> right, then back.
const FEEL_CAM = { pos: [0, 0.3, 6.5] as V3, target: [0, 0.3, 0] as V3, fov: 34 };
const PIVOT: V3 = [0.9, -1.3, 0];
const REACH = 1.75; // pivot -> racket centre
const HEAD = REACH + 0.76; // pivot -> head centre
const PX = 1080 / (2 * FEEL_CAM.pos[2] * Math.tan((FEEL_CAM.fov / 2) * (Math.PI / 180))); // px per unit at z = 0
const toScreen = (x: number, y: number) => [960 + x * PX, 540 - (y - FEEL_CAM.target[1]) * PX];
const SWING = 0.9;
const Feel: React.FC = () => {
  const frame = useCurrentFrame();
  const fe = E.feel;
  const b = (beat: number) => f(beat - fe.at[0]);
  const [c1, c2] = fe.contacts.map(b);
  const s = (c: number, fr: number) => 0.5 + 0.5 * Math.tanh((fr - c) / 2.4);
  const angleAt = (fr: number) => SWING - 2 * SWING * s(c1, fr) + 2 * SWING * s(c2, fr);
  const angle = angleAt(frame);
  const head = (a: number) => toScreen(PIVOT[0] - HEAD * Math.sin(a), PIVOT[1] + HEAD * Math.cos(a));
  // ball: in from the side the racket is moving toward, back out the way it came, faster
  const c = frame < (c1 + c2) / 2 ? c1 : c2;
  const side = c === c1 ? 1 : -1;
  const hit: V3 = [PIVOT[0], PIVOT[1] + HEAD, 0.15];
  const inT = interpolate(frame, [c - 14, c], [0, 1], clamp);
  const outT = interpolate(frame, [c, c + 12], [0, 1], clamp);
  const ball: V3 = frame < c
    ? [hit[0] + side * 4.5 * (1 - inT), hit[1] + 0.3 * (1 - inT), hit[2] - 1.5 * (1 - inT)]
    : [hit[0] + side * 5 * outT, hit[1] + 0.7 * outT, hit[2] - 7 * outT];
  const showBall = frame > c - 15 && frame < c + 12;
  // motion trail of the head over the last frames
  const trail = Array.from({ length: 7 }, (_, k) => head(angleAt(frame - k * 0.8)));
  const speed = Math.abs(angleAt(frame) - angleAt(frame - 1));
  const glow = Math.max(0, 1 - Math.min(Math.abs(frame - c1), Math.abs(frame - c2)) / 7);
  const ring = frame >= c1 ? (frame - (frame >= c2 ? c2 : c1)) : -1;
  const [hx, hy] = head(0);
  const l1 = useSlam(0);
  const l2 = useSlam(b(fe.contacts[0]));
  const shake = frame >= c1 && frame < c1 + 6 ? Math.sin(frame * 7.1) * 10 * (1 - (frame - c1) / 6) : frame >= c2 && frame < c2 + 6 ? Math.sin(frame * 7.1) * 10 * (1 - (frame - c2) / 6) : 0;
  const end = b(fe.at[1]);
  return (
    <AbsoluteFill style={{ ...whipIn(frame, 0), ...whipOut(frame, end), translate: `${shake}px ${-shake / 2}px` }}>
      <Plate name={fe.plate} blur={24} dim={0.55} zoom={1.2} />
      <AbsoluteFill style={{ filter: GRADE }}>
        <Stage3D camera={FEEL_CAM.pos} target={FEEL_CAM.target} fov={FEEL_CAM.fov} rim="#ffe9c9" envIntensity={0.8}>
          <group position={PIVOT} rotation={[0, 0, angle]}>
            <Racket finish="red" position={[0, REACH, 0]} rotation={[0, -0.35 * angle, 0]} glow={glow} />
          </group>
          {showBall && (
            <mesh position={ball}>
              <sphereGeometry args={[0.147, 32, 32]} />
              <meshStandardMaterial color="#D9EE3F" roughness={0.9} emissive="#D9EE3F" emissiveIntensity={0.15} />
            </mesh>
          )}
        </Stage3D>
      </AbsoluteFill>
      <svg width={1920} height={1080} style={{ position: 'absolute', inset: 0, mixBlendMode: 'screen', filter: 'blur(6px)', opacity: Math.min(1, speed * 6) }}>
        {trail.slice(1).map(([x, y], k) => (
          <line key={k} x1={trail[k][0]} y1={trail[k][1]} x2={x} y2={y} stroke={colors.accent} strokeWidth={60 - k * 7} strokeLinecap="round" opacity={0.5 - k * 0.07} />
        ))}
      </svg>
      {ring >= 0 && (
        <svg width={1920} height={1080} style={{ position: 'absolute', inset: 0 }}>
          <circle cx={hx} cy={hy} r={18 + ring * 6} fill="none" stroke={colors.accent} strokeWidth={4} opacity={Math.max(0, 1 - ring / 14)} />
          <circle cx={hx} cy={hy} r={11} fill={colors.accent} opacity={Math.abs(angle) < 0.35 ? 1 : 0} style={{ filter: `drop-shadow(0 0 12px ${colors.accent})` }} />
        </svg>
      )}
      {ring >= 0 && Math.abs(angle) < 0.35 && (
        <div style={{ position: 'absolute', left: hx + 34, top: hy - 18, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.accent, background: 'rgba(11,12,9,0.6)', padding: '4px 12px', borderRadius: 6 }}>{fe.label}</div>
      )}
      <div style={{ position: 'absolute', left: 110, bottom: 110 }}>
        <Big size={130} style={{ ...l1, transformOrigin: 'left center', textShadow: SHADOW }}>{fe.lines[0]}</Big>
        {frame >= b(fe.contacts[0]) && <Big size={150} color={colors.accent} style={{ ...l2, transformOrigin: 'left center', textShadow: SHADOW }}>{fe.lines[1]}</Big>}
      </div>
      <div style={{ position: 'absolute', right: 110, top: 100, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.accent }}>◆ CGI</div>
      <Flash at={c1} len={6} peak={0.4} />
      <Flash at={c2} len={6} peak={0.4} />
    </AbsoluteFill>
  );
};

// ---------- 4. The app on the phone ----------
const Phone: React.FC = () => {
  const frame = useCurrentFrame();
  const p = E.phone;
  const b = (beat: number) => f(beat - p.at[0]);
  const l1 = useSlam(0);
  const l2 = useSlam(b(22));
  return (
    <AbsoluteFill>
      {p.shots.map((s) => (
        <Sequence key={s.clip} from={b(s.at[0])} durationInFrames={b(s.at[1]) - b(s.at[0])}>
          <Clip name={s.clip} len={b(s.at[1]) - b(s.at[0])} zoom={[1.0, 1.12]} origin="65% 50%" />
        </Sequence>
      ))}
      <AbsoluteFill style={{ background: 'linear-gradient(90deg, rgba(0,0,0,0.6), transparent 55%)' }} />
      <div style={{ position: 'absolute', left: 110, top: 100, display: 'flex', alignItems: 'center', gap: 14, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.accent }}>
        <div style={{ width: 14, height: 14, borderRadius: 7, background: colors.accent, boxShadow: `0 0 ${10 + 10 * pulse(frame)}px ${colors.accent}` }} />
        SYNCED TO THE APP
      </div>
      <div style={{ position: 'absolute', left: 110, bottom: 110 }}>
        <Big size={120} style={{ ...l1, transformOrigin: 'left center', textShadow: SHADOW }}>{p.lines[0]}</Big>
        {frame >= b(22) && <Big size={120} color={colors.accent} style={{ ...l2, transformOrigin: 'left center', textShadow: SHADOW }}>{p.lines[1]}</Big>}
      </div>
    </AbsoluteFill>
  );
};

// ---------- 5. Serve against the sky, then four hits, one word each ----------
const Train: React.FC = () => {
  const frame = useCurrentFrame();
  const t = E.train;
  const b = (beat: number) => f(beat - t.at[0]);
  const hit = Math.floor((frame - b(30)) / BEAT);
  const word = Math.min(2, hit);
  const slam = useSlam(b(30 + word));
  return (
    <AbsoluteFill>
      <Sequence durationInFrames={b(30)}>
        <WordShot clip={t.sky} len={b(30)} word={t.line} size={170} zoom={[1.0, 1.1]} at={4} />
      </Sequence>
      {t.hits.map((clip, i) => (
        <Sequence key={clip} from={b(30 + i)} durationInFrames={b(31 + i) - b(30 + i)}>
          <Clip name={clip} len={b(31 + i) - b(30 + i)} zoom={[1.28, 1.06]} />
          <Flash at={0} len={5} peak={0.3} />
        </Sequence>
      ))}
      {frame >= b(30) && (
        <>
          <Shade amount={0.4} />
          <Center><Big key={word} size={240} color={word === 2 ? colors.accent : colors.text} style={{ ...slam, textShadow: SHADOW }}>{t.words[word]}</Big></Center>
        </>
      )}
    </AbsoluteFill>
  );
};

// ---------- 6. Finale ----------
const Finale: React.FC = () => {
  const frame = useCurrentFrame();
  const fin = E.finale;
  const cut = f(fin.cut - fin.at[0]);
  const blurIn = interpolate(frame, [cut - 5, cut], [0, 8], clamp);
  return (
    <AbsoluteFill>
      {frame < cut ? (
        <AbsoluteFill style={{ filter: blurIn ? `blur(${blurIn}px)` : undefined }}>
          <Clip name={fin.clip} len={cut} zoom={[1, 1.25]} origin="45% 60%" ease={Easing.in(Easing.quad)} />
        </AbsoluteFill>
      ) : (
        <Sequence from={cut} layout="none">
          <RacketFinale beat={BEAT} finish="red" name={fin.name} tagline={fin.tagline} cta={fin.cta} room={fin.clip} glow={(k) => 0.4 + 0.6 * pulse(k + cut)} />
        </Sequence>
      )}
      <Flash at={cut - 1} len={6} peak={0.5} />
    </AbsoluteFill>
  );
};

const duck = makeDuck(everySwingCues, f);

export const EverySwing: React.FC = () => {
  const s = E.song;
  return (
    <AbsoluteFill style={{ background: colors.bg, color: colors.text, fontFamily: fonts.sans, overflow: 'hidden' }}>
      <Shot at={E.hook.at}><Hook /></Shot>
      {E.montage.shots.map((_, i) => (
        <Shot key={i} at={[E.montage.at[0] + i, E.montage.at[0] + i + 1]}><MontageShot i={i} /></Shot>
      ))}
      <Shot at={E.feel.at}><Feel /></Shot>
      <Shot at={E.phone.at}><Phone /></Shot>
      <Shot at={E.train.at}><Train /></Shot>
      <Shot at={E.finale.at}><Finale /></Shot>
      <Vignette />
      <Grain />
      <Audio src={staticFile(s.src)} volume={(fr) => s.volume * duck(fr) * interpolate(fr, [everySwingFrames - 24, everySwingFrames], [1, 0], clamp)} />
      {everySwingCues.map((c, i) => <Effect key={i} cue={{ ...c, at: 0 }} frame={f(c.beat)} />)}
    </AbsoluteFill>
  );
};

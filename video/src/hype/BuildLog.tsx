// BuildLog (~26 s X clip): "how to build an AI tennis racket" as six numbered steps, on
// "Comin Wit It". Timed in beats; copy, clips and beats come from src/config/buildLog.ts.
// Real -> CGI hand-offs as in RobotHype: one grade, grain and vignette over both, CGI over the
// real place (blurred), and each cut on matching framing: the pod's end, the CAD on the monitor,
// the racket held up at the gate.
import React from 'react';
import { AbsoluteFill, Audio, Easing, Sequence, interpolate, staticFile, useCurrentFrame } from 'remotion';
import { Effect } from '../components/Timeline';
import { Stage3D } from '../components/Stage3D';
import { colors, fonts } from '../config/brand';
import { buildLog as B, buildLogCues } from '../config/buildLog';
import { RobotArm } from '../scenes/RobotLab';
import { Big, Center, Grain, useSlam } from './Hype';
import { Clip, Flash, GRADE, Plate, SHADOW, Shade, Vignette, beatClock, clamp, inOut, makeDuck, mix, type V3, whipIn, whipOut } from './kit';
import { HandleCGI, PushToBlack, RacketFinale, Tags } from './pieces';

const { BEAT, f, pulse, Shot } = beatClock(B.song.bpm); // ~13.78 frames per beat
export const buildLogFrames = f(B.beats);
const [SOLDER, HANDLE, CODE, ROBOT, REPEAT, OUTSIDE] = B.steps;

// ---------- 1. Intro: the title over the bench, music muffled ----------
const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const i = B.intro;
  const top = useSlam(f(0.5));
  const bottom = useSlam(f(4));
  const typed = B.intro.kicker.slice(0, Math.floor(frame / 3));
  // a lamp-like flicker while the music is still behind the wall
  const flicker = 0.85 + 0.15 * Math.sin(frame * 1.7) * Math.sin(frame * 0.37);
  return (
    <AbsoluteFill style={{ filter: `brightness(${flicker})` }}>
      {i.shots.map((s) => (
        <Sequence key={s.clip} from={f(s.at[0])} durationInFrames={f(s.at[1]) - f(s.at[0])}>
          <Clip name={s.clip} len={f(4)} zoom={[1.18, 1.04]} />
        </Sequence>
      ))}
      <Shade amount={0.5} />
      <Center style={{ flexDirection: 'column', gap: 12 }}>
        <div style={{ fontFamily: fonts.mono, fontSize: 30, letterSpacing: 8, color: colors.accent, marginBottom: 14, minHeight: 40 }}>● {typed}{frame % 16 < 8 ? '_' : ' '}</div>
        <Big size={150} style={{ ...top, textShadow: SHADOW }}>{i.title[0]}</Big>
        {frame >= f(4) && <Big size={150} color={colors.accent} style={{ ...bottom, textShadow: SHADOW }}>{i.title[1]}</Big>}
      </Center>
    </AbsoluteFill>
  );
};

// ---------- 2. Steps: counter top left, title bottom left, over whatever the step shows ----------
const StepFrame: React.FC<{ n: number; title: string; children: React.ReactNode; titleAt?: number }> = ({ n, title, children, titleAt = 0 }) => {
  const frame = useCurrentFrame();
  const slam = useSlam(titleAt);
  const total = B.steps.length;
  const fill = interpolate(frame, [0, 10], [(n - 1) / total, n / total], { ...clamp, easing: Easing.out(Easing.cubic) });
  return (
    <AbsoluteFill>
      {children}
      <AbsoluteFill style={{ background: 'linear-gradient(0deg, rgba(0,0,0,0.6), transparent 42%)', pointerEvents: 'none' }} />
      <div style={{ position: 'absolute', left: 110, top: 96 }}>
        <div style={{ fontFamily: fonts.mono, fontSize: 28, letterSpacing: 4, color: colors.text, textShadow: SHADOW }}>
          STEP <span style={{ color: colors.accent }}>{String(n).padStart(2, '0')}</span> / {String(total).padStart(2, '0')}
        </div>
        <div style={{ width: 300, height: 5, marginTop: 14, background: 'rgba(243,245,236,0.25)' }}>
          <div style={{ width: `${fill * 100}%`, height: '100%', background: colors.accent }} />
        </div>
      </div>
      {frame >= titleAt && (
        <div style={{ position: 'absolute', left: 110, bottom: 100, right: 110 }}>
          <Big size={title.length > 18 ? 116 : 140} style={{ ...slam, transformOrigin: 'left center', textShadow: SHADOW }}>{title}</Big>
        </div>
      )}
    </AbsoluteFill>
  );
};

/** Shots of `beats` beats each, back to back from local frame 0. */
const Cuts: React.FC<{ shots: readonly { clip: string; beats: number }[]; zoom?: [number, number] }> = ({ shots, zoom = [1.14, 1.02] }) => {
  let at = 0;
  return (
    <>
      {shots.map((s, i) => {
        const el = (
          <Sequence key={i} from={f(at)} durationInFrames={f(at + s.beats) - f(at)}>
            <Clip name={s.clip} len={f(s.beats)} zoom={zoom} ease={Easing.out(Easing.cubic)} />
          </Sequence>
        );
        at += s.beats;
        return el;
      })}
    </>
  );
};

const Handle: React.FC = () => {
  const frame = useCurrentFrame();
  const h = HANDLE;
  const b = (beat: number) => f(beat - h.at[0]);
  const push = b(h.push), cut = b(h.cut), end = b(h.at[1]);
  const k = frame - cut;
  const explode = interpolate(k, [0, f(1.4)], [0.25, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  const move = interpolate(k, [0, end - cut], [0, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  const up = interpolate(k, [0, 7], [1, 0], clamp);
  return (
    <StepFrame n={2} title={h.title}>
      {frame < push && <Clip name={h.pcb} len={push} zoom={[1.1, 1.22]} />}
      {frame >= push && frame < cut && (
        <Sequence from={push} layout="none">
          <PushToBlack clip={h.pod} len={cut - push} origin={h.podOrigin} zoom={3.6} />
        </Sequence>
      )}
      {frame >= cut && (
        <AbsoluteFill>
          <Plate name="bt-plate-bench" blur={26} dim={0.62} zoom={1.5} />
          <AbsoluteFill style={{ filter: GRADE }}>
            <HandleCGI explode={explode} move={move} imu={k > f(1) ? 0.5 + 0.5 * pulse(frame) : 0} />
          </AbsoluteFill>
          <div style={{ position: 'absolute', right: 110, top: 100 }}>
            <Tags tags={h.tags} at={cut + f(0.5)} every={f(0.5)} />
          </div>
          <AbsoluteFill style={{ background: '#050504', opacity: up }} />
        </AbsoluteFill>
      )}
    </StepFrame>
  );
};

// The CAD on the monitor shows the arm from its side, upright, light grey on dark grey.
const VIEWPORT_CAM = { from: [-0.4, 1.8, 7.2] as V3, to: [-0.9, 1.5, 5.6] as V3, target: [-0.6, 1.2, 0] as V3 };
const Robot: React.FC = () => {
  const frame = useCurrentFrame();
  const r = ROBOT;
  const b = (beat: number) => f(beat - r.at[0]);
  const cut = b(r.cut), whip = b(r.whip), end = b(r.at[1]);
  const glow = interpolate(frame, [cut - 6, cut], [0, 1], clamp); // the monitor's light fills the frame
  const t = interpolate(frame, [cut, whip], [0, 1], clamp);
  const angle = interpolate(frame, [cut, whip - 4], [-0.2, 0.55], { ...clamp, easing: inOut });
  return (
    <StepFrame n={4} title={r.title}>
      {frame < cut && (
        <AbsoluteFill>
          <Clip name={r.cad} len={cut} zoom={[1, 4.2]} origin={r.monitor} ease={Easing.in(Easing.cubic)} />
          <AbsoluteFill style={{ background: '#2a2d31', opacity: glow * 0.9 }} />
        </AbsoluteFill>
      )}
      {frame >= cut && frame < whip && (
        <AbsoluteFill style={whipOut(frame, whip)}>
          {/* CAD viewport: flat dark grey with a faint grid, like the monitor */}
          <AbsoluteFill style={{ background: 'radial-gradient(ellipse at 50% 40%, #34383d, #1f2226 75%)' }} />
          <AbsoluteFill style={{ filter: GRADE }}>
            <Stage3D camera={mix(VIEWPORT_CAM.from, VIEWPORT_CAM.to, t)} target={VIEWPORT_CAM.target} fov={36} rim="#ffffff" envIntensity={0.8}>
              <RobotArm angle={angle} racket="blue" />
            </Stage3D>
          </AbsoluteFill>
          <div style={{ position: 'absolute', right: 110, top: 100, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.accent }}>◆ CAD · TEST RIG</div>
          <AbsoluteFill style={{ background: '#2a2d31', opacity: interpolate(frame, [cut, cut + 5], [0.9, 0], clamp) }} />
        </AbsoluteFill>
      )}
      {frame >= whip && (
        <AbsoluteFill style={whipIn(frame, whip)}>
          <Clip name={r.real} len={end - whip} zoom={[1.15, 1]} />
          <div style={{ position: 'absolute', right: 110, top: 100, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.text }}>● REAL · EPSON C8</div>
        </AbsoluteFill>
      )}
    </StepFrame>
  );
};

const Repeat: React.FC = () => {
  const frame = useCurrentFrame();
  const r = REPEAT;
  const word = Math.min(2, Math.floor(frame / f(2)));
  const slam = useSlam(f(word * 2));
  const last = word === 2;
  return (
    <AbsoluteFill>
      <StepFrame n={5} title="" titleAt={1e9}>
        {r.shots.map((clip, i) => (
          <Sequence key={i} from={f(i)} durationInFrames={f(i + 1) - f(i)}>
            <Clip name={clip} len={f(1)} zoom={[1.2, 1.05]} />
          </Sequence>
        ))}
        <Flash at={f(Math.floor(frame / BEAT))} len={4} peak={0.18} />
      </StepFrame>
      <Center>
        <div style={{ position: 'relative' }}>
          {/* REPEAT. echoes once per beat behind itself */}
          {last && [3, 2, 1].map((e) => {
            const on = frame >= f(4 + e);
            return on && <Big key={e} size={230} color="transparent" style={{ position: 'absolute', inset: 0, WebkitTextStroke: `2px ${colors.accent}`, opacity: 0.5 / e, transform: `scale(${1 + e * 0.12})` }}>{r.words[2]}</Big>;
          })}
          <Big key={word} size={230} color={last ? colors.accent : colors.text} style={{ ...slam, textShadow: SHADOW }}>{r.words[word]}</Big>
        </div>
      </Center>
    </AbsoluteFill>
  );
};

const Outside: React.FC = () => {
  const frame = useCurrentFrame();
  const o = OUTSIDE;
  return (
    <StepFrame n={6} title={o.title}>
      {o.hits.map((clip, i) => (
        <Sequence key={clip} from={f(i)} durationInFrames={f(1 + i) - f(i)}>
          <Clip name={clip} len={f(1)} zoom={[1.2, 1.04]} />
          <Flash at={0} len={5} peak={0.35} />
        </Sequence>
      ))}
      <Sequence from={f(4)} durationInFrames={f(8) - f(4)}>
        <Clip name={o.gate} len={f(4)} zoom={[1, 1.08]} origin="47% 32%" />
      </Sequence>
      {frame < f(4) && <div style={{ position: 'absolute', right: 110, top: 100, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.accent }}>● ON COURT</div>}
    </StepFrame>
  );
};

// ---------- 3. Finale: the racket at the net, cut to CGI, the name ----------
const Finale: React.FC = () => {
  const frame = useCurrentFrame();
  const fin = B.finale;
  const cut = f(fin.cut - fin.at[0]);
  const blurIn = interpolate(frame, [cut - 5, cut], [0, 8], clamp);
  return (
    <AbsoluteFill>
      {frame < cut ? (
        <AbsoluteFill style={{ filter: blurIn ? `blur(${blurIn}px)` : undefined }}>
          <Clip name={fin.clip} len={cut} zoom={[1.08, 2.6]} origin={fin.racket} ease={Easing.in(Easing.quad)} />
        </AbsoluteFill>
      ) : (
        <Sequence from={cut} layout="none">
          <RacketFinale beat={BEAT} finish="red" name={fin.name} line={fin.line} cta={fin.cta} room={fin.clip} headDown={false} glow={(k) => 0.4 + 0.6 * pulse(k + cut)} />
        </Sequence>
      )}
      <Flash at={cut - 1} len={6} peak={0.5} />
    </AbsoluteFill>
  );
};

const duck = makeDuck(buildLogCues, f);

export const BuildLog: React.FC = () => {
  const s = B.song;
  return (
    <AbsoluteFill style={{ background: colors.bg, color: colors.text, fontFamily: fonts.sans, overflow: 'hidden' }}>
      <Shot at={B.intro.at}><Intro /></Shot>
      <Shot at={SOLDER.at}><StepFrame n={1} title={SOLDER.title}><Cuts shots={SOLDER.shots} /></StepFrame></Shot>
      <Shot at={HANDLE.at}><Handle /></Shot>
      <Shot at={CODE.at}><StepFrame n={3} title={CODE.title}><Cuts shots={CODE.shots} /></StepFrame></Shot>
      <Shot at={ROBOT.at}><Robot /></Shot>
      <Shot at={REPEAT.at}><Repeat /></Shot>
      <Shot at={OUTSIDE.at}><Outside /></Shot>
      <Shot at={B.finale.at}><Finale /></Shot>
      <Vignette />
      <Grain />
      <Audio src={staticFile(s.src)} volume={(fr) => s.volume * duck(fr) * interpolate(fr, [buildLogFrames - 24, buildLogFrames], [1, 0], clamp)} />
      {buildLogCues.map((c, i) => <Effect key={i} cue={{ ...c, at: 0 }} frame={f(c.beat)} />)}
    </AbsoluteFill>
  );
};

// The Lemonade Developer Challenge cut, about 1:57. Words and numbers: config/lemonade.ts. Media: scripts/cut-lemonade.py.
// Every cut is on the beat of "Comin Wit It". The bass runs alone for six bars, then the ball becomes a lemon on the drop.
import React from 'react';
import { AbsoluteFill, Audio, Easing, OffthreadVideo, Sequence, interpolate, spring, staticFile, useCurrentFrame } from 'remotion';
import { Effect } from '../components/Timeline';
import { Backdrop } from '../components/ui';
import { colors, fonts } from '../config/brand';
import type { Cue } from '../config/sound';
import { LEMON, lemonade as v } from '../config/lemonade';
import { Big, Center, Grain, useSlam } from './Hype';
import { Clip, FPS, Flash, GRADE, SHADOW, Vignette, beatClock, clamp, inOut, makeDuck } from './kit';
import { HandleCGI, RacketFinale, Tags } from './pieces';

const { BEAT, f } = beatClock(v.song.bpm);
/** First frame of a bar (from 1), plus some beats. */
const bar = (n: number, beat = 0) => f((n - 1) * 4 + beat);
export const lemonadeFrames = bar(v.bars) + 54;

const At: React.FC<{ n: number; beat?: number; to: number; toBeat?: number; children: React.ReactNode }> = ({ n, beat = 0, to, toBeat = 0, children }) => (
  <Sequence from={bar(n, beat)} durationInFrames={bar(to, toBeat) - bar(n, beat)}>{children}</Sequence>
);
/** Cuts through real clips, each `beats` long. */
const Shots: React.FC<{ list: [string, number, [number, number]?][] }> = ({ list }) => {
  let at = 0;
  return (
    <>
      {list.map(([name, beats, zoom], i) => {
        const from = f(at), len = f(at + beats) - from;
        at += beats;
        return <Sequence key={i} from={from} durationInFrames={len}><Clip name={name} len={len} zoom={zoom ?? [1.1, 1]} ease={Easing.out(Easing.quad)} /></Sequence>;
      })}
    </>
  );
};

// ---------- Type ----------
const Line: React.FC<{ text: string; color?: string; size?: number; at?: number; still?: boolean }> = ({ text, color = colors.text, size = 120, at = 0, still }) => {
  const frame = useCurrentFrame();
  const slam = useSlam(at);
  if (frame < at) return null;
  return (
    <AbsoluteFill style={{ justifyContent: 'flex-end', alignItems: 'center', textAlign: 'center', padding: '0 70px 110px', background: 'linear-gradient(0deg, rgba(5,6,3,0.85), rgba(5,6,3,0) 50%)' }}>
      <Big size={size} color={color} style={{ ...(still ? {} : slam), textShadow: SHADOW }}>{text}</Big>
    </AbsoluteFill>
  );
};
const Caption: React.FC<{ text: string; from?: number; to?: number }> = ({ text, from = 0, to = 1e9 }) => {
  const frame = useCurrentFrame();
  if (frame < from || frame >= to) return null;
  return (
    <div style={{ position: 'absolute', left: 0, right: 0, bottom: 36, display: 'flex', justifyContent: 'center', padding: '0 180px' }}>
      <div style={{ fontFamily: fonts.sans, fontWeight: 600, fontSize: 36, lineHeight: 1.25, textAlign: 'center', color: colors.text, background: 'rgba(11,12,9,0.78)', padding: '8px 22px', borderRadius: 12 }}>{text}</div>
    </div>
  );
};
const Kicker: React.FC<{ children: React.ReactNode; color?: string; style?: React.CSSProperties }> = ({ children, color = LEMON, style }) => (
  <div style={{ fontFamily: fonts.mono, fontSize: 30, letterSpacing: 5, color, ...style }}>{children}</div>
);
const rise = (frame: number, at: number, len = 8) => {
  const t = interpolate(frame, [at, at + len], [0, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  return { opacity: t, transform: `translateY(${(1 - t) * 26}px)` };
};

// ---------- The ball that becomes a lemon ----------
const FruitBall: React.FC<{ morph: number; size: number; spin?: number }> = ({ morph, size, spin = 0 }) => {
  // A circle with two seams that grows nubs at both ends and turns yellow.
  const nub = 12 * morph, w = 52 + 7 * morph, h = 52 - 5 * morph;
  const path = `M ${-w - nub} 0 C ${-w} ${-h * 0.25}, ${-w * 0.8} ${-h}, 0 ${-h} C ${w * 0.8} ${-h}, ${w} ${-h * 0.25}, ${w + nub} 0 C ${w} ${h * 0.25}, ${w * 0.8} ${h}, 0 ${h} C ${-w * 0.8} ${h}, ${-w} ${h * 0.25}, ${-w - nub} 0 Z`;
  const r = Math.round(217 + (255 - 217) * morph), g = Math.round(238 + (225 - 238) * morph), b = Math.round(63 + (74 - 63) * morph);
  return (
    <svg width={size} height={size} viewBox="-85 -85 170 170" style={{ transform: `rotate(${spin - 18 * morph}deg)`, overflow: 'visible' }}>
      <path d={path} fill={`rgb(${r},${g},${b})`} />
      <g opacity={1 - morph}>
        <path d="M -38 -36 C -10 -12, -10 12, -38 36" stroke="#F4F7E6" strokeWidth={6} fill="none" />
        <path d="M 38 -36 C 10 -12, 10 12, 38 36" stroke="#F4F7E6" strokeWidth={6} fill="none" />
      </g>
      <g opacity={morph * 0.5} fill="#E2B90F">
        {[[-24, -14], [-6, -24], [14, -18], [28, -4], [-30, 8], [-12, 4], [8, 2], [24, 14], [-16, 24], [6, 26]].map(([x, y], i) => <circle key={i} cx={x} cy={y} r={1.8} />)}
      </g>
      <ellipse cx={-14} cy={-22} rx={15} ry={7} fill="#fff" opacity={0.26 * morph} transform="rotate(-20 -14 -22)" />
    </svg>
  );
};

const Question: React.FC = () => {
  const frame = useCurrentFrame();
  const beat = frame / BEAT;
  const hop = Math.abs(Math.sin(beat * Math.PI));
  return (
    <AbsoluteFill style={{ background: colors.bg }}>
      <Center style={{ flexDirection: 'column', gap: 40 }}>
        <div style={{ height: 300, display: 'flex', alignItems: 'flex-end', transform: `translateY(${-hop * 110}px)` }}><FruitBall morph={0} size={170} spin={frame * 7} /></div>
        <Big size={100} style={{ ...rise(frame, 2), textTransform: 'none' }}>{v.question}</Big>
      </Center>
    </AbsoluteFill>
  );
};

const LemonDrop: React.FC = () => {
  const frame = useCurrentFrame();
  const morph = interpolate(frame, [0, 7], [0, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  const s = spring({ frame, fps: FPS, config: { damping: 9, stiffness: 180 } });
  const slam = useSlam(0);
  return (
    <AbsoluteFill style={{ background: `radial-gradient(ellipse 60% 70% at 50% 45%, rgba(255,225,74,0.2), ${colors.bg} 70%)` }}>
      <Center style={{ flexDirection: 'column', gap: 6 }}>
        <div style={{ transform: `scale(${0.7 + 0.3 * s})` }}><FruitBall morph={morph} size={300} spin={-10} /></div>
        <Big size={210} color={LEMON} style={slam}>{v.reveal.name}</Big>
        <div style={{ ...rise(frame, 8), fontFamily: fonts.sans, fontWeight: 600, fontSize: 44, color: colors.text, marginTop: 20 }}>{v.reveal.sub}</div>
      </Center>
    </AbsoluteFill>
  );
};

// ---------- The racket, its handle, the arm ----------
const Handle: React.FC = () => {
  const frame = useCurrentFrame();
  const explode = interpolate(frame, [f(2), f(9)], [0, 1], { ...clamp, easing: inOut });
  const move = interpolate(frame, [0, f(16)], [0, 1], { ...clamp, easing: inOut });
  return (
    <Backdrop glow={0.1}>
      <HandleCGI explode={explode} move={move} imu={frame > f(6) && frame < f(11) ? 1 : 0} glow={frame > f(11) ? 0.6 : 0} />
      <div style={{ position: 'absolute', left: 60, top: 44, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 3, color: colors.accent }}>◆ CGI · BUILT FROM OUR CAD</div>
      <div style={{ position: 'absolute', left: 60, bottom: 122 }}><Tags tags={v.tags} at={f(5)} every={f(3)} /></div>
    </Backdrop>
  );
};

// ---------- The real swing beside the app ----------
const Twin: React.FC<{ i: number }> = ({ i }) => {
  const t = v.twin[i];
  const frame = useCurrentFrame();
  const slam = useSlam(0);
  const hit = Math.exp(-((frame + 18) % 40) / 8);
  return (
    <AbsoluteFill style={{ background: colors.bg }}>
      <div style={{ position: 'absolute', left: 0, top: 0, width: 1180, height: 1080, overflow: 'hidden' }}>
        <OffthreadVideo muted src={staticFile(`footage/vx-twin-cam-${i}.mp4`)} style={{ width: '100%', height: '100%', objectFit: 'cover', filter: GRADE }} />
        <div style={{ position: 'absolute', top: 28, left: 28, fontFamily: fonts.mono, fontWeight: 700, fontSize: 30, color: colors.text, background: 'rgba(11,12,9,0.72)', padding: '8px 18px', borderRadius: 8 }}>ON COURT · {t.chip}</div>
      </div>
      <div style={{ position: 'absolute', left: 1180, top: 0, width: 740, height: 682, overflow: 'hidden', background: '#000', borderBottom: `4px solid ${colors.accent}`, borderLeft: `4px solid ${colors.accent}`, boxShadow: `0 0 ${hit * 50}px rgba(221,232,91,${hit * 0.5})` }}>
        <OffthreadVideo muted src={staticFile(`footage/vx-twin-app-${i}.mp4`)} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
        <div style={{ position: 'absolute', top: 18, right: 22, fontFamily: fonts.mono, fontSize: 26, fontWeight: 700, color: colors.accent, background: 'rgba(0,0,0,0.75)', padding: '6px 14px', borderRadius: 8 }}>IN THE APP</div>
      </div>
      <AbsoluteFill style={{ left: 1214, top: 682, width: 672, height: 398, justifyContent: 'center' }}>
        <Big size={80} color={t.accent ? LEMON : colors.text} style={{ ...slam, transformOrigin: 'left center' }}>{t.title}</Big>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ---------- The real CLI ----------
const Terminal: React.FC = () => {
  const frame = useCurrentFrame();
  // Each command types in, then its output appears, then the next one.
  const each = (bar(5) - bar(1)) / (v.terminal.length + 0.4);
  const rows: React.ReactNode[] = [];
  v.terminal.forEach((step, i) => {
    const start = i * each;
    if (frame < start) return;
    const typed = Math.floor(interpolate(frame, [start, start + each * 0.42], [0, step.cmd.length], clamp));
    rows.push(<div key={i}><span style={{ color: LEMON }}>PS&gt; </span><span style={{ color: colors.text }}>{step.cmd.slice(0, typed)}</span></div>);
    if (frame > start + each * 0.5) step.out.forEach((o, j) => rows.push(<div key={`${i}-${j}`} style={{ color: o.includes('TennisBuddee') ? colors.better : colors.muted, whiteSpace: 'pre', minHeight: 44 }}>{o}</div>));
  });
  return (
    <Backdrop glow={0.08}>
      <div style={{ position: 'absolute', left: 80, right: 80, top: 56, height: 700, background: '#0d0e0a', border: `1.5px solid ${colors.track}`, borderRadius: 18, overflow: 'hidden', boxShadow: '0 30px 100px rgba(0,0,0,0.6)' }}>
        <div style={{ height: 50, background: colors.card, display: 'flex', alignItems: 'center', gap: 10, padding: '0 20px' }}>
          {['#FF9A8D', LEMON, colors.better].map((c) => <div key={c} style={{ width: 14, height: 14, borderRadius: 7, background: c }} />)}
          <span style={{ marginLeft: 16, fontFamily: fonts.mono, fontSize: 22, color: colors.muted }}>Windows · Lemonade Server</span>
        </div>
        <div style={{ padding: '24px 32px', fontFamily: fonts.mono, fontSize: 34, lineHeight: 1.3 }}>{rows}</div>
      </div>
      <div style={{ position: 'absolute', left: 80, right: 80, bottom: 56, height: 230, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Big size={96} style={{ ...rise(frame, 0), textTransform: 'none' }}>{v.terminalTitle[0]}</Big>
        <Big size={96} color={LEMON} style={{ ...rise(frame, bar(3)), textTransform: 'none' }}>{v.terminalTitle[1]}</Big>
      </div>
    </Backdrop>
  );
};

// ---------- One endpoint ----------
const Node: React.FC<{ x: number; y: number; w: number; h: number; on: number; color?: string; children: React.ReactNode }> = ({ x, y, w, h, on, color = colors.accent, children }) => (
  <div style={{ position: 'absolute', left: x, top: y, width: w, height: h, opacity: on, transform: `scale(${0.94 + 0.06 * on})`, background: colors.card, border: `2px solid ${color}`, borderRadius: 18, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', textAlign: 'center', gap: 6 }}>{children}</div>
);
const Engine: React.FC = () => {
  const frame = useCurrentFrame();
  const e = v.engine;
  const step = (b: number) => interpolate(frame, [f(b), f(b) + 9], [0, 1], { ...clamp, easing: Easing.out(Easing.cubic) });
  const rows = [250, 470, 690];
  const LX = 90, LW = 440, SX = 750, SW = 540, TX = 1500, TW = 340;
  const wires: React.ReactNode[] = [];
  rows.forEach((y, i) => {
    const on = step(2 + i * 2);
    const x1 = LX + LW, y1 = y + 65, x2 = SX, y2 = 535;
    wires.push(<path key={i} d={`M ${x1} ${y1} C ${x1 + 110} ${y1}, ${x2 - 110} ${y2}, ${x2} ${y2}`} stroke={LEMON} strokeWidth={3} fill="none" opacity={on * 0.8} />);
    if (on >= 1) {
      const t = ((frame - f(2 + i * 2)) % f(2)) / f(2);
      const u = 1 - t, px = u * u * u * x1 + 3 * u * u * t * (x1 + 110) + 3 * u * t * t * (x2 - 110) + t * t * t * x2, py = u * u * u * y1 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t * t * t * y2;
      wires.push(<circle key={`p${i}`} cx={px} cy={py} r={8} fill={LEMON} />);
    }
  });
  const toolOn = step(12);
  return (
    <Backdrop glow={0.1}>
      <div style={{ position: 'absolute', left: 90, top: 56 }}>
        <Kicker style={rise(frame, 0)}>{e.kicker}</Kicker>
        <Big size={82} style={{ ...rise(frame, 3), textTransform: 'none', marginTop: 14 }}>{e.title}</Big>
      </div>
      <svg width={1920} height={1080} style={{ position: 'absolute', inset: 0 }}>
        {wires}
        <path d={`M ${SX + SW} 535 L ${TX} 535`} stroke={colors.accent} strokeWidth={3} opacity={toolOn} strokeDasharray="10 8" />
      </svg>
      {e.clients.map((c, i) => (
        <Node key={c} x={LX} y={rows[i]} w={LW} h={130} on={step(2 + i * 2)} color={colors.track}>
          <div style={{ fontFamily: fonts.sans, fontWeight: 700, fontSize: 40, color: colors.text }}>{c}</div>
        </Node>
      ))}
      <Node x={SX} y={330} w={SW} h={410} on={step(1)} color={LEMON}>
        <FruitBall morph={1} size={92} />
        <Big size={78} color={LEMON} style={{ textTransform: 'none' }}>{e.server}</Big>
        <div style={{ fontFamily: fonts.sans, fontSize: 30, color: colors.muted }}>{e.where}</div>
        <div style={{ marginTop: 10, fontFamily: fonts.mono, fontSize: 25, color: colors.text, background: '#0d0e0a', padding: '8px 14px', borderRadius: 8 }}>{e.endpoint}</div>
        <div style={{ fontFamily: fonts.mono, fontSize: 25, color: colors.better }}>{e.model}</div>
      </Node>
      <Node x={TX} y={400} w={TW} h={270} on={toolOn}>
        <div style={{ fontFamily: fonts.mono, fontSize: 30, fontWeight: 700, color: colors.accent }}>{e.tools}</div>
        <div style={{ fontFamily: fonts.sans, fontSize: 30, lineHeight: 1.2, color: colors.text, padding: '0 20px' }}>{e.toolsNote}</div>
      </Node>
      <div style={{ ...rise(frame, f(16)), position: 'absolute', left: 0, right: 0, bottom: 62, textAlign: 'center', fontFamily: fonts.sans, fontWeight: 600, fontSize: 44, color: colors.text }}>{e.foot}</div>
    </Backdrop>
  );
};

// ---------- The app on Lemonade ----------
const Demo: React.FC = () => {
  const frame = useCurrentFrame();
  const d = v.demo;
  const resultAt = Math.round(4.2 * FPS), whatIfAt = Math.round(7.6 * FPS);
  return (
    <Backdrop glow={0.14}>
      <div style={{ position: 'absolute', left: 130, top: 30, width: 536, height: 1000, borderRadius: 66, background: '#000', border: '12px solid #2b2d27', overflow: 'hidden', boxShadow: '0 30px 120px rgba(0,0,0,0.7)' }}>
        <OffthreadVideo muted src={staticFile('footage/lm-app.mp4')} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
      </div>
      <AbsoluteFill style={{ left: 760, width: 1090, justifyContent: 'center', gap: 34 }}>
        <Kicker style={rise(frame, 0)}>{d.kicker}</Kicker>
        <div style={{ ...rise(frame, 2.6 * FPS), alignSelf: 'flex-start', fontFamily: fonts.mono, fontWeight: 700, fontSize: 40, color: '#14140a', background: LEMON, padding: '10px 22px', borderRadius: 12 }}>{d.chip}</div>
        {frame < resultAt && <Big size={112} style={{ ...rise(frame, 4), textTransform: 'none' }}>{d.intro}</Big>}
        {frame >= resultAt && <Big size={100} style={{ ...rise(frame, resultAt), textTransform: 'none' }}>{d.first}</Big>}
        <div style={{ ...rise(frame, resultAt + 6), display: frame >= resultAt ? 'block' : 'none', fontFamily: fonts.sans, fontWeight: 700, fontSize: 54, color: colors.better }}>{d.stat}<span style={{ fontWeight: 500, fontSize: 32, color: colors.muted, marginLeft: 20 }}>{d.statNote}</span></div>
        {frame >= whatIfAt && <Big size={100} color={LEMON} style={{ ...rise(frame, whatIfAt), textTransform: 'none' }}>{d.second}</Big>}
      </AbsoluteFill>
      <div style={{ position: 'absolute', left: 760, right: 60, bottom: 40 }}>
        {frame >= whatIfAt - 12 && <div style={{ fontFamily: fonts.sans, fontWeight: 600, fontSize: 32, lineHeight: 1.25, color: colors.text, background: 'rgba(11,12,9,0.78)', padding: '8px 18px', borderRadius: 12 }}>{v.captions.whatif}</div>}
      </div>
    </Backdrop>
  );
};

const Answer: React.FC = () => {
  const frame = useCurrentFrame();
  const a = v.answer;
  const typed = Math.floor(interpolate(frame, [f(3), f(7)], [0, a.a.length], clamp));
  return (
    <Backdrop glow={0.1}>
      <div style={{ position: 'absolute', left: 150, right: 150, top: 80, display: 'flex', flexDirection: 'column', gap: 26 }}>
        <Kicker style={rise(frame, 0)}>{a.kicker}</Kicker>
        <div style={{ ...rise(frame, 0), alignSelf: 'flex-end', maxWidth: 1200, fontFamily: fonts.sans, fontWeight: 600, fontSize: 40, color: '#14140a', background: colors.accent, padding: '20px 30px', borderRadius: '26px 26px 6px 26px' }}>{a.q}</div>
        <div style={{ display: 'flex', gap: 16 }}>
          {a.tools.map((t, i) => <div key={t} style={{ ...rise(frame, f(1 + i)), fontFamily: fonts.mono, fontSize: 30, color: LEMON, border: `2px solid ${LEMON}`, padding: '8px 18px', borderRadius: 30 }}>{t}()</div>)}
        </div>
        <div style={{ minHeight: 280, maxWidth: 1400, fontFamily: fonts.sans, fontWeight: 500, fontSize: 44, lineHeight: 1.3, color: colors.text, background: colors.card, padding: '26px 34px', borderRadius: '26px 26px 26px 6px' }}>{a.a.slice(0, typed)}</div>
      </div>
      <div style={{ ...rise(frame, f(5)), position: 'absolute', left: 0, right: 0, bottom: 66, textAlign: 'center' }}><Big size={64} color={LEMON} style={{ textTransform: 'none', letterSpacing: -1 }}>{a.rule}</Big></div>
    </Backdrop>
  );
};

// ---------- Why it matters ----------
const Privacy: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill>
      <Shots list={[['ev-phone', 4], ['sl-watch', 4]]} />
      <AbsoluteFill style={{ background: 'rgba(5,6,3,0.5)' }} />
      <Center style={{ flexDirection: 'column', gap: 30, padding: '0 100px' }}>
        <Big size={150} color={LEMON} style={{ ...useSlam(0), textShadow: SHADOW, textTransform: 'none' }}>{v.privacy.title}</Big>
        <div style={{ ...rise(frame, f(1)), fontFamily: fonts.sans, fontWeight: 600, fontSize: 46, color: colors.text, textShadow: SHADOW }}>{v.privacy.sub}</div>
      </Center>
    </AbsoluteFill>
  );
};

const Loop: React.FC = () => {
  const frame = useCurrentFrame();
  const l = v.loop;
  const LEFT = 90, W = 1000;
  return (
    <Backdrop glow={0.1}>
      <div style={{ position: 'absolute', left: LEFT, top: 54 }}>
        <Kicker style={rise(frame, 0)}>{l.kicker}</Kicker>
        <Big size={96} style={{ ...rise(frame, 3), textTransform: 'none', marginTop: 12 }}>{l.title}</Big>
      </div>
      <div style={{ position: 'absolute', left: LEFT, right: 90, top: 236, display: 'flex', gap: 18 }}>
        {l.facts.map((t, i) => <div key={t} style={{ ...rise(frame, f(2 + i)), fontFamily: fonts.mono, fontSize: 30, color: LEMON, border: `2px solid ${LEMON}`, borderRadius: 30, padding: '8px 20px' }}>{t}</div>)}
      </div>
      <div style={{ position: 'absolute', left: LEFT, top: 340, width: W, display: 'flex', flexDirection: 'column', gap: 34 }}>
        {l.bars.map((b, i) => {
          const start = f(6 + i * 3);
          const grow = interpolate(frame, [start, start + f(2)], [0, 1], { ...clamp, easing: inOut });
          const pct = (b.n / l.of) * 100;
          return (
            <div key={b.label} style={{ opacity: frame >= start ? 1 : 0.15 }}>
              <div style={{ fontFamily: fonts.sans, fontWeight: 600, fontSize: 34, color: colors.text, marginBottom: 10 }}>{b.label}</div>
              <div style={{ position: 'relative', height: 66, background: colors.track, borderRadius: 12, overflow: 'hidden' }}>
                <div style={{ width: `${pct * grow}%`, height: '100%', background: b.best ? LEMON : colors.muted, borderRadius: 12 }} />
                <div style={{ position: 'absolute', right: 20, top: 8, fontFamily: fonts.display, fontWeight: 800, fontSize: 44, color: b.best && grow > 0.85 ? '#14140a' : colors.text }}>{(pct * grow).toFixed(1)}%<span style={{ fontFamily: fonts.mono, fontWeight: 400, fontSize: 26, color: colors.text, marginLeft: 14 }}>{Math.round(b.n * grow)}/{l.of}</span></div>
              </div>
            </div>
          );
        })}
      </div>
      <div style={{ position: 'absolute', left: 1160, right: 90, top: 340, display: 'flex', flexDirection: 'column', gap: 26 }}>
        {l.finds.map((x, i) => (
          <div key={x.big} style={{ ...rise(frame, f(12 + i * 3.5)), background: colors.card, border: `1.5px solid ${colors.track}`, borderRadius: 16, padding: '16px 24px' }}>
            <div style={{ fontFamily: fonts.display, fontWeight: 800, fontSize: 54, color: LEMON }}>{x.big}</div>
            <div style={{ fontFamily: fonts.sans, fontSize: 30, lineHeight: 1.22, color: colors.text }}>{x.small}</div>
          </div>
        ))}
      </div>
      <div style={{ position: 'absolute', left: LEFT, bottom: 46, fontFamily: fonts.sans, fontSize: 28, color: colors.muted }}>{l.foot}</div>
    </Backdrop>
  );
};

const Reach: React.FC = () => {
  const frame = useCurrentFrame();
  const r = v.reach;
  return (
    <AbsoluteFill>
      <Shots list={[['bt-code', 2.6], ['bt-code2', 2.6], ['bt-cad', 2.8]]} />
      <AbsoluteFill style={{ background: 'rgba(5,6,3,0.6)' }} />
      <AbsoluteFill style={{ justifyContent: 'center', padding: '0 110px', gap: 14 }}>
        <Big size={230} color={LEMON} style={{ ...useSlam(0), transformOrigin: 'left center', textShadow: SHADOW }}>{r.big}</Big>
        <Big size={92} style={{ ...rise(frame, 5), textTransform: 'none', textShadow: SHADOW }}>{r.title}</Big>
        <div style={{ ...rise(frame, f(2)), maxWidth: 1400, fontFamily: fonts.sans, fontWeight: 500, fontSize: 38, color: colors.text, textShadow: SHADOW, marginTop: 14 }}>{r.sub}</div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// ---------- Their words, in their own voices ----------
const Person: React.FC<{ p: (typeof v.people.list)[number] }> = ({ p }) => (
  <AbsoluteFill>
    <OffthreadVideo src={staticFile(`footage/${p.clip}.mp4`)} style={{ width: '100%', height: '100%', objectFit: 'cover', filter: GRADE }} />
    <div style={{ position: 'absolute', left: 60, top: 54, fontFamily: fonts.sans, background: 'rgba(11,12,9,0.82)', borderLeft: `8px solid ${LEMON}`, padding: '14px 30px', borderRadius: '0 14px 14px 0' }}>
      <div style={{ fontSize: 46, fontWeight: 700, color: colors.text }}>{p.name}</div>
      {p.detail && <div style={{ fontSize: 32, color: colors.muted }}>{p.detail}</div>}
    </div>
    <Line text={p.line} size={76} still />
  </AbsoluteFill>
);

const Open: React.FC = () => {
  const frame = useCurrentFrame();
  const o = v.open;
  const typed = Math.floor(interpolate(frame, [f(2), f(4)], [0, o.cmd.length], clamp));
  return (
    <Backdrop glow={0.12}>
      <AbsoluteFill style={{ justifyContent: 'center', padding: '0 110px', gap: 30 }}>
        <Kicker style={rise(frame, 0)}>{o.kicker}</Kicker>
        <Big size={104} style={{ ...rise(frame, 2), textTransform: 'none' }}>{o.title}</Big>
        <div style={{ ...rise(frame, f(1.5)), alignSelf: 'flex-start', fontFamily: fonts.mono, fontSize: 52, color: colors.text, background: '#0d0e0a', border: `2px solid ${LEMON}`, borderRadius: 14, padding: '18px 30px', minWidth: 880 }}><span style={{ color: LEMON }}>$ </span>{o.cmd.slice(0, typed)}</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {o.items.map((t, i) => <div key={t} style={{ ...rise(frame, f(4.5 + i)), fontFamily: fonts.sans, fontWeight: 600, fontSize: 38, color: colors.text }}><span style={{ color: LEMON, marginRight: 14 }}>●</span>{t}</div>)}
        </div>
        <div style={{ ...rise(frame, f(8)), fontFamily: fonts.sans, fontWeight: 700, fontSize: 42, color: LEMON, marginTop: 8 }}>{o.next}</div>
      </AbsoluteFill>
    </Backdrop>
  );
};

const Tagline: React.FC = () => {
  const frame = useCurrentFrame();
  const second = useSlam(f(2));
  return (
    <AbsoluteFill style={{ background: colors.bg }}>
      <Center style={{ flexDirection: 'column', gap: 26 }}>
        <Big size={118} style={{ ...useSlam(0), textTransform: 'none' }}>{v.end.first}</Big>
        {frame >= f(2) && <Big size={170} color={LEMON} style={{ ...second, textTransform: 'none' }}>{v.end.second}</Big>}
      </Center>
    </AbsoluteFill>
  );
};

const Url: React.FC = () => {
  const frame = useCurrentFrame();
  return <div style={{ ...rise(frame, f(5)), position: 'absolute', left: 860, top: 800, fontFamily: fonts.mono, fontSize: 34, color: colors.text }}>{v.end.url}</div>;
};

// ---------- Sound ----------
const CUES: (Omit<Cue, 'at'> & { beat: number })[] = [
  ...[20, 21, 22, 23].map((beat) => ({ sfx: 'tap' as const, beat, volume: 0.5 })),
  { sfx: 'riser', beat: 24, volume: 0.3 }, { sfx: 'impact', beat: 24, volume: 1 }, { sfx: 'chime', beat: 24.2, volume: 0.55 },
  { sfx: 'whoosh', beat: 27.7, volume: 0.25 }, { sfx: 'whoosh', beat: 54, volume: 0.3 },
  { sfx: 'impact', beat: 88, volume: 0.7 }, { sfx: 'impact', beat: 92, volume: 0.6 }, { sfx: 'impact', beat: 96, volume: 0.6 },
  { sfx: 'swipe', beat: 104, volume: 0.5 }, ...[106, 108, 110, 112].map((beat) => ({ sfx: 'blip' as const, beat, volume: 0.35 })),
  { sfx: 'swipe', beat: 120, volume: 0.5 }, ...[122, 124, 126].map((beat) => ({ sfx: 'ping' as const, beat, volume: 0.4 })),
  { sfx: 'swipe', beat: 144, volume: 0.5 }, { sfx: 'ping', beat: 170, volume: 0.45 }, { sfx: 'whoosh', beat: 175.7, volume: 0.3 },
  { sfx: 'impact', beat: 176, volume: 0.7 }, { sfx: 'swipe', beat: 184, volume: 0.5 },
  ...[190, 193, 196].map((beat) => ({ sfx: 'blip' as const, beat, volume: 0.4 })), { sfx: 'whoosh', beat: 207.7, volume: 0.3 }, { sfx: 'impact', beat: 208, volume: 0.8 },
  { sfx: 'swipe', beat: 228, volume: 0.45 }, { sfx: 'tap', beat: 240, volume: 0.6 }, { sfx: 'impact', beat: 242, volume: 0.8 },
  { sfx: 'whoosh', beat: 247.7, volume: 0.3 }, { sfx: 'boom', beat: 252, volume: 0.45 },
];
const duck = makeDuck(CUES, f);

// Voice over the song, in frames: where it plays, and how long.
const VOICE = [
  { src: 'open', at: 8, len: 4.31 * FPS },
  { src: 'reveal', at: f(12) + 6, len: 2.87 * FPS },
  { src: 'hardware', at: bar(14), len: 12.53 * FPS },
  { src: 'esp32', at: bar(21), len: 3.42 * FPS },
  { src: 'whatif', at: bar(37) + Math.round(4.6 * FPS), len: 6.11 * FPS },
];
const TALK = { at: bar(9, 1), len: 8.72 * FPS };
const PEOPLE = { at: bar(55, 1.5), to: bar(58) };
const underVoice = (fr: number) => {
  const spans = [...VOICE.map((x) => [x.at, x.at + x.len]), [TALK.at, TALK.at + TALK.len], [PEOPLE.at, PEOPLE.to]];
  let w = 0;
  for (const [a, b] of spans) w = Math.max(w, interpolate(fr, [a - 8, a, b, b + 10], [0, 1, 1, 0], clamp));
  return 1 - w * (1 - v.song.under);
};

export const LemonadeCut: React.FC = () => {
  const c = v.captions;
  const s = (x: number) => Math.round(x * FPS);
  const musicEnd = bar(v.bars);
  return (
    <AbsoluteFill style={{ background: colors.bg, color: colors.text, fontFamily: fonts.sans, overflow: 'hidden' }}>
      {/* Six bars of bass: the question. */}
      <At n={1} to={6}>
        <Shots list={[['lm-serve-hero', 8, [1, 1.08]], ['sl-forehand', 4], ['hw-creep', 4, [1.02, 1.1]], ['hw-grip', 2], ['hw-xray', 2]]} />
        <Caption text={c.open} from={6} to={8 + s(4.4)} />
        <Caption text={c.reveal} from={f(12) + 4} to={f(12) + 6 + s(2.95)} />
      </At>
      <At n={6} to={7}><Question /></At>
      {/* The drop: the ball becomes a lemon. */}
      <At n={7} to={8}><LemonDrop /></At>
      <At n={8} to={9} toBeat={1}>
        <Shots list={[['rt-swing', 2, [1.14, 1]], ['ev-serve', 2], ['ev-toss2', 1]]} />
        <Line text={v.promise} size={124} color={LEMON} />
      </At>

      {/* The person, the handle, the arm. */}
      <Sequence from={TALK.at} durationInFrames={bar(14) - TALK.at}>
        <OffthreadVideo src={staticFile('footage/lm-talk.mp4')} style={{ width: '100%', height: '100%', objectFit: 'cover', filter: GRADE }} />
        <div style={{ position: 'absolute', left: 60, top: 54, fontFamily: fonts.sans, background: 'rgba(11,12,9,0.82)', borderLeft: `8px solid ${colors.accent}`, padding: '14px 30px', borderRadius: '0 14px 14px 0' }}>
          <div style={{ fontSize: 46, fontWeight: 700, color: colors.text }}>Quentin Lynch</div>
          <div style={{ fontSize: 32, color: colors.muted }}>Built Tennis Buddee</div>
        </div>
        <Caption text={c.talk[0].text} to={s(c.talk[0].to)} />
        <Caption text={c.talk[1].text} from={s(c.talk[0].to)} />
      </Sequence>
      <At n={14} to={21}>
        <Sequence durationInFrames={f(16)}><Handle /></Sequence>
        <Sequence from={f(16)}><Shots list={[['bt-pcb', 2], ['bt-solder', 2], ['rt-handle', 3], ['rt-racket', 3], ['rt-wide', 2]]} /></Sequence>
        {c.hardware.map((x, i) => <Caption key={i} text={x.text} from={i ? s(c.hardware[i - 1].to) : 0} to={s(x.to)} />)}
      </At>
      <At n={21} to={23}>
        <Shots list={[['rt-swing', 3], ['rt-arm', 3], ['rh-handle', 2]]} />
        <div style={{ position: 'absolute', right: 60, top: 54, fontFamily: fonts.mono, fontWeight: 700, fontSize: 32, color: '#14140a', background: colors.accent, padding: '10px 20px', borderRadius: 10 }}>TESTED ON A ROBOT ARM</div>
        <Caption text={c.esp32} to={s(3.5)} />
      </At>
      <At n={23} to={24} toBeat={1.5}><Twin i={0} /></At>
      <At n={24} beat={1.5} to={25} toBeat={3}><Twin i={1} /></At>
      <At n={25} beat={3} to={27}><Twin i={2} /></At>

      {/* Lemonade itself. */}
      <At n={27} to={31}><Terminal /></At>
      <At n={31} to={37}><Engine /></At>
      <At n={37} to={43}><Demo /></At>
      <At n={43} to={45}><Answer /></At>
      <At n={45} to={47}><Privacy /></At>
      <At n={47} to={53}><Loop /></At>
      <At n={53} to={55}><Reach /></At>

      {/* People, the repo, the end. */}
      <At n={55} to={55} toBeat={1.5}>
        <Clip name="hw-lineup" len={f(1.5)} />
        <Line text={v.people.lead} size={120} color={LEMON} />
      </At>
      <Sequence from={bar(55, 1.5)} durationInFrames={f(5.5)}><Person p={v.people.list[0]} /></Sequence>
      <Sequence from={bar(55, 7)} durationInFrames={bar(58) - bar(55, 7)}><Person p={v.people.list[1]} /></Sequence>
      <At n={58} to={61}><Open /></At>
      <At n={61} to={62}><Tagline /></At>
      <Sequence from={bar(62)}>
        <RacketFinale beat={BEAT} finish="red" name={v.end.name} tagline={v.end.tag} cta={v.end.cta} room="hw-net" roomLen={72} aura={LEMON} glow={() => 0.3} />
        <Url />
      </Sequence>

      <Flash at={bar(7)} len={10} peak={0.85} color={LEMON} />
      <Vignette strength={0.28} />
      <Grain />

      <Audio
        src={staticFile(v.song.src)}
        trimBefore={Math.round(v.song.firstNote * FPS)}
        volume={(fr) => v.song.volume * duck(fr) * underVoice(fr) * interpolate(fr, [musicEnd - 3, musicEnd + 36], [1, 0], clamp)}
      />
      {VOICE.map((x) => <Sequence key={x.src} from={x.at} layout="none"><Audio src={staticFile(`audio/vo-lemonade/${x.src}.wav`)} volume={1.15} /></Sequence>)}
      {CUES.map((cue, i) => <Effect key={i} cue={{ ...cue, at: 0 }} frame={f(cue.beat)} />)}
    </AbsoluteFill>
  );
};

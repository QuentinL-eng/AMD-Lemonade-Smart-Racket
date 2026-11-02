// Shared pieces of the footage + CGI X cuts (RobotHype, BuildLog, EverySwing, Possessed):
// beat timing, the one grade every clip and CGI layer gets, whip-pan cuts, HUD bits and the
// music ducking under loud effects.
import React from 'react';
import { AbsoluteFill, Easing, Img, OffthreadVideo, Sequence, interpolate, staticFile, useCurrentFrame } from 'remotion';
import { colors } from '../config/brand';
import type { Cue } from '../config/sound';

export const FPS = 30;
export type V3 = [number, number, number];
export const clamp = { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' } as const;
export const inOut = Easing.inOut(Easing.cubic);
export const mix = (a: V3, b: V3, t: number): V3 => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];

// One look for all footage: a little more contrast, a little less colour, slightly warm.
export const GRADE = 'contrast(1.12) saturate(0.84) brightness(0.9) sepia(0.06)';
export const SHADOW = '0 8px 48px rgba(0,0,0,0.55)';

/** Beat clock for a song: frames per beat, beat -> frame, an on-beat pulse and a Shot spanning beats. */
export const beatClock = (bpm: number) => {
  const BEAT = (FPS * 60) / bpm;
  const f = (beat: number) => Math.round(beat * BEAT);
  /** 1 on each beat, decaying fast. */
  const pulse = (frame: number, every = 1) => Math.exp(-((frame % (BEAT * every)) / BEAT) * 6);
  const Shot: React.FC<{ at: readonly number[]; children: React.ReactNode }> = ({ at, children }) => (
    <Sequence from={f(at[0])} durationInFrames={f(at[1]) - f(at[0])}>{children}</Sequence>
  );
  return { BEAT, f, pulse, Shot };
};

/** A clip from public/footage, graded, with a zoom across `len` frames. */
export const Clip: React.FC<{ name: string; len: number; zoom?: [number, number]; origin?: string; blur?: number; grade?: string; ease?: (t: number) => number; style?: React.CSSProperties }> = ({ name, len, zoom = [1.06, 1], origin = '50% 50%', blur = 0, grade = GRADE, ease, style }) => {
  const frame = useCurrentFrame();
  const z = interpolate(frame, [0, len], zoom, { ...clamp, easing: ease });
  return (
    <AbsoluteFill style={{ overflow: 'hidden', ...style }}>
      <OffthreadVideo
        src={staticFile(`footage/${name}.mp4`)}
        muted
        style={{ width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${z})`, transformOrigin: origin, filter: blur ? `${grade} blur(${blur}px)` : grade }}
      />
    </AbsoluteFill>
  );
};

/** A still of the real location, blurred and darkened: the room behind the CGI. */
export const Plate: React.FC<{ name: string; blur?: number; dim?: number; zoom?: number; grade?: string }> = ({ name, blur = 22, dim = 0.55, zoom = 1.15, grade = GRADE }) => (
  <AbsoluteFill style={{ overflow: 'hidden' }}>
    <Img src={staticFile(`footage/${name}.jpg`)} style={{ width: '100%', height: '100%', objectFit: 'cover', filter: `${grade} blur(${blur}px)`, transform: `scale(${zoom})` }} />
    <AbsoluteFill style={{ background: `rgba(11,12,9,${dim})` }} />
  </AbsoluteFill>
);

/** Darkens the frame centre a touch so white type reads over bright footage. */
export const Shade: React.FC<{ amount?: number }> = ({ amount = 0.35 }) => (
  <AbsoluteFill style={{ background: `radial-gradient(ellipse 60% 50% at 50% 50%, rgba(0,0,0,${amount}), rgba(0,0,0,${amount * 0.4}) 70%)` }} />
);

/** Lime flash that decays over `len` frames from local frame `at`. */
export const Flash: React.FC<{ at: number; len?: number; peak?: number; color?: string }> = ({ at, len = 6, peak = 0.7, color = colors.accent }) => {
  const frame = useCurrentFrame();
  const o = frame < at ? 0 : peak * Math.exp(-(frame - at) / (len / 3));
  return <AbsoluteFill style={{ background: `radial-gradient(circle at 50% 50%, #ffffff, ${color})`, opacity: o, mixBlendMode: 'screen', pointerEvents: 'none' }} />;
};

/** Whip-pan cut: the outgoing shot smears off to the left over its last frames... */
export const whipOut = (frame: number, end: number, len = 5): React.CSSProperties => {
  const t = interpolate(frame, [end - len, end], [0, 1], { ...clamp, easing: Easing.in(Easing.cubic) });
  return t ? { transform: `translateX(${-t * 340}px) scaleX(${1 + t * 0.15})`, filter: `blur(${t * 24}px)` } : {};
};
/** ...and the incoming one smears in from the right, so the move reads as one camera. */
export const whipIn = (frame: number, start: number, len = 6): React.CSSProperties => {
  const t = interpolate(frame, [start, start + len], [1, 0], { ...clamp, easing: Easing.out(Easing.cubic) });
  return t ? { transform: `translateX(${t * 340}px) scaleX(${1 + t * 0.15})`, filter: `blur(${t * 24}px)` } : {};
};

/** Camera viewfinder corners. */
export const Brackets: React.FC<{ color?: string }> = ({ color = colors.text }) => {
  const L = 70, W = 4, I = 70;
  const corner = (s: React.CSSProperties) => <div style={{ position: 'absolute', width: L, height: L, borderColor: color, borderStyle: 'solid', borderWidth: 0, opacity: 0.85, ...s }} />;
  return (
    <AbsoluteFill>
      {corner({ left: I, top: I, borderLeftWidth: W, borderTopWidth: W })}
      {corner({ right: I, top: I, borderRightWidth: W, borderTopWidth: W })}
      {corner({ left: I, bottom: I, borderLeftWidth: W, borderBottomWidth: W })}
      {corner({ right: I, bottom: I, borderRightWidth: W, borderBottomWidth: W })}
    </AbsoluteFill>
  );
};

/** One vignette over real and CGI alike. */
export const Vignette: React.FC<{ strength?: number }> = ({ strength = 0.55 }) => (
  <AbsoluteFill style={{ background: `radial-gradient(ellipse 85% 80% at 50% 50%, transparent 55%, rgba(0,0,0,${strength}))`, pointerEvents: 'none' }} />
);

// The songs are mastered to 0 dBFS and the whoosh/riser/boom files peak near it too, so the music
// ducks under each of those hits (in fast, out over a few frames) instead of clipping.
const LOUD = new Set(['whoosh', 'riser', 'boom', 'impact']);
export const makeDuck = (cues: (Omit<Cue, 'at'> & { beat: number })[], f: (beat: number) => number) => {
  const hits = cues.filter((c) => LOUD.has(c.sfx)).map((c) => ({ at: f(c.beat), depth: 0.5 * Math.min(1, (c.volume ?? 1) / 0.6) }));
  return (fr: number) => {
    let d = 0;
    for (const { at, depth } of hits) {
      const dt = fr - at;
      const env = dt < -12 ? 0 : dt < -4 ? (dt + 12) / 8 : dt < 6 ? 1 : Math.exp(-(dt - 6) / 6);
      d = Math.max(d, depth * env);
    }
    return 1 - d;
  };
};

// Text and cards over a shot, placed per entry in config/timeline.ts. Words come from copy.overlays,
// so they can be rendered with a transparent background for an outside editor (scripts/render-clips.mjs).
import React from 'react';
import { AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig } from 'remotion';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import type { Overlay } from '../config/timeline';
import { enter, pop, ramp } from '../lib/anim';

/** Fades out over the last 8 frames of an overlay. */
const useOut = (frames: number) => 1 - ramp(useCurrentFrame(), frames - 8, frames);

const Headline: React.FC<{ lines: string[]; frames: number }> = ({ lines, frames }) => {
  const frame = useCurrentFrame();
  const out = useOut(frames);
  return (
    <AbsoluteFill style={{ justifyContent: 'center', padding: '0 110px', gap: 10, opacity: out }}>
      <div style={{ ...enter(frame, 2, 12), fontFamily: fonts.display, fontSize: 88, fontWeight: 700, letterSpacing: -1.5, color: colors.text, textShadow: '0 4px 40px rgba(0,0,0,0.7)' }}>{lines[0]}</div>
      <div style={{ ...enter(frame, 26, 12), fontFamily: fonts.display, fontSize: 110, fontWeight: 800, letterSpacing: -2, color: colors.accent, textShadow: '0 4px 40px rgba(0,0,0,0.7)' }}>{lines[1]}</div>
    </AbsoluteFill>
  );
};

// The Live tab's shot card, flying in over real footage.
const ShotCard: React.FC<{ frames: number }> = ({ frames }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = pop(frame, 0, fps);
  const shot = copy.coldOpenShot;
  const speed = Math.round(shot.speed * ramp(frame, 2, 18));
  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'flex-end', padding: '0 90px 90px', opacity: useOut(frames) }}>
      <div style={{ width: 620, padding: '26px 34px', borderRadius: 30, background: 'rgba(23,25,19,0.94)', border: `3px solid ${colors.better}`, boxShadow: '0 16px 70px rgba(0,0,0,0.6)', color: colors.text, fontFamily: fonts.sans, opacity: s, transform: `translateX(${(1 - s) * 90}px) scale(${0.92 + 0.08 * s})` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, fontSize: 38, fontWeight: 700 }}>
          {shot.stroke}
          <span style={{ fontSize: 26, color: colors.better, background: 'rgba(94,220,138,0.15)', padding: '4px 14px', borderRadius: 20 }}>{shot.badge}</span>
          {shot.sample && <span style={{ fontSize: 22, color: '#11130c', background: colors.worse, padding: '4px 12px', borderRadius: 8, marginLeft: 'auto' }}>SAMPLE</span>}
        </div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
          <span style={{ fontFamily: fonts.display, fontSize: 150, fontWeight: 800, lineHeight: 1.05 }}>{speed}</span>
          <span style={{ fontSize: 44, color: colors.muted }}>{shot.unit}</span>
        </div>
        <div style={{ fontSize: 31, color: colors.muted }}>{shot.sub}</div>
      </div>
    </AbsoluteFill>
  );
};

// A pill centred on (x, y).
const Badge: React.FC<{ text: string; frames: number; x?: number; y?: number }> = ({ text, frames, x = 960, y = 140 }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ opacity: useOut(frames) }}>
      <div style={{ position: 'absolute', left: x, top: y, transform: 'translate(-50%,-50%)' }}>
        <div style={{ ...enter(frame, 0, 12), fontFamily: fonts.sans, fontSize: 28, fontWeight: 700, whiteSpace: 'nowrap', color: '#11130c', background: colors.accent, padding: '10px 26px', borderRadius: 40 }}>{text}</div>
      </div>
    </AbsoluteFill>
  );
};

// Big side notes beside the phone. One at a time, stacking up.
const Callouts: React.FC<{ lines: string[]; every: number }> = ({ lines, every }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const current = Math.min(lines.length - 1, Math.floor(frame / (every * fps)));
  return (
    <AbsoluteFill style={{ justifyContent: 'center', left: 980, width: 860, gap: 34, paddingBottom: 70 }}>
      {lines.map((l, i) => (
        <div key={l} style={{ ...enter(frame, i * every * fps, 14), fontFamily: fonts.display, fontSize: 66, fontWeight: 700, letterSpacing: -1, lineHeight: 1.1, color: i === current ? colors.accent : colors.muted }}>{l}</div>
      ))}
    </AbsoluteFill>
  );
};

const LowerThird: React.FC<{ name: string; detail: string; frames: number }> = ({ name, detail, frames }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ justifyContent: 'flex-end', padding: '0 0 170px 90px', opacity: useOut(frames) }}>
      <div style={{ ...enter(frame, 0, 10), width: 'fit-content', fontFamily: fonts.sans, background: 'rgba(11,12,9,0.82)', borderLeft: `6px solid ${colors.accent}`, padding: '14px 30px', borderRadius: '0 14px 14px 0' }}>
        <div style={{ fontSize: 40, fontWeight: 700, color: colors.text }}>{name}</div>
        {detail && <div style={{ fontSize: 28, color: colors.muted }}>{detail}</div>}
      </div>
    </AbsoluteFill>
  );
};

/** Every overlay of one entry, on a transparent background. */
export const OverlayLayer: React.FC<{ overlays: Overlay[] }> = ({ overlays }) => {
  const { fps, durationInFrames } = useVideoConfig();
  return (
    <AbsoluteFill>
      {overlays.map((o, i) => {
        const from = Math.round(o.at * fps);
        const frames = 'seconds' in o ? Math.round(o.seconds * fps) : durationInFrames - from;
        return (
          <Sequence key={i} from={from} durationInFrames={frames} layout="none">
            {o.type === 'headline' && <Headline lines={copy.overlays[o.text]} frames={frames} />}
            {o.type === 'shotCard' && <ShotCard frames={frames} />}
            {o.type === 'badge' && <Badge text={copy.overlays[o.text]} frames={frames} x={o.x} y={o.y} />}
            {o.type === 'callouts' && <Callouts lines={copy.overlays[o.text]} every={o.every} />}
            {o.type === 'lowerThird' && <LowerThird {...copy.overlays[o.text]} frames={frames} />}
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

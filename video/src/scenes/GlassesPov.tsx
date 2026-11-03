import React from 'react';
import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import { Vignette } from '../hype/kit';
import { enter, pop, ramp } from '../lib/anim';

const c = copy.glassesPov;
// Frames a shot lands on the HUD
const HITS = [45, 135];

// Looking through Meta Ray-Ban Display: the fields of GlassesHUD.swift in the right lens, over the court.
export const GlassesPov: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const hits = HITS.filter((h) => frame >= h).length;
  const last = hits ? HITS[hits - 1] : -1;
  const s = hits ? pop(frame, last, fps) : 1;
  const glow = hits ? Math.exp(-(frame - last) / 14) : 0;
  const drift = 1.08 - 0.05 * ramp(frame, 0, 210, (x) => x);
  return (
    <AbsoluteFill style={{ background: '#000', fontFamily: fonts.sans }}>
      <AbsoluteFill style={{ overflow: 'hidden' }}>
        <Img src={staticFile('footage/ev-plate-court.jpg')} style={{ width: '100%', height: '100%', objectFit: 'cover', transform: `scale(${drift})`, filter: 'blur(1.4px) brightness(0.8) saturate(0.95)' }} />
      </AbsoluteFill>
      <AbsoluteFill style={{ background: 'radial-gradient(ellipse 88% 96% at 54% 50%, rgba(0,0,0,0) 54%, rgba(0,0,0,0.3) 84%, rgba(0,0,0,0.62) 100%)' }} />
      <Vignette strength={0.3} />

      <div style={{ position: 'absolute', left: 1080, top: 190, width: 620, color: '#fff', display: 'flex', flexDirection: 'column', gap: 10, padding: '30px 36px', borderRadius: 30, background: 'rgba(12,14,12,0.72)', backdropFilter: 'blur(10px)', border: `2px solid rgba(94,220,138,${0.25 + glow * 0.75})`, boxShadow: `0 0 ${20 + glow * 60}px rgba(94,220,138,${0.15 + glow * 0.5})` }}>
        <div style={{ fontSize: 28, color: 'rgba(255,255,255,0.65)' }}>{c.elapsed}</div>
        {hits === 0 ? (
          <>
            <div style={{ fontFamily: fonts.display, fontSize: 76, fontWeight: 800 }}>{c.idleTitle}</div>
            <div style={{ fontSize: 34, color: 'rgba(255,255,255,0.7)' }}>{c.idleDetail}</div>
          </>
        ) : (
          <div style={{ transform: `scale(${0.94 + 0.06 * s})`, transformOrigin: 'left center' }}>
            <div style={{ fontFamily: fonts.display, fontSize: 76, fontWeight: 800 }}>{c.stroke}</div>
            <div style={{ fontSize: 38, fontWeight: 600, color: colors.better }}>{c.detailSweet}</div>
          </div>
        )}
        <div style={{ fontSize: 28, color: 'rgba(255,255,255,0.7)', marginTop: 10 }}>{c.shots + hits} shots · {c.sweetPercent}% sweet spot</div>
        <div style={{ fontSize: 34, fontWeight: 600 }}>{c.score}</div>
        <div style={{ fontSize: 28, color: 'rgba(255,255,255,0.7)' }}>{c.points}</div>
        <div style={{ fontSize: 28, color: colors.accent, fontWeight: 600 }}>{c.drillName} {c.drillStart + hits}/{c.drillTarget}</div>
      </div>

      <div style={{ ...enter(frame, 8), position: 'absolute', left: 70, top: 60, fontSize: 26, fontWeight: 600, color: colors.text, background: 'rgba(11,12,9,0.72)', padding: '10px 20px', borderRadius: 12 }}>{c.badge}</div>
      <div style={{ ...enter(frame, 14), position: 'absolute', left: 70, top: 118, fontSize: 22, color: colors.muted, background: 'rgba(11,12,9,0.72)', padding: '7px 16px', borderRadius: 10 }}>{c.tag}</div>
    </AbsoluteFill>
  );
};

import React from 'react';
import { AbsoluteFill, Img, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';
import { Backdrop, Title } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import { enter, pop } from '../lib/anim';

// One headline + the real tagline from the website.
export const Endcard: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const s = pop(frame, 4, fps);
  return (
    <Backdrop glow={0.2}>
      <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', gap: 22 }}>
        <Img src={staticFile('img/icon.png')} style={{ width: 170, height: 170, borderRadius: 40, transform: `scale(${s})` }} />
        <Title size={130} style={enter(frame, 12)}>{copy.endcard.name}</Title>
        <div style={{ ...enter(frame, 24), fontSize: 52, color: colors.accent, fontWeight: 600 }}>{copy.endcard.tagline}</div>
        <div style={{ ...enter(frame, 40), fontFamily: fonts.display, fontSize: 60, fontWeight: 700, marginTop: 26 }}>{copy.endcard.site}</div>
        <div style={{ ...enter(frame, 50), fontSize: 32, color: colors.muted }}>{copy.endcard.tryIt}</div>
      </AbsoluteFill>
      <AbsoluteFill style={{ justifyContent: 'flex-end', alignItems: 'center', paddingBottom: 40 }}>
        <div style={{ ...enter(frame, 56), fontSize: 26, color: colors.muted }}>{copy.endcard.footer}</div>
      </AbsoluteFill>
    </Backdrop>
  );
};

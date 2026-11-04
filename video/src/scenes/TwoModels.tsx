import React from 'react';
import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { Backdrop, Card, Kicker, Title } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import { enter } from '../lib/anim';

const c = copy.twoModels;
// Beat timings (frames): the racket card lands on "on the racket", the app card on "in the app".
const T = { racket: 16, app: 135 };

const Side: React.FC<{ side: typeof c.racket; at: number; accent: string }> = ({ side, at, accent }) => {
  const frame = useCurrentFrame();
  return (
    <Card style={{ ...enter(frame, at), flex: 1, display: 'flex', flexDirection: 'column', gap: 26, padding: 44 }}>
      <div style={{ fontSize: 32, fontWeight: 600, color: accent }}>{side.where}</div>
      <div style={{ fontFamily: fonts.display, fontSize: 84, fontWeight: 800, lineHeight: 1.02, letterSpacing: -2 }}>{side.name}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 18, marginTop: 10 }}>
        {side.lines.map((line, i) => (
          <div key={line} style={{ ...enter(frame, at + 14 + i * 10), fontSize: 44, lineHeight: 1.2, color: colors.muted }}>{line}</div>
        ))}
      </div>
    </Card>
  );
};

// What runs where: our own model on the ESP32, open Muse Spark on Baseten in the app.
export const TwoModels: React.FC = () => {
  const frame = useCurrentFrame();
  return (
    <Backdrop glow={0.08}>
      <AbsoluteFill style={{ padding: '80px 100px 170px', gap: 40 }}>
        <div>
          <Kicker style={enter(frame, 4)}>{c.kicker}</Kicker>
          <Title size={76} style={{ ...enter(frame, 10), marginTop: 10 }}>{c.title}</Title>
        </div>
        <div style={{ display: 'flex', gap: 32, flex: 1 }}>
          <Side side={c.racket} at={T.racket} accent={colors.accent} />
          <Side side={c.app} at={T.app} accent={colors.accent} />
        </div>
      </AbsoluteFill>
    </Backdrop>
  );
};

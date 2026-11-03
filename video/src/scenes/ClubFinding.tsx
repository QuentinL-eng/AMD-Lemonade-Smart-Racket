import React from 'react';
import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { Backdrop, Card, Kicker, Title } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import facts from '../config/generated/facts.json';
import { enter, ramp, rand } from '../lib/anim';

const c = copy.clubFinding;
// Beat timings (frames)
const T = { stream: 16, stat: 40, pivot: 150, steps: 172, stepEvery: 14 };
const COLS = 40, ROWS = 22, CELL = 21;

// The Oct 28 club session: most of the raw stream never arrived, so the shot moved onto the racket.
export const ClubFinding: React.FC = () => {
  const frame = useCurrentFrame();
  const sweep = ramp(frame, T.stream, T.pivot - 20, (x) => x);
  const after = ramp(frame, T.pivot, T.pivot + 16);
  const percent = Math.round(c.arrivedPercent * ramp(frame, T.stat, T.pivot - 40));
  return (
    <Backdrop glow={0.08}>
      <AbsoluteFill style={{ padding: '0 0 60px 110px', width: 810, gap: 18, justifyContent: 'center' }}>
        <Kicker style={enter(frame, 4)}>{c.kicker} · {facts.clubMinutes} minutes</Kicker>
        <div style={{ position: 'relative', height: 250 }}>
          <Title size={76} style={{ position: 'absolute', opacity: (1 - after) * ramp(frame, 10, 24) }}>{c.title}</Title>
          <Title size={76} style={{ position: 'absolute', opacity: after, color: colors.accent }}>{c.pivot}</Title>
        </div>
        <div style={{ ...enter(frame, T.stat), fontFamily: fonts.display, fontSize: 170, fontWeight: 800, lineHeight: 1, color: colors.accent }}>{percent}%</div>
        <div style={{ ...enter(frame, T.stat + 8), fontSize: 36, color: colors.muted }}>{c.arrivedLabel}</div>
      </AbsoluteFill>

      {/* One cell per slice of the stream, in time order: lit only if it arrived. */}
      <svg width={COLS * CELL} height={ROWS * CELL} style={{ position: 'absolute', left: 980, top: 290, opacity: 1 - after }}>
        {Array.from({ length: COLS * ROWS }, (_, i) => {
          const x = i % COLS, y = Math.floor(i / COLS);
          const seen = x / COLS < sweep;
          const arrived = rand(i * 3 + 11) < c.arrivedPercent / 100;
          return <rect key={i} x={x * CELL} y={y * CELL} width={CELL - 4} height={CELL - 4} rx={3} fill={!seen ? colors.card : arrived ? colors.accent : colors.track} />;
        })}
      </svg>

      <AbsoluteFill style={{ left: 980, width: 840, justifyContent: 'center', gap: 24, paddingBottom: 60 }}>
        {c.steps.map((s, i) => {
          const at = T.steps + i * T.stepEvery;
          return (
            <Card key={s.big} style={{ ...enter(frame, at), display: 'flex', alignItems: 'center', gap: 30, padding: '24px 32px' }}>
              <span style={{ fontFamily: fonts.display, fontSize: 68, fontWeight: 800, color: colors.accent, minWidth: 320, lineHeight: 1 }}>{s.big}</span>
              <span style={{ fontSize: 32, color: colors.text, lineHeight: 1.2 }}>{s.small}</span>
            </Card>
          );
        })}
      </AbsoluteFill>
    </Backdrop>
  );
};

import React from 'react';
import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { Backdrop, Card, Kicker, Title } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import facts from '../config/generated/facts.json';
import { enter, ramp } from '../lib/anim';

const c = copy.evidence;
// Beat timings (frames)
const T = { parity: 20, distance: 60, whatIf: 100, source: 170 };

const CARD: React.CSSProperties = { flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', padding: 36 };
const LABEL: React.CSSProperties = { fontSize: 38, fontWeight: 700, lineHeight: 1.15 };
const DETAIL: React.CSSProperties = { fontSize: 31, color: colors.muted, lineHeight: 1.3 };

const Big: React.FC<{ children: React.ReactNode; color?: string }> = ({ children, color = colors.text }) => (
  <div style={{ fontFamily: fonts.display, fontSize: 112, fontWeight: 800, lineHeight: 1, color, letterSpacing: -3 }}>{children}</div>
);

const Bar: React.FC<{ value: number; max: number; color: string; t: number; label: string }> = ({ value, max, color, t, label }) => (
  <div style={{ marginTop: 20 }}>
    <div style={{ fontSize: 28, color: colors.muted, lineHeight: 1.2 }}>{label}</div>
    <div style={{ height: 20, background: colors.track, borderRadius: 10, marginTop: 8 }}>
      <div style={{ height: '100%', width: `${((value * t) / max) * 100}%`, background: color, borderRadius: 10 }} />
    </div>
  </div>
);

// Measured results only, each with its comparison or its caveat on screen.
export const Evidence: React.FC = () => {
  const frame = useCurrentFrame();
  const { parityClips: clips, sweetSpot } = facts;
  const grow = ramp(frame, T.distance + 10, T.distance + 40);
  return (
    <Backdrop glow={0.08}>
      <AbsoluteFill style={{ padding: '70px 100px 150px', gap: 30 }}>
        <div>
          <Kicker style={enter(frame, 4)}>{c.kicker}</Kicker>
          <Title size={76} style={{ ...enter(frame, 10), marginTop: 10 }}>{c.title}</Title>
        </div>
        <div style={{ display: 'flex', gap: 28, flex: 1 }}>
          <Card style={{ ...enter(frame, T.parity), ...CARD }}>
            <div style={LABEL}>{c.parity.label}</div>
            <Big color={colors.better}>{Math.round(clips * ramp(frame, T.parity + 8, T.parity + 34))}/{clips}</Big>
            <div style={DETAIL}>{c.parity.detail}</div>
          </Card>
          <Card style={{ ...enter(frame, T.distance), ...CARD }}>
            <div style={LABEL}>{c.distance.label}</div>
            <Big color={colors.better}>{sweetSpot.errorCm} cm</Big>
            <div>
              <Bar value={sweetSpot.errorCm} max={3} color={colors.better} t={grow} label={`${c.distance.detail}: ${sweetSpot.errorCm} cm`} />
              <Bar value={c.distance.medianCm} max={3} color="#5c6040" t={grow} label={`${c.distance.medianLabel}: ${c.distance.medianCm} cm`} />
            </div>
          </Card>
          <Card style={{ ...enter(frame, T.whatIf), ...CARD }}>
            <div style={LABEL}>{c.whatIf.label}</div>
            <Big color={colors.better}>{(c.whatIf.percent * ramp(frame, T.whatIf + 8, T.whatIf + 34)).toFixed(1)}%</Big>
            <div style={DETAIL}>{c.whatIf.detail}</div>
          </Card>
        </div>
        <div style={{ ...enter(frame, T.source), fontFamily: fonts.mono, fontSize: 24, color: colors.muted }}>{c.source}</div>
      </AbsoluteFill>
    </Backdrop>
  );
};

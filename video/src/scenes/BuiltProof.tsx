import React from 'react';
import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { Backdrop, Card, Kicker, Title } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import facts from '../config/generated/facts.json';
import { enter, ramp } from '../lib/anim';

const c = copy.builtProof;
const { git, tests, parityClips } = facts;
const LINE = 42; // px per commit subject
const day = (d: string) => new Date(`${d}T00:00:00Z`).toLocaleDateString('en-US', { month: 'short', day: 'numeric', timeZone: 'UTC' });

// The repo's real history, read from git before each render (scripts/sync-facts.mjs).
export const BuiltProof: React.FC = () => {
  const frame = useCurrentFrame();
  const most = Math.max(...git.days.map((d) => d.commits));
  const scroll = ramp(frame, 10, 230, (x) => x) * Math.max(0, git.subjects.length * LINE - 620);
  const stats = [tests.swift, tests.python, parityClips];
  return (
    <Backdrop glow={0.08}>
      <AbsoluteFill style={{ padding: '70px 0 150px 100px', width: 1020, gap: 20 }}>
        <Kicker style={enter(frame, 4)}>{c.kicker}</Kicker>
        <Title size={76} style={enter(frame, 10)}>{c.title}</Title>
        <div style={{ ...enter(frame, 22), display: 'flex', alignItems: 'baseline', gap: 22 }}>
          <span style={{ fontFamily: fonts.display, fontSize: 116, fontWeight: 800, color: colors.accent, lineHeight: 1 }}>{Math.round(git.commits * ramp(frame, 26, 70))}</span>
          <span style={{ fontSize: 36, color: colors.muted }}>commits · {day(git.first)} to {day(git.last)}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 12, height: 150 }}>
          {git.days.map((d, i) => (
            <div key={d.date} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-end', height: '100%', gap: 6 }}>
              <div style={{ width: '100%', height: (d.commits / most) * 110 * ramp(frame, 30 + i * 3, 56 + i * 3), minHeight: 3, background: d.commits ? colors.accent : colors.track, borderRadius: 5 }} />
              <div style={{ fontSize: 19, color: colors.muted, whiteSpace: 'nowrap' }}>{day(d.date).split(' ')[1]}</div>
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', gap: 20, marginTop: 6 }}>
          {stats.map((v, i) => (
            <Card key={c.testsLabel[i]} style={{ ...enter(frame, 90 + i * 12), flex: 1, padding: '16px 22px' }}>
              <div style={{ fontFamily: fonts.display, fontSize: 56, fontWeight: 800, lineHeight: 1 }}>{v}</div>
              <div style={{ fontSize: 24, color: colors.muted, marginTop: 4 }}>{c.testsLabel[i]}</div>
            </Card>
          ))}
        </div>
        <div style={{ ...enter(frame, 130), fontFamily: fonts.mono, fontSize: 26, color: colors.better }}>{c.verify}  <span style={{ color: colors.muted }}>· {c.license}</span></div>
      </AbsoluteFill>

      {/* git log, scrolling */}
      <div style={{ ...enter(frame, 6), position: 'absolute', left: 1130, top: 70, width: 720, height: 800, overflow: 'hidden', background: colors.card, border: `1px solid ${colors.track}`, borderRadius: 18, padding: '20px 26px', WebkitMaskImage: 'linear-gradient(180deg, #000 86%, transparent)' }}>
        <div style={{ fontFamily: fonts.mono, fontSize: 24, color: colors.accent, marginBottom: 14 }}>$ git log --reverse --oneline</div>
        <div style={{ height: 720, overflow: 'hidden' }}>
          <div style={{ transform: `translateY(${-scroll}px)` }}>
            {git.subjects.map((s) => (
              <div key={s} style={{ fontFamily: fonts.mono, fontSize: 21, color: colors.text, height: LINE, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', lineHeight: `${LINE}px` }}>{s}</div>
            ))}
          </div>
        </div>
      </div>
    </Backdrop>
  );
};

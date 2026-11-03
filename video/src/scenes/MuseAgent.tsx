import React from 'react';
import { AbsoluteFill, useCurrentFrame } from 'remotion';
import { Backdrop, Kicker } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import facts from '../config/generated/facts.json';
import { enter, ramp } from '../lib/anim';

const c = copy.museAgent;
// Beat timings (frames): each call starts, its result lands, then the answer.
const T = { ask: 12, calls: [{ at: 66, result: 112 }, { at: 150, result: 205 }], answer: 250, rule: 300 };
const HUB = { x: 1340, y: 450 };
// Tool groups around Muse, in the order of copy.museAgent.groups.
const GROUP_AT = [{ x: 1085, y: 175 }, { x: 1600, y: 175 }, { x: 1085, y: 725 }, { x: 1600, y: 725 }];

const Line: React.FC<{ children: React.ReactNode; dir: string; style?: React.CSSProperties }> = ({ children, dir, style }) => (
  <div style={{ fontFamily: fonts.mono, fontSize: 26, lineHeight: 1.35, display: 'flex', gap: 14, ...style }}>
    <span style={{ color: colors.accent, flexShrink: 0 }}>{dir}</span><span>{children}</span>
  </div>
);

// Muse Spark as a tool-calling agent: the tools around it light up as it uses them on a real trace.
export const MuseAgent: React.FC = () => {
  const frame = useCurrentFrame();
  const current = T.calls.findIndex((t) => frame >= t.at && frame < t.result);
  const activeTool = current >= 0 ? c.calls[current].tool : null;
  const used = c.calls.filter((_, i) => frame >= T.calls[i].at).map((x) => x.tool);
  return (
    <Backdrop glow={0.06}>
      {/* Transcript */}
      <AbsoluteFill style={{ left: 70, width: 790, padding: '60px 0 150px', gap: 18 }}>
        <Kicker style={enter(frame, 4)}>{c.kicker}</Kicker>
        <div style={{ ...enter(frame, T.ask), alignSelf: 'flex-end', maxWidth: 640, background: colors.accent, color: '#11130c', fontSize: 31, fontWeight: 600, padding: '16px 24px', borderRadius: '24px 24px 6px 24px', lineHeight: 1.25, marginTop: 6 }}>{c.question}</div>
        {c.calls.map((call, i) => (
          <div key={call.tool} style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <Line dir="→" style={{ ...enter(frame, T.calls[i].at), color: colors.text }}><b>{call.tool}</b>({call.args})</Line>
            <Line dir="←" style={{ ...enter(frame, T.calls[i].result), color: colors.muted }}>{call.result}</Line>
          </div>
        ))}
        <div style={{ ...enter(frame, T.answer), fontSize: 32, lineHeight: 1.3, background: colors.card, border: `1px solid ${colors.track}`, padding: '16px 24px', borderRadius: '24px 24px 24px 6px' }}>{c.answer}</div>
        <div style={{ ...enter(frame, T.answer + 12), fontSize: 22, color: colors.muted }}>{c.traceNote}</div>
      </AbsoluteFill>

      {/* Wires from Muse to each tool group */}
      <svg width={1920} height={1080} style={{ position: 'absolute', inset: 0 }}>
        {c.groups.map((g, i) => {
          const hot = activeTool !== null && g.tools.includes(activeTool);
          const p = GROUP_AT[i];
          const pulse = hot ? ((frame * 2) % 30) / 30 : 0;
          return (
            <g key={g.name}>
              <line x1={HUB.x} y1={HUB.y} x2={p.x} y2={p.y} stroke={hot ? colors.accent : colors.track} strokeWidth={hot ? 4 : 2} />
              {hot && <circle cx={HUB.x + (p.x - HUB.x) * pulse} cy={HUB.y + (p.y - HUB.y) * pulse} r={9} fill={colors.accent} />}
            </g>
          );
        })}
      </svg>

      {/* Muse */}
      <div style={{ position: 'absolute', left: HUB.x - 145, top: HUB.y - 95, width: 290, height: 190, borderRadius: 28, background: colors.card, border: `3px solid ${colors.accent}`, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', opacity: ramp(frame, 0, 12), boxShadow: `0 0 ${activeTool ? 70 : 30}px rgba(221,232,91,${activeTool ? 0.45 : 0.18})` }}>
        <div style={{ fontFamily: fonts.display, fontSize: 46, fontWeight: 800 }}>Muse Spark</div>
        <div style={{ fontFamily: fonts.mono, fontSize: 24, color: colors.muted }}>{facts.model}</div>
        <div style={{ fontSize: 26, color: colors.accent, fontWeight: 700, marginTop: 6 }}>{facts.agentTools.length} tools</div>
      </div>

      {/* Tool groups */}
      {c.groups.map((g, i) => (
        <div key={g.name} style={{ ...enter(frame, 14 + i * 5), position: 'absolute', left: GROUP_AT[i].x - 190, top: GROUP_AT[i].y - 125, width: 380, background: colors.bg, border: `1px solid ${colors.track}`, borderRadius: 18, padding: '14px 18px' }}>
          <div style={{ fontSize: 24, fontWeight: 700, marginBottom: 8, color: colors.muted }}>{g.name}</div>
          {g.tools.map((t) => (
            <div key={t} style={{ fontFamily: fonts.mono, fontSize: 24, padding: '3px 8px', borderRadius: 8, color: t === activeTool ? '#11130c' : used.includes(t) ? colors.accent : colors.text, background: t === activeTool ? colors.accent : 'transparent', fontWeight: t === activeTool ? 700 : 400 }}>{t}</div>
          ))}
        </div>
      ))}

      {/* The rule and the limits, below the graph */}
      <div style={{ ...enter(frame, T.rule), position: 'absolute', left: 900, right: 40, top: 880, display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center', fontSize: 30 }}>
        <span style={{ color: colors.accent, fontWeight: 700 }}>{c.rule}</span>
        <span style={{ color: colors.muted, fontFamily: fonts.mono, fontSize: 23 }}>{facts.agentLimits.max_requests_per_round} requests · {facts.agentLimits.max_tool_calls_per_round} tool calls · {facts.agentLimits.timeout_s} s per round</span>
      </div>
    </Backdrop>
  );
};

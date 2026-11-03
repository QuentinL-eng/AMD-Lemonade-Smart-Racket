import React from 'react';
import { AbsoluteFill, OffthreadVideo, staticFile, useCurrentFrame } from 'remotion';
import { Kicker, Title } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { copy } from '../config/copy';
import track from '../config/generated/samTrack.json';
import { Vignette } from '../hype/kit';
import { enter, ramp } from '../lib/anim';

const c = copy.samTrack;
const K = 1920 / track.width;
const TRAIL = 40; // frames of racket path behind the current one
type Box = number[] | null;

const Boxed: React.FC<{ box: Box; color: string; label: string }> = ({ box, color, label }) => {
  if (!box) return null;
  const [x1, y1, x2, y2] = box.map((v) => v * K);
  return (
    <div style={{ position: 'absolute', left: x1, top: y1, width: x2 - x1, height: y2 - y1, border: `4px solid ${color}`, borderRadius: 6 }}>
      <div style={{ position: 'absolute', left: -4, top: y1 > 44 ? -40 : undefined, bottom: y1 > 44 ? undefined : -40, background: color, color: '#11130c', fontFamily: fonts.mono, fontSize: 24, fontWeight: 700, padding: '3px 10px', borderRadius: 6, whiteSpace: 'nowrap' }}>
        {label} {box[4].toFixed(2)}
      </div>
    </div>
  );
};

// A real 240 fps forehand, one source frame per video frame, under the real cached SAM 3.1 boxes.
export const SamTrack: React.FC = () => {
  const frame = useCurrentFrame();
  const i = Math.min(frame, track.racket.length - 1);
  const racket = track.racket as Box[], ball = track.ball as Box[];
  const centre = (b: number[]) => `${((b[0] + b[2]) / 2) * K},${((b[1] + b[3]) / 2) * K}`;
  const trail = racket.slice(Math.max(0, i - TRAIL), i + 1).filter((b): b is number[] => !!b).map(centre).join(' ');
  const contact = track.contactIndex ?? -1;
  const flash = contact >= 0 && frame >= contact ? Math.exp(-(frame - contact) / 10) : 0;
  return (
    <AbsoluteFill style={{ background: colors.bg, fontFamily: fonts.sans }}>
      <OffthreadVideo src={staticFile('footage/sam-clip.mp4')} muted style={{ width: '100%', height: '100%', objectFit: 'cover', filter: 'contrast(1.05) saturate(0.9) brightness(0.82)' }} />
      <Vignette strength={0.5} />
      <svg width={1920} height={1080} style={{ position: 'absolute', inset: 0 }}>
        <polyline points={trail} fill="none" stroke={colors.accent} strokeWidth={5} strokeLinejoin="round" opacity={0.8} />
      </svg>
      <Boxed box={racket[i]} color={colors.accent} label={c.prompts.racket} />
      <Boxed box={ball[i] ?? null} color={colors.better} label={c.prompts.ball} />
      <AbsoluteFill style={{ background: colors.accent, opacity: flash * 0.22, mixBlendMode: 'screen' }} />

      <AbsoluteFill style={{ padding: '60px 70px', alignItems: 'flex-end' }}>
        <div style={{ width: 760, background: 'rgba(11,12,9,0.78)', borderRadius: 20, padding: '24px 30px', textAlign: 'right' }}>
          <Kicker style={enter(frame, 4)}>{c.kicker}</Kicker>
          <Title size={56} style={{ ...enter(frame, 10), marginTop: 6 }}>{c.title}</Title>
          <div style={{ ...enter(frame, 24), fontSize: 28, color: colors.muted, marginTop: 10, lineHeight: 1.25 }}>{c.stat}</div>
          <div style={{ ...enter(frame, 36), fontSize: 30, color: colors.accent, fontWeight: 700, marginTop: 8 }}>{c.purpose}</div>
          <div style={{ fontFamily: fonts.mono, fontSize: 24, color: colors.muted, marginTop: 10, opacity: ramp(frame, 40, 50) }}>frame {track.startFrame + i}</div>
        </div>
      </AbsoluteFill>
      {contact >= 0 && frame >= contact && (
        <div style={{ ...enter(frame, contact, 6, 12), position: 'absolute', left: 70, top: 60, fontFamily: fonts.display, fontSize: 64, fontWeight: 800, color: colors.accent }}>{c.contact}</div>
      )}
    </AbsoluteFill>
  );
};

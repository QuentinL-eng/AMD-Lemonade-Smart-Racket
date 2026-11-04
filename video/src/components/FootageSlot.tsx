import React from 'react';
import { AbsoluteFill, OffthreadVideo, Sequence, getStaticFiles, interpolate, staticFile, useCurrentFrame, useVideoConfig } from 'remotion';
import { colors, fonts } from '../config/brand';
import type { FootageEntry } from '../config/timeline';
import { GRADE } from '../hype/kit';
import { scenes } from '../scenes';
import { OverlayLayer } from './Overlays';
import { Backdrop } from './ui';

/** Burned-in caption: most social views are muted. */
export const Caption: React.FC<{ text: string }> = ({ text }) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(frame, [6, 16], [0, 1], { extrapolateLeft: 'clamp', extrapolateRight: 'clamp' });
  return (
    <AbsoluteFill style={{ justifyContent: 'flex-end', alignItems: 'center', paddingBottom: 72, opacity }}>
      <div style={{ fontFamily: fonts.sans, fontWeight: 600, fontSize: 40, color: colors.text, background: 'rgba(11,12,9,0.72)', padding: '14px 28px', borderRadius: 14, maxWidth: 1500, textAlign: 'center', lineHeight: 1.3 }}>
        {text}
      </div>
    </AbsoluteFill>
  );
};

/** The file that fills a slot: `file`, or public/footage/<id>.mp4 once it exists. */
export const footageFile = (entry: FootageEntry) => {
  if (entry.file) return entry.file;
  const name = `${entry.footage}.mp4`;
  return getStaticFiles().some((f) => f.name === `footage/${name}`) ? name : undefined;
};

/** Short cuts already in public/footage, end to end. */
const Clips: React.FC<{ clips: NonNullable<FootageEntry['clips']> }> = ({ clips }) => {
  const { fps } = useVideoConfig();
  let at = 0;
  return (
    <>
      {clips.map(([name, seconds, rate], i) => {
        const from = at;
        const frames = Math.round(seconds * fps);
        at += frames;
        return (
          <Sequence key={i} from={from} durationInFrames={frames}>
            <OffthreadVideo src={staticFile(`footage/${name}.mp4`)} muted playbackRate={rate ?? 1} style={{ width: '100%', height: '100%', objectFit: 'cover', filter: GRADE }} />
          </Sequence>
        );
      })}
    </>
  );
};

/** A portrait screen recording in an iPhone frame. */
const PhoneFrame: React.FC<{ children: React.ReactNode; width?: number }> = ({ children, width = 470 }) => (
  <Backdrop glow={0.12}>
    <div style={{ position: 'absolute', left: 300, top: 40, width, height: 1000, borderRadius: 70, background: '#000', border: '12px solid #2b2d27', overflow: 'hidden', boxShadow: '0 30px 120px rgba(0,0,0,0.7)' }}>
      {children}
    </div>
  </Backdrop>
);

const Placeholder: React.FC<{ entry: FootageEntry; small?: boolean }> = ({ entry, small }) => (
  <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', border: small ? undefined : `4px dashed ${colors.track}`, fontFamily: fonts.sans, color: colors.muted, gap: 20, padding: small ? 34 : 160, textAlign: 'center' }}>
    <div style={{ fontSize: small ? 20 : 26, letterSpacing: 4, textTransform: 'uppercase', color: colors.accent }}>Real footage · {entry.seconds}s</div>
    <div style={{ fontFamily: fonts.display, fontSize: small ? 36 : 64, fontWeight: 700, color: colors.text, overflowWrap: 'anywhere' }}>{entry.footage}</div>
    <div style={{ fontSize: small ? 25 : 34, lineHeight: 1.4, maxWidth: 1300 }}>{entry.shot}</div>
    <div style={{ fontSize: small ? 17 : 24, fontFamily: fonts.mono, overflowWrap: 'anywhere' }}>public/footage/{entry.footage}.mp4</div>
  </AbsoluteFill>
);

/** Real footage if the file exists, otherwise its stand-in clips, its CGI fallback or a placeholder with the shot notes. */
export const FootageSlot: React.FC<{ entry: FootageEntry }> = ({ entry }) => {
  const { fps } = useVideoConfig();
  const file = footageFile(entry);
  const phone = entry.layout === 'phone';
  const video = file && (
    <OffthreadVideo src={staticFile(`footage/${file}`)} trimBefore={Math.round((entry.from ?? 0) * fps)} playbackRate={entry.playbackRate ?? 1} muted={entry.muted ?? true} style={{ width: '100%', height: '100%', objectFit: 'cover', filter: phone ? undefined : GRADE }} />
  );
  const Fallback = !file && entry.fallback ? scenes[entry.fallback] : null;
  return (
    <AbsoluteFill style={{ background: colors.bg }}>
      {phone ? <PhoneFrame width={entry.phoneWidth}>{video ?? <Placeholder entry={entry} small />}</PhoneFrame> : video}
      {!file && entry.clips && <Clips clips={entry.clips} />}
      {Fallback && <Fallback />}
      {!file && !phone && !entry.clips && !Fallback && <Placeholder entry={entry} />}
      {!file && entry.standIn && (
        <div style={{ position: 'absolute', left: 40, top: 36, fontFamily: fonts.mono, fontSize: 24, color: '#11130c', background: colors.worse, padding: '5px 14px', borderRadius: 8 }}>STAND-IN · film {entry.footage}.mp4</div>
      )}
      {entry.overlays && <OverlayLayer overlays={entry.overlays} />}
      {entry.caption && <Caption text={entry.caption} />}
    </AbsoluteFill>
  );
};

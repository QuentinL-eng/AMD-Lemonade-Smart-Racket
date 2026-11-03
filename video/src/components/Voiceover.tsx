// The Demo's spoken lines (config/voiceover.ts): each plays once its recording exists in public/audio/vo/, and its
// caption is always burned in, one short phrase at a time, so the video reads muted.
import React from 'react';
import { AbsoluteFill, Audio, Sequence, getStaticFiles, staticFile, useCurrentFrame } from 'remotion';
import { colors, fonts } from '../config/brand';
import { voSeconds, type VoLine } from '../config/voiceover';

/** The recording of a line, if it has been saved. */
export const voFile = (id: string) => getStaticFiles().find((f) => new RegExp(`^audio/vo/${id}\\.(wav|mp3|m4a)$`).test(f.name))?.name;

/** Breaks a line at punctuation, then at about eight words. */
const phrases = (text: string) =>
  text.split(/(?<=[.,:?!])\s+/).flatMap((part) => {
    const words = part.split(/\s+/);
    if (words.length <= 9) return [part];
    const mid = Math.ceil(words.length / 2);
    return [words.slice(0, mid).join(' '), words.slice(mid).join(' ')];
  });

const LineCaption: React.FC<{ text: string; frames: number }> = ({ text, frames }) => {
  const frame = useCurrentFrame();
  const parts = phrases(text);
  const total = text.split(/\s+/).length;
  // Each phrase stays up in proportion to its words.
  let spent = 0;
  const current = parts.find((p) => {
    spent += p.split(/\s+/).length / total;
    return frame < spent * frames;
  }) ?? parts[parts.length - 1];
  return (
    <AbsoluteFill style={{ justifyContent: 'flex-end', alignItems: 'center', paddingBottom: 58 }}>
      <div style={{ fontFamily: fonts.sans, fontWeight: 600, fontSize: 40, color: colors.text, background: 'rgba(11,12,9,0.78)', padding: '12px 28px', borderRadius: 14, maxWidth: 1560, textAlign: 'center', lineHeight: 1.25 }}>
        {current}
      </div>
    </AbsoluteFill>
  );
};

/** All spoken lines of a cut. `starts` maps an entry id to its first frame. */
export const VoiceoverTrack: React.FC<{ lines: VoLine[]; starts: Map<string, number>; fps: number }> = ({ lines, starts, fps }) => (
  <>
    {lines.map((l) => {
      const start = starts.get(l.at);
      if (start === undefined) return null; // its entry was cut from the timeline
      const from = start + Math.round((l.lead ?? 0.3) * fps);
      const frames = Math.round(voSeconds(l) * fps);
      const file = voFile(l.id);
      return (
        <React.Fragment key={l.id}>
          {file && <Sequence from={from} layout="none"><Audio src={staticFile(file)} /></Sequence>}
          <Sequence from={from} durationInFrames={frames} layout="none"><LineCaption text={l.text} frames={frames} /></Sequence>
        </React.Fragment>
      );
    })}
  </>
);

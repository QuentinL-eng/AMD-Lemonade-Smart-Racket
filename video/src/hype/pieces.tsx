// Larger building blocks shared by the footage + CGI X cuts: a real shot with a word slammed
// over it, the CAD handle opening up, and the CGI racket finale with the name.
import React from 'react';
import { AbsoluteFill, Easing, interpolate, useCurrentFrame } from 'remotion';
import { Racket } from '../components/Racket';
import { Stage3D } from '../components/Stage3D';
import { colors, fonts } from '../config/brand';
import { useCad } from '../lib/models';
import { Part } from '../scenes/InsideHandle';
import { Big, Center, useSlam } from './Hype';
import { Clip, GRADE, SHADOW, Shade, clamp, inOut, mix, type V3 } from './kit';

/** A real shot with one phrase slammed over it on its first frame. */
export const WordShot: React.FC<{ clip: string; len: number; word?: string; accent?: boolean; size?: number; zoom?: [number, number]; origin?: string; grade?: string; at?: number; kicker?: string }> = ({ clip, len, word, accent, size, zoom = [1.14, 1], origin, grade = GRADE, at = 0, kicker }) => {
  const frame = useCurrentFrame();
  const slam = useSlam(at);
  const auto = !word ? 0 : word.length > 14 ? 150 : word.length > 9 ? 180 : 210;
  return (
    <AbsoluteFill>
      <Clip name={clip} len={len} zoom={zoom} origin={origin} grade={grade} />
      {word && <Shade />}
      {word && frame >= at && (
        <Center style={{ flexDirection: 'column', padding: '0 80px' }}>
          {kicker && <div style={{ ...slam, fontFamily: fonts.mono, fontSize: 30, letterSpacing: 6, color: colors.accent, marginBottom: 18 }}>{kicker}</div>}
          <Big size={size ?? auto} color={accent ? colors.accent : colors.text} style={{ ...slam, textShadow: SHADOW }}>{word}</Big>
        </Center>
      )}
    </AbsoluteFill>
  );
};

/**
 * The CAD handle (shells, screws, button, board, IMU, mic, MCU) opening up. `explode` and `move`
 * run 0..1; `imu` lights the motion sensor. `xray` draws the shells as ghosts from the start.
 */
const HANDLE_CAM = { from: [1.1, 0.75, 2.6] as V3, fromTarget: [0.9, 0, 0] as V3, to: [1.3, 1.5, 4.4] as V3, toTarget: [1.3, 0.05, 0] as V3, fov: 30 };
export const HandleCGI: React.FC<{ explode: number; move: number; imu?: number; glow?: number; rim?: string; xray?: boolean }> = ({ explode, move, imu = 0, glow = 0, rim = '#ffe9c9', xray }) => {
  const cad = useCad('handle');
  const lift = 22 * explode;
  return (
    <Stage3D camera={mix(HANDLE_CAM.from, HANDLE_CAM.to, move)} target={mix(HANDLE_CAM.fromTarget, HANDLE_CAM.toTarget, move)} fov={HANDLE_CAM.fov} rim={rim} envIntensity={0.6}>
      {cad && (
        <group rotation={[0.1 + 0.08 * move, -0.3 - 0.25 * move, 0]}>
          <group scale={0.036} rotation={[0, Math.PI / 2, 0]}>
            <group position={cad.center.clone().negate().toArray()}>
              <Part group={cad.groups.shell1} offset={[0, lift, 0]} ghost={xray || explode > 0.05} />
              <Part group={cad.groups.shell2} offset={[0, -lift, 0]} ghost={xray || explode > 0.05} />
              <Part group={cad.groups.screws} offset={[0, -lift, 0]} />
              <Part group={cad.groups.button} offset={[0, lift, 0]} />
              <Part group={cad.groups.board} glow={glow * 0.4} />
              <Part group={cad.groups.imu} offset={[0, 6 * explode, 0]} glow={Math.max(imu, glow)} />
              <Part group={cad.groups.mic} offset={[0, 4 * explode, 0]} glow={glow} />
              <Part group={cad.groups.mcu} offset={[0, 4 * explode, 0]} glow={glow} />
            </group>
          </group>
        </group>
      )}
    </Stage3D>
  );
};

/** Tags that pop in one after another, bottom right. */
export const Tags: React.FC<{ tags: readonly string[]; at: number; every?: number; color?: string }> = ({ tags, at, every = 4, color = colors.accent }) => {
  const frame = useCurrentFrame();
  const tagIn = (i: number) => interpolate(frame, [at + i * every, at + 6 + i * every], [0, 1], clamp);
  return (
    <div style={{ display: 'flex', gap: 14 }}>
      {tags.map((tag, i) => (
        <div key={tag} style={{ opacity: tagIn(i), transform: `translateY(${(1 - tagIn(i)) * 20}px)`, fontFamily: fonts.mono, fontSize: 26, letterSpacing: 2, color, border: `1.5px solid ${color}`, borderRadius: 30, padding: '8px 18px', background: 'rgba(11,12,9,0.5)' }}>{tag}</div>
      ))}
    </div>
  );
};

/**
 * Finale, local frame 0 = the cut from the last real shot. The real shot ends close on the racket
 * standing head-down against the net, so the CGI racket starts head-down and close, then turns
 * upright as the camera pulls back and slides left for the name. `room` is the real clip, blurred,
 * that stays behind the CGI for the first moments.
 */
const FIN_CAM = { from: [0, -0.15, 1.5] as V3, fromTarget: [0, -0.1, 0] as V3, to: [0, 0.1, 6.1] as V3, toTarget: [0, 0.05, 0] as V3 };
export const RacketFinale: React.FC<{
  beat: number; // frames per beat
  finish: 'carbon' | 'blue' | 'red';
  name: string;
  /** a sentence under the name, or a `tagline` slammed in lime instead */
  line?: string;
  tagline?: string;
  cta: string;
  room?: string;
  roomLen?: number;
  headDown?: boolean;
  glow?: (frame: number) => number;
  grade?: string;
  aura?: string;
}> = ({ beat, finish, name, line, tagline, cta, room, roomLen = 120, headDown = true, glow = () => 0.4, grade, aura = colors.accent }) => {
  const k = useCurrentFrame();
  const B = (n: number) => Math.round(n * beat);
  const pull = interpolate(k, [0, B(2.5)], [0, 1], { ...clamp, easing: inOut });
  const slide = interpolate(k, [B(1.5), B(3)], [0, 1], { ...clamp, easing: inOut });
  const turn = headDown ? interpolate(k, [0, B(2.2)], [Math.PI, 0], { ...clamp, easing: Easing.inOut(Easing.cubic) }) : 0;
  const nameSlam = useSlam(B(2));
  const tagSlam = useSlam(B(3));
  const appear = (n: number) => ({ opacity: interpolate(k, [B(n), B(n) + 6], [0, 1], clamp) });
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{ background: colors.bg }} />
      {room && (
        <AbsoluteFill style={{ opacity: 1 - pull }}>
          <Clip name={room} len={roomLen} zoom={[1.5, 1.7]} blur={30} grade={grade} />
          <AbsoluteFill style={{ background: 'rgba(11,12,9,0.5)' }} />
        </AbsoluteFill>
      )}
      <AbsoluteFill style={{ background: `radial-gradient(ellipse 70% 60% at 30% 50%, ${aura}${Math.round(26 * slide).toString(16).padStart(2, '0')}, rgba(11,12,9,0) 65%)` }} />
      <Stage3D camera={mix(FIN_CAM.from, FIN_CAM.to, pull)} target={mix(FIN_CAM.fromTarget, FIN_CAM.toTarget, pull)} fov={interpolate(pull, [0, 1], [50, 32])} env="studio" envIntensity={1.4} hero>
        <pointLight position={[-0.6, 2.2, -1.8]} intensity={40} distance={8} color="#ffffff" />
        <Racket finish={finish} position={[-1.25 * slide, 0, 0]} rotation={[0.1 * pull, 0.3 * pull + k * 0.005, turn - 0.16 * slide]} glow={glow(k)} />
      </Stage3D>
      <AbsoluteFill style={{ justifyContent: 'center', paddingLeft: 860, gap: 18 }}>
        {k >= B(2) && <Big size={118} style={{ ...nameSlam, transformOrigin: 'left center', whiteSpace: 'nowrap' }}>{name}</Big>}
        {line && <div style={{ ...appear(3), fontFamily: fonts.sans, fontSize: 52, color: colors.text }}>{line}</div>}
        {tagline && k >= B(3) && <Big size={96} color={colors.accent} style={{ ...tagSlam, transformOrigin: 'left center', whiteSpace: 'nowrap' }}>{tagline}</Big>}
        <div style={{ ...appear(4), alignSelf: 'flex-start', marginTop: 20, padding: '14px 30px', borderRadius: 40, background: colors.accent, color: '#11130c', fontFamily: fonts.sans, fontWeight: 700, fontSize: 38 }}>{cta}</div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

/** Push into a point of a real shot until it goes black (local frames 0..len). */
export const PushToBlack: React.FC<{ clip: string; len: number; origin: string; zoom: number; grade?: string }> = ({ clip, len, origin, zoom, grade }) => {
  const frame = useCurrentFrame();
  const dark = interpolate(frame, [len - 7, len], [0, 1], clamp);
  return (
    <AbsoluteFill>
      <Clip name={clip} len={len} zoom={[1, zoom]} origin={origin} ease={Easing.in(Easing.cubic)} grade={grade} />
      <AbsoluteFill style={{ background: '#050504', opacity: dark }} />
    </AbsoluteFill>
  );
};

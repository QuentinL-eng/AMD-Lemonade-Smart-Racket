// Swing film: the player's average forehand, then Muse's recommended change, then the estimated effect.
// Everything visual is fixed here and in look.ts; the script (config/swingFilm.json) comes from
// tools/swing_film.py, which asks Muse Spark and validates the answer against docs/SWING_FILM.md.
import React, { useMemo } from 'react';
import { AbsoluteFill, useCurrentFrame } from 'remotion';
import * as THREE from 'three';
import { Racket } from '../components/Racket';
import { Stage3D } from '../components/Stage3D';
import { Backdrop, Card, Kicker, Title } from '../components/ui';
import { colors, fonts } from '../config/brand';
import { enter, ramp } from '../lib/anim';
import { CAMERA, CM, FILM, M, SWING } from './look';

export type Side = {
  swingKmh: number; pathDeg: number; faceDeg: number; contactXcm: number; contactYcm: number;
  ballKmh: number; spinRpm: number; spinType: string;
};
export type FilmScript = {
  model: string; stroke: string; sampleCount: number; estimated: boolean; source: string;
  deltas: Record<string, number>; title: string; cue: string; why: string; before: Side; after: Side;
};

const deg = Math.PI / 180;
const v3 = (x: number, y: number, z: number) => new THREE.Vector3(x, y, z);

/** Racket pose at real time `t` seconds from contact (negative before). */
function pose(s: Side, t: number) {
  const p = s.pathDeg * deg, f = s.faceDeg * deg;
  const e1 = v3(0, 0, 1); // pivot -> head at contact: out to the player's side
  const e2 = v3(Math.cos(p), Math.sin(p), 0); // head travel at contact: toward the target, tilted by the path
  const n = e1.clone().cross(e2).normalize(); // up, out of the swing plane
  const R = SWING.pivotToHeadM * M;
  const omega = s.swingKmh / 3.6 / SWING.pivotToHeadM; // rad/s at contact
  const phi = SWING.maxTurn * Math.tanh((omega * t) / SWING.maxTurn);
  const r = e1.clone().multiplyScalar(Math.cos(phi)).addScaledVector(e2, Math.sin(phi)); // radial: racket long axis
  const tan = e1.clone().multiplyScalar(-Math.sin(phi)).addScaledVector(e2, Math.cos(phi));
  const normal = tan.clone().multiplyScalar(Math.cos(f)).addScaledVector(n, Math.sin(f)); // + opens the face
  const x = r.clone().cross(normal).normalize(); // across the strings (x, r, normal is right-handed)
  const q = new THREE.Quaternion().setFromRotationMatrix(new THREE.Matrix4().makeBasis(x, r, normal));
  const pivot = e1.clone().multiplyScalar(-R);
  const head = pivot.clone().addScaledVector(r, R);
  // place the racket so the ball (fixed at the origin) meets the strings at the measured contact point
  const origin = head.clone().addScaledVector(r, -SWING.headOffset)
    .addScaledVector(x, -s.contactXcm * CM).addScaledVector(r, -s.contactYcm * CM);
  const bed = head.clone().addScaledVector(x, -s.contactXcm * CM).addScaledVector(r, -s.contactYcm * CM);
  return { q, origin, bed, normal, tan, n };
}

const realTime = (frame: number, start: number) => ((frame - start - FILM.contactAt) / FILM.fps) * FILM.slowMo;

/** The string-bed centre's path through the swing, as a tube. */
const Trail: React.FC<{ side: Side; until: number; color: string; opacity: number }> = ({ side, until, color, opacity }) => {
  const geo = useMemo(() => {
    const pts: THREE.Vector3[] = [];
    const t0 = -0.32;
    const end = Math.min(until, 0.32);
    if (end <= t0 + 0.01) return null;
    for (let k = 0; k <= 60; k++) pts.push(pose(side, t0 + ((end - t0) * k) / 60).bed);
    return new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts), 120, 0.035, 10, false);
  }, [side, until]);
  if (!geo) return null;
  return (
    <mesh geometry={geo}>
      <meshStandardMaterial color={color} emissive={color} emissiveIntensity={0.6} transparent opacity={opacity} toneMapped={false} />
    </mesh>
  );
};

const Ball: React.FC<{ side: Side; t: number }> = ({ side, t }) => {
  if (t > SWING.ballShowS) return null;
  const { normal, n } = pose(side, 0);
  const pos = t < 0
    ? v3(1, 0.04, 0).multiplyScalar((SWING.incomingKmh / 3.6) * -t * M)
    : normal.clone().multiplyScalar((side.ballKmh / 3.6) * t * M);
  const spin = t > 0 ? (side.spinRpm / 60) * 2 * Math.PI * t : 0;
  const q = new THREE.Quaternion().setFromAxisAngle(n, -spin);
  const fade = t > 0 ? 1 - t / SWING.ballShowS : 1;
  return (
    <group position={pos} quaternion={q}>
      <mesh>
        <sphereGeometry args={[SWING.ballR, 40, 40]} />
        <meshStandardMaterial color="#D9EE3F" roughness={0.85} emissive="#D9EE3F" emissiveIntensity={0.18} transparent opacity={fade} />
      </mesh>
      {/* seam, so spin is visible */}
      <mesh rotation={[0, Math.PI / 2, 0]}>
        <torusGeometry args={[SWING.ballR * 1.002, SWING.ballR * 0.07, 8, 64]} />
        <meshBasicMaterial color="#f4f7e6" transparent opacity={fade} />
      </mesh>
    </group>
  );
};

const SwingScene: React.FC<{ side: Side; ghost?: Side; t: number; glow: number }> = ({ side, ghost, t, glow }) => {
  const p = pose(side, t);
  return (
    <Stage3D camera={CAMERA.pos} target={CAMERA.target} fov={CAMERA.fov} env="studio" envIntensity={0.7}>
      {/* floor grid: a fixed reference for "up" */}
      <gridHelper args={[30, 30, '#2A2E20', '#1b1e15']} position={[0, -3.4, 0]} />
      {ghost && <Trail side={ghost} until={0.32} color="#7c826a" opacity={0.55} />}
      <Trail side={side} until={t} color={colors.accent} opacity={0.95} />
      <group position={p.origin} quaternion={p.q}>
        <Racket finish="carbon" glow={glow} />
      </group>
      <Ball side={side} t={t} />
    </Stage3D>
  );
};

// ---------- HUD (fixed slots) ----------

const fmt = (v: number, d = 0) => (Math.abs(v) < 0.05 && d > 0 ? '0' : v.toFixed(d));
const sign = (v: number, d = 0) => `${v > 0 ? '+' : v < 0 ? '−' : '±'}${fmt(Math.abs(v), d)}`;

const Stat: React.FC<{ label: string; value: string; delta?: string; lit: boolean }> = ({ label, value, delta, lit }) => (
  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', padding: '12px 0', borderBottom: `1px solid ${colors.track}` }}>
    <span style={{ fontSize: 22, color: colors.muted, letterSpacing: 1, marginRight: 24 }}>{label}</span>
    <span style={{ fontFamily: fonts.mono, fontSize: 30, color: lit ? colors.accent : colors.text }}>
      {value}{delta && <span style={{ fontSize: 22, marginLeft: 12, color: colors.accent }}>{delta}</span>}
    </span>
  </div>
);

/** String bed seen face-on with the contact point; before in grey, after in lime. */
const StringBed: React.FC<{ before: Side; after?: Side }> = ({ before, after }) => {
  const s = 7; // px per cm
  const dot = (x: number, y: number, c: string) => <circle cx={110 + x * s} cy={140 - y * s} r={9} fill={c} style={{ filter: `drop-shadow(0 0 8px ${c})` }} />;
  return (
    <svg width={220} height={280}>
      <ellipse cx={110} cy={140} rx={12.45 * s} ry={16.4 * s} fill="none" stroke={colors.muted} strokeWidth={4} />
      {Array.from({ length: 9 }, (_, k) => <line key={`m${k}`} x1={110 + (k - 4) * 20} x2={110 + (k - 4) * 20} y1={40} y2={240} stroke={colors.track} strokeWidth={2} />)}
      {Array.from({ length: 11 }, (_, k) => <line key={`c${k}`} y1={140 + (k - 5) * 20} y2={140 + (k - 5) * 20} x1={30} x2={190} stroke={colors.track} strokeWidth={2} />)}
      <circle cx={110} cy={140} r={4 * s} fill="none" stroke={colors.better} strokeWidth={2} strokeDasharray="6 5" />
      {dot(before.contactXcm, before.contactYcm, after ? '#7c826a' : colors.accent)}
      {after && dot(after.contactXcm, after.contactYcm, colors.accent)}
    </svg>
  );
};

const Hud: React.FC<{ script: FilmScript; showing: Side; changed: boolean; frame: number; start: number }> = ({ script, showing, changed, frame, start }) => {
  const d = script.deltas;
  const lit = (k: string) => changed && d[k] !== 0;
  return (
    <>
      <AbsoluteFill style={{ padding: '80px 110px', justifyContent: 'flex-start', gap: 14, width: 900 }}>
        <Kicker style={enter(frame, start + 2)}>{changed ? 'Try this' : 'Your swing · forehand average'}</Kicker>
        <Title size={70} style={enter(frame, start + 6)}>{changed ? script.title : `${script.sampleCount} forehands`}</Title>
        {changed && <div style={{ ...enter(frame, start + 14), fontSize: 34, color: colors.text, maxWidth: 760, lineHeight: 1.3 }}>{script.cue}</div>}
      </AbsoluteFill>
      <div style={{ position: 'absolute', right: 80, top: 120, width: 520, padding: '18px 30px 24px', background: 'rgba(23,25,19,0.94)', border: `1px solid ${colors.track}`, borderRadius: 22, ...enter(frame, start + 8) }}>
        <Stat label="SWING SPEED" value={`${fmt(showing.swingKmh)} km/h`} delta={lit('swing_percent') ? `${sign(d.swing_percent)}%` : undefined} lit={lit('swing_percent')} />
        <Stat label="SWING PATH" value={`${fmt(showing.pathDeg)}° up`} delta={lit('path_deg') ? `${sign(d.path_deg)}°` : undefined} lit={lit('path_deg')} />
        <Stat label="FACE" value={`${fmt(Math.abs(showing.faceDeg))}° ${showing.faceDeg >= 0 ? 'open' : 'closed'}`} delta={lit('face_deg') ? `${sign(d.face_deg)}°` : undefined} lit={lit('face_deg')} />
        <div style={{ display: 'flex', alignItems: 'center', gap: 24, marginTop: 18 }}>
          <StringBed before={script.before} after={changed ? script.after : undefined} />
          <div style={{ fontSize: 22, color: colors.muted, lineHeight: 1.5 }}>CONTACT<br /><span style={{ color: colors.better }}>- - -</span> sweet spot</div>
        </div>
      </div>
      <div style={{ position: 'absolute', left: 110, bottom: 70, fontFamily: fonts.mono, fontSize: 22, color: colors.muted, letterSpacing: 2 }}>
        SUPER SLOW-MO · RACKET DATA ONLY
      </div>
    </>
  );
};

const Bar: React.FC<{ label: string; before: number; after: number; unit: string; t: number; extra?: string }> = ({ label, before, after, unit, t, extra }) => {
  const max = Math.max(before, after) * 1.15;
  const now = before + (after - before) * t;
  return (
    <div style={{ marginBottom: 30 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 32 }}>
        <span>{label}</span>
        <span><span style={{ color: colors.muted }}>{Math.round(before)} → </span><b>{Math.round(now)}</b> <span style={{ color: colors.muted }}>{unit}</span>{extra && <span style={{ color: colors.better, fontSize: 26, marginLeft: 12 }}>{extra}</span>}</span>
      </div>
      <div style={{ position: 'relative', height: 16, background: colors.track, borderRadius: 8, marginTop: 12 }}>
        <div style={{ position: 'absolute', height: '100%', width: `${(before / max) * 100}%`, background: '#5c6040', borderRadius: 8 }} />
        <div style={{ position: 'absolute', height: '100%', width: `${(now / max) * 100}%`, background: colors.accent, borderRadius: 8, opacity: t > 0 ? 1 : 0 }} />
      </div>
    </div>
  );
};

const ResultCard: React.FC<{ script: FilmScript; frame: number }> = ({ script, frame }) => {
  const s = FILM.card[0];
  const t = ramp(frame, s + 12, s + 40);
  const { before: b, after: a } = script;
  const pct = (x: number, y: number) => `${y >= x ? '▲' : '▼'} ${Math.abs(Math.round(((y - x) / x) * 100))}%`;
  return (
    <Backdrop glow={0.1}>
      <AbsoluteFill style={{ padding: '0 110px', width: 820, justifyContent: 'center', gap: 20 }}>
        <Kicker style={enter(frame, s + 2)}>Estimated effect</Kicker>
        <Title size={76} style={enter(frame, s + 6)}>{script.title}</Title>
        <div style={{ ...enter(frame, s + 14), fontSize: 32, color: colors.muted, lineHeight: 1.35 }}>{script.why}</div>
      </AbsoluteFill>
      <AbsoluteFill style={{ left: 940, width: 870, justifyContent: 'center' }}>
        <Card style={enter(frame, s + 8)}>
          <Bar label="Ball speed" before={b.ballKmh} after={a.ballKmh} unit="km/h" t={t} extra={pct(b.ballKmh, a.ballKmh)} />
          <Bar label="Spin" before={b.spinRpm} after={a.spinRpm} unit="rpm" t={t} extra={b.spinType !== a.spinType ? `${b.spinType} → ${a.spinType}` : pct(b.spinRpm, a.spinRpm)} />
          <div style={{ fontSize: 22, color: colors.muted, marginTop: 6 }}>
            Estimated on your average forehand ({script.sampleCount} shots). Picked and tested by Muse Spark (Meta).
          </div>
        </Card>
      </AbsoluteFill>
    </Backdrop>
  );
};

export const SwingFilm: React.FC<{ script: FilmScript }> = ({ script }) => {
  const frame = useCurrentFrame();
  if (frame >= FILM.card[0]) return <ResultCard script={script} frame={frame} />;
  const changed = frame >= FILM.tryThis[0];
  const start = changed ? FILM.tryThis[0] : FILM.yours[0];
  const side = changed ? script.after : script.before;
  const t = realTime(frame, start);
  const glow = Math.max(0, 1 - Math.abs(frame - start - FILM.contactAt) / 6);
  return (
    <Backdrop glow={0.12}>
      <AbsoluteFill style={{ opacity: ramp(frame, start, start + 8) }}>
        <SwingScene side={side} ghost={changed ? script.before : undefined} t={t} glow={glow} />
      </AbsoluteFill>
      <Hud script={script} showing={side} changed={changed} frame={frame} start={start} />
    </Backdrop>
  );
};

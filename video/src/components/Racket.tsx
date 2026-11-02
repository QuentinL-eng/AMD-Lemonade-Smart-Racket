import type { ThreeElements } from '@react-three/fiber';
import React, { useMemo } from 'react';
import * as THREE from 'three';
import { colors } from '../config/brand';
import { D, buildBumper, buildFrame, buildHandle, buildStrings } from '../lib/racketMesh';

export const RACKET_LENGTH = 3; // scene units, butt to tip

// Geometry lives in lib/racketMesh.ts (real dimensions in metres, one blended frame surface).
// It is built once per tab and shared by every racket on screen.
let shared: ReturnType<typeof build> | null = null;
function build() {
  const frame = buildFrame();
  const { strings, grommets } = buildStrings();
  return { frame, strings, grommets, bumper: buildBumper(), ...buildHandle() };
}
const geometry = () => (shared ??= build());

// Paint: the frame colour, and the colour of the panel on one throat arm (`zone` = 1 there).
const PAINT = {
  carbon: { frame: '#202328', throat: '#202328', grip: '#f1f0ea' },
  blue: { frame: '#2a35c8', throat: '#2a35c8', grip: '#1c1c1e' },
  red: { frame: '#f2333b', throat: '#4fb6ec', grip: '#f1f0ea' }, // the on-court racket: red, one light blue throat arm
} as const;

type Props = ThreeElements['group'] & {
  /** 0..1: the lime ring on the butt cap (where the sensor insert lives). */
  glow?: number;
  /** 'carbon' (default, unbranded), 'blue' (blue frame, black grip: the racket on the test arm) or
   *  'red' (red frame, light blue throat panel, white grip, mint strings: the racket in the on-court footage). */
  finish?: 'carbon' | 'blue' | 'red';
};

/**
 * Head up (+Y), strings facing the camera (+Z), centred on the origin,
 * RACKET_LENGTH units long. Rotate/position the group to animate.
 */
export const Racket: React.FC<Props> = ({ glow = 0, finish = 'carbon', ...props }) => {
  const parts = useMemo(() => {
    const g = geometry();
    const paint = PAINT[finish];
    // per-vertex colour from the paint zones, on a copy that shares the shape buffers
    const frame = new THREE.BufferGeometry();
    for (const name of ['position', 'normal'] as const) frame.setAttribute(name, g.frame.getAttribute(name));
    frame.setIndex(g.frame.getIndex());
    const zone = g.frame.getAttribute('zone');
    const a = new THREE.Color(paint.frame).convertSRGBToLinear(), b = new THREE.Color(paint.throat).convertSRGBToLinear();
    const col = new Float32Array(zone.count * 3);
    for (let i = 0; i < zone.count; i++) {
      const t = zone.getX(i);
      col[i * 3] = a.r + (b.r - a.r) * t;
      col[i * 3 + 1] = a.g + (b.g - a.g) * t;
      col[i * 3 + 2] = a.b + (b.b - a.b) * t;
    }
    frame.setAttribute('color', new THREE.BufferAttribute(col, 3));
    return {
      ...g,
      frame,
      // glossy paint over carbon: a little flake, a hard clearcoat
      frameMat: new THREE.MeshPhysicalMaterial({ vertexColors: true, metalness: finish === 'carbon' ? 0.3 : 0.35, roughness: 0.36, clearcoat: 1, clearcoatRoughness: 0.04 }),
      stringMat: new THREE.MeshPhysicalMaterial({ color: finish === 'red' ? '#9fe0cf' : '#ecebe2', roughness: 0.32, clearcoat: 0.6, clearcoatRoughness: 0.2 }),
      rubberMat: new THREE.MeshPhysicalMaterial({ color: '#0e0e10', roughness: 0.55, clearcoat: 0.3, clearcoatRoughness: 0.4 }),
      gripMat: new THREE.MeshPhysicalMaterial({ color: paint.grip, roughness: 0.85, sheen: 0.5, sheenRoughness: 0.6, sheenColor: new THREE.Color('#ffffff') }),
      trimMat: new THREE.MeshPhysicalMaterial({ color: '#141518', metalness: 0.2, roughness: 0.3, clearcoat: 1, clearcoatRoughness: 0.06 }),
    };
  }, [finish]);
  const s = RACKET_LENGTH / D.length;

  return (
    <group {...props}>
      <group scale={s} position={[0, -(D.length / 2) * s, 0]}>
        <mesh geometry={parts.frame} material={parts.frameMat} />
        <mesh geometry={parts.strings} material={parts.stringMat} />
        <mesh geometry={parts.grommets} material={parts.rubberMat} />
        <mesh geometry={parts.bumper} material={parts.rubberMat} />
        {/* handle: overgrip, finishing tape, collar into the shaft, butt cap */}
        <mesh geometry={parts.grip} material={parts.gripMat} />
        <mesh geometry={parts.tape} material={parts.trimMat} />
        <mesh geometry={parts.collar} material={parts.trimMat} />
        <mesh geometry={parts.cap} material={parts.trimMat} />
        {/* the sensor ring on the butt cap */}
        <mesh position={[0, 0.0128, 0]} rotation={[Math.PI / 2, 0, 0]}>
          <torusGeometry args={[0.0186, 0.0009, 8, 96]} />
          <meshStandardMaterial color={colors.accent} emissive={colors.accent} emissiveIntensity={0.3 + glow * 4} toneMapped={false} />
        </mesh>
      </group>
    </group>
  );
};

import React from 'react';
import { useCurrentFrame } from 'remotion';
import { Racket } from '../../components/Racket';
import { Stage3D } from '../../components/Stage3D';
import { Backdrop } from '../../components/ui';

type V3 = [number, number, number];
// One view per frame, for checking the racket's shape: npx remotion still racket-sheet --frame=N
export const VIEWS: { cam: V3; target: V3; fov: number; rot: V3; finish?: 'carbon' | 'blue' | 'red' }[] = [
  { cam: [0, 0, 14], target: [0, 0, 0], fov: 14, rot: [0, 0, 0] }, // face-on
  { cam: [0, 0, 14], target: [0, 0, 0], fov: 14, rot: [0, Math.PI / 2, 0] }, // side
  { cam: [0, 0.3, 6.4], target: [0, 0.05, 0], fov: 32, rot: [0.1, 0.42, -0.16] }, // hero 3/4
  { cam: [0.5, -0.2, 2.2], target: [0, -0.2, 0], fov: 30, rot: [0.1, 0.5, 0] }, // throat close-up
  { cam: [0, -0.1, 2.6], target: [0, -0.12, 0], fov: 30, rot: [0, 0, 0], finish: 'red' }, // throat face-on
  { cam: [1.1, 0.1, 1.6], target: [0, -0.15, 0], fov: 30, rot: [0, 0, 0], finish: 'red' }, // throat 3/4 from above
  { cam: [2.2, -0.1, 0.2], target: [0, -0.15, 0], fov: 30, rot: [0, 0, 0], finish: 'red' }, // throat from the side
  { cam: [0.6, 1.9, 1.4], target: [0, 1.3, 0], fov: 30, rot: [0, 0, 0], finish: 'red' }, // top of the head, bumper
  { cam: [0.8, -0.9, 1.6], target: [0, -1.0, 0], fov: 30, rot: [0, 0, 0], finish: 'red' }, // handle
  { cam: [0, 0.3, 6.4], target: [0, 0.05, 0], fov: 32, rot: [0.1, 0.42, -0.16], finish: 'red' }, // hero 3/4, red
  { cam: [0, 0.3, 6.4], target: [0, 0.05, 0], fov: 32, rot: [0.1, 0.42, -0.16], finish: 'blue' }, // hero 3/4, blue
];

export const RacketSheet: React.FC = () => {
  const v = VIEWS[Math.min(useCurrentFrame(), VIEWS.length - 1)];
  return (
    <Backdrop glow={0.08}>
      <Stage3D camera={v.cam} target={v.target} fov={v.fov} env="studio" envIntensity={1.4} hero>
        <pointLight position={[-0.6, 2.2, -1.8]} intensity={40} distance={8} color="#ffffff" />
        <Racket rotation={v.rot} glow={1} finish={v.finish} />
      </Stage3D>
    </Backdrop>
  );
};

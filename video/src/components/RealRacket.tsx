import type { ThreeElements } from '@react-three/fiber';
import React from 'react';
import { useGlb } from '../lib/models';
import { RACKET_LENGTH } from './Racket';
import { useRedraw } from './Stage3D';

const MODEL_LENGTH = 8.87; // the file's long axis, tip to butt (website/emulator/TennisRacket.glb)

/** The app's real textured racket, in the same pose as Racket: head up (+Y), strings to the camera (+Z), centred. */
export const RealRacket: React.FC<ThreeElements['group']> = (props) => {
  const model = useGlb('TennisRacket');
  useRedraw([model]);
  return (
    <group {...props}>
      {model && <primitive object={model} scale={RACKET_LENGTH / MODEL_LENGTH} rotation={[Math.PI / 2, 0, 0]} />}
    </group>
  );
};

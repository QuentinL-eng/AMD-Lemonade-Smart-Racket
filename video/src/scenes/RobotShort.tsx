import React from 'react';
import { RobotHypeIntro } from '../hype/RobotHype';

// A wrapper so the registry doesn't need RobotHype while it loads: that file imports Timeline, which imports the registry.
export const RobotShort: React.FC = () => <RobotHypeIntro />;

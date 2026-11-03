import React from 'react';
import swingFilm from '../config/swingFilm.json';
import { SwingFilm, type FilmScript } from '../swingfilm/SwingFilm';

// The 8 s swing film as a timeline scene. Its script comes from tools/swing_film.py (docs/SWING_FILM.md).
export const SwingFilmScene: React.FC = () => <SwingFilm script={swingFilm as FilmScript} />;

Drop filmed clips here (mp4/mov, ideally 1080p+). They are git-ignored.
Name them after the slot ids in src/config/timeline.ts (e.g. club-rally.mp4),
then set `file: 'club-rally.mp4'` on that slot.

The `rh-*` (RobotHype), `bt-*` (BuildLog), `ev-*` (EverySwing) and `hw-*` (Possessed) clips and
stills are generated, not hand-placed: `FFMPEG=path/to/ffmpeg npm run footage` cuts them from
`marketing/Videos/` (list and in-points in `scripts/cut-footage.mjs`; pass a prefix such as `bt-`
to cut one set).

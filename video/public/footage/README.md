Drop filmed clips here (mp4/mov, ideally 1080p+). They are git-ignored.
Name them after the slot ids in src/config/timeline.ts (e.g. cold-open.mp4). Each one fills its slot on its own.
`sam-clip.mp4` is generated: `FFMPEG=path/to/ffmpeg npm run sam`.

The `rh-*` (RobotHype), `bt-*` (BuildLog), `ev-*` (EverySwing) and `hw-*` (Possessed) clips and
stills are generated, not hand-placed: `FFMPEG=path/to/ffmpeg npm run footage` cuts them from
`marketing/Videos/` (list and in-points in `scripts/cut-footage.mjs`; pass a prefix such as `bt-`
to cut one set).

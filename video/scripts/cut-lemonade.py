#!/usr/bin/env python3
"""Cuts everything the Lemonade challenge video needs into public/: the song, the voice takes, new court clips, the app capture.

    FFMPEG=path/to/ffmpeg SELECTS="../marketing/Videos/Tennis selects" python scripts/cut-lemonade.py <capture dir>

<capture dir> comes from scripts/capture-lemonade.mjs. SPANS are seconds on the capture's clock. Chrome only sends a frame when
the page changes, so each frame is held until the next one. The waits for the model are cut; nothing on the phone is changed.
Voice cuts come from Whisper word times: they drop only the words naming the old engine, and keep the rest of the take.
"""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

FFMPEG = os.environ.get('FFMPEG', 'ffmpeg')
ROOT = Path(__file__).resolve().parents[1]
SELECTS = Path(os.environ.get('SELECTS', ROOT.parent / 'marketing/Videos/Tennis selects'))
MUSIC = ROOT.parent / 'marketing/Music/Comin Wit It - Anno Domini Beats.mp3'
FOOTAGE, VO = ROOT / 'public/footage', ROOT / 'public/audio/vo-lemonade'
# No B-frames and a short GOP: Remotion's frame seeker reported missing frames on these clips with the encoder's defaults.
VIDEO = ['-c:v', 'libx264', '-preset', 'medium', '-crf', '17', '-pix_fmt', 'yuv420p', '-r', '30', '-g', '30', '-bf', '0']
FIT = 'scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080'
PHONE = 'crop=590:1100:1268:100,scale=1072:2000:flags=lanczos'  # the phone's screen, sized for its frame


def run(*args):
    subprocess.run([FFMPEG, '-hide_banner', '-loglevel', 'error', '-y', *map(str, args)], check=True)


VO.mkdir(parents=True, exist_ok=True)

# The whole song. The composition starts it on the first bass note, so its bars are the video's bars.
run('-i', MUSIC, '-ar', '48000', '-c:a', 'libmp3lame', '-q:a', '1', ROOT / 'public/audio/comin-wit-it-full.mp3')

# ---- Voice: these takes went through scripts/voice.py already ----
TAKES = {'open': ('open', 0, None), 'reveal': ('reveal', 0, None), 'hardware': ('hardware', 0, None),
         # Ends before "In the app, ...".
         'esp32': ('models', 0, 3.42),
         # Starts after "Ask ... what if, and".
         'whatif': ('whatif', 1.83, None)}
for out, (take, start, end) in TAKES.items():
    span = ['-ss', start] + (['-to', end] if end else [])
    fade = [f'afade=t=in:d=0.02'] + ([f'afade=t=out:st={end - start - 0.05}:d=0.05'] if end else [])
    run('-i', ROOT / f'public/audio/vo/{take}.wav', *span, '-af', ','.join(fade), VO / f'{out}.wav')
    print('vo', out)

# On camera: the first two sentences, up to the pause before the old third clause.
run('-i', FOOTAGE / 'talk-intro.mp4', '-t', 8.72, *VIDEO, '-af', 'afade=t=out:st=8.62:d=0.1', '-c:a', 'aac', '-b:a', '256k', FOOTAGE / 'lm-talk.mp4')
print('lm-talk')


# ---- Court: selects with nobody in sunglasses. They are 120 fps playing at 30, so these are 1/4 speed as they stand ----
def clip(out, source, start, length, vf=FIT):
    run('-ss', start, '-t', length, '-i', SELECTS / source, '-an', '-vf', vf, *VIDEO, FOOTAGE / f'{out}.mp4')
    print(out)


clip('lm-serve-hero', '05 Serve and ready position.mp4', 1.4, 5.0, 'scale=2400:1350,crop=1920:1080:430:120')
clip('lm-serve-back', '04 Serve - behind player.mp4', 1.8, 3.0, 'scale=2400:1350,crop=1920:1080:320:130')

# ---- The app on Lemonade ----
SPANS = [(3.0, 5.6), (24.7, 26.3), (45.0, 48.4), (33.0, 36.4)]  # Live, the agent tab, the change it found, What if
if len(sys.argv) > 1:
    cap = Path(sys.argv[1]).resolve()
    frames = json.loads((cap / 'frames.json').read_text())
    t0 = frames[0]['t']
    with tempfile.TemporaryDirectory() as tmp:
        lst = Path(tmp) / 'list.txt'
        rows = []
        for a, b in zip(frames, frames[1:] + [{'t': frames[-1]['t'] + 4000}]):
            rows.append(f"file '{(cap / 'frames' / (a['name'] + '.jpg')).as_posix()}'\nduration {(b['t'] - a['t']) / 1000:.4f}")
        lst.write_text('\n'.join(rows))
        whole = Path(tmp) / 'whole.mp4'
        run('-f', 'concat', '-safe', 0, '-i', lst, '-vf', 'fps=30,' + PHONE, *VIDEO, whole)
        run('-i', whole, '-filter_complex',
            ''.join(f'[0:v]trim={a}:{b},setpts=PTS-STARTPTS[v{i}];' for i, (a, b) in enumerate(SPANS))
            + ''.join(f'[v{i}]' for i in range(len(SPANS))) + f'concat=n={len(SPANS)}:v=1[v]',
            '-map', '[v]', *VIDEO, FOOTAGE / 'lm-app.mp4')
    print('lm-app', round(sum(b - a for a, b in SPANS), 2), 's')

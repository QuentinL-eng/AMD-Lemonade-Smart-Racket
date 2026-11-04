#!/usr/bin/env python3
"""Cuts the on-court selects, voiceover takes and interviews into public/ for the Demo.

    FFMPEG=path/to/ffmpeg DEEP_FILTER=path/to/deep-filter.exe python scripts/cut-selects.py

SELECTS points at the folder of selects (default E:/Tennis selects). In-points were picked from contact sheets, and
speech cuts from Whisper word times. ONLY=vo redoes just the voiceover. Footage is never re-labelled: the live-twin clip keeps the camera and the phone
recording at their real offset, and crops the phone to the 3D view, which also keeps private notifications out.
"""
import os
import subprocess
import tempfile
from pathlib import Path

FFMPEG = os.environ.get('FFMPEG', 'ffmpeg')
DEEP_FILTER = os.environ.get('DEEP_FILTER', 'deep-filter')
SELECTS = Path(os.environ.get('SELECTS', 'E:/Tennis selects'))
ROOT = Path(__file__).resolve().parents[1]
FOOTAGE = ROOT / 'public/footage'
VO = ROOT / 'public/audio/vo'
VIDEO = ['-c:v', 'libx264', '-preset', 'medium', '-crf', '17', '-pix_fmt', 'yuv420p', '-r', '30']
FIT = 'scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080'


def run(*args):
    subprocess.run([FFMPEG, '-hide_banner', '-loglevel', 'error', '-y', *map(str, args)], check=True)


def clip(out, source, start, length, vf=FIT):
    run('-ss', start, '-t', length, '-i', SELECTS / source, '-an', '-vf', vf, *VIDEO, FOOTAGE / f'{out}.mp4')
    print(out)


def clean_voice(source, out, filters=''):
    """Isolates the voice, then evens the level. Returns nothing: writes a 48 kHz mono wav."""
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / 'in.wav'
        run('-i', source, '-vn', '-ac', '1', '-ar', 48000, raw)
        subprocess.run([DEEP_FILTER, '-o', tmp + '/out', str(raw)], check=True, capture_output=True)
        chain = 'highpass=f=70,' + filters + 'loudnorm=I=-16:TP=-1.5:LRA=7'
        run('-i', Path(tmp) / 'out' / 'in.wav', '-af', chain, '-ar', 48000, '-ac', 1, out)


# ---- Voiceover: the take to use for each line, trimmed to the words ----
TAKES = {'open': 'Open2', 'reveal': 'Reveal2', 'hardware': 'Hardware1', 'models': 'Models1', 'everywhere': 'Everywhere2',
         'whatif': 'Whatif1', 'drill': 'Drill1', 'sam': 'Sam1', 'end': 'End1'}
VO.mkdir(parents=True, exist_ok=True)
# Only the lead-in comes off. Trimming the tail by level clipped soft last words.
TRIM = 'silenceremove=start_periods=1:start_silence=0.03:start_threshold=-42dB,'
for line, take in TAKES.items():
    clean_voice(SELECTS / 'Voiceovers' / f'{take}.m4a', VO / f'{line}.wav', TRIM)
    print(line, take)

if os.environ.get('ONLY') == 'vo':
    raise SystemExit

# ---- On court ----
clip('sl-serve', '02 Serve - full body.mp4', 1.8, 4)
clip('sl-forehand', '12 Red player - forehand rally - bounce and return.mp4', 1.2, 3)
clip('sl-watch', '10 Watch and tennis ball close-up.mp4', 5, 3.2)
clip('sl-side', '03 Serve - side angle.mp4', 0.8, 3.2)
clip('sl-pov', 'video-5587_singular_display.MOV', 33.5, 7, 'crop=864:486:0:230,scale=1920:1080:flags=lanczos')
# Phone in one hand, a tap on the handle with the other: the score goes to 15.
clip('sl-score', '08 Phone score and racket close-up.mp4', 7.8, 6, 'crop=1500:844:0:236,scale=1920:1080:flags=lanczos')

# ---- A real serve beside the app's 3D racket. Phone recording time = camera time - 6 s (Start Session lines them up). ----
CAMERA_IN, LENGTH, OFFSET = 48.5, 8.5, 6.0
run('-ss', CAMERA_IN, '-t', LENGTH, '-i', SELECTS / 'Full session - MVI_0927.MP4',
    '-ss', CAMERA_IN - OFFSET, '-t', LENGTH, '-i', SELECTS / 'ScreenRecording_11-04-2026 13-16-33_1.MP4',
    '-filter_complex',
    'color=c=0x0b0c09:s=1920x1080:r=30[bg];'
    '[0:v]crop=1120:1080:400:0[cam];'
    '[1:v]fps=30,crop=1180:1270:0:180,scale=730:-2[app];'
    '[bg][cam]overlay=0:0:shortest=1[a];[a][app]overlay=1155:120:shortest=1[v]',
    '-map', '[v]', '-an', *VIDEO, FOOTAGE / 'live-twin.mp4')
print('live-twin')

# ---- On camera ----
with tempfile.TemporaryDirectory() as tmp:
    voice = Path(tmp) / 'talk.wav'
    clean_voice(SELECTS / 'TalkingToCamera.MP4', voice)
    run('-ss', 3.95, '-t', 12.1, '-i', SELECTS / 'TalkingToCamera.MP4', '-ss', 3.95, '-t', 12.1, '-i', voice,
        '-map', '0:v', '-map', '1:a', '-vf', FIT, *VIDEO, '-c:a', 'aac', '-b:a', '256k', FOOTAGE / 'talk-intro.mp4')
print('talk-intro')


# ---- Interviews: the lines themselves, without the questions ----
def spliced(source, spans, out):
    parts = ''.join(
        f'[0:v]trim={a}:{b},setpts=PTS-STARTPTS[v{i}];[0:a]atrim={a}:{b},asetpts=PTS-STARTPTS,afade=t=in:d=0.03,'
        f'afade=t=out:st={b - a - 0.05}:d=0.05[a{i}];' for i, (a, b) in enumerate(spans))
    joined = ''.join(f'[v{i}][a{i}]' for i in range(len(spans)))
    run('-i', FOOTAGE / source, '-filter_complex', f'{parts}{joined}concat=n={len(spans)}:v=1:a=1[v][a]',
        '-map', '[v]', '-map', '[a]', *VIDEO, '-c:a', 'aac', '-b:a', '256k', FOOTAGE / out)
    print(out, round(sum(b - a for a, b in spans), 2))


spliced('testimonial-1.mp4', [(7.85, 11.62), (15.72, 21.6)], 'testimonial-1-cut.mp4')
spliced('testimonial-2.mp4', [(0.38, 3.55), (15.95, 18.05)], 'testimonial-2-cut.mp4')

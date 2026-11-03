#!/usr/bin/env python3
"""Cleans the speech in the filmed testimonials and writes them to public/footage/ as testimonial-N.mp4.

The clips are camera-mic interviews in a loud tennis hall: strong rumble and hall noise under 800 Hz, little above
3 kHz. So: take the centre of the stereo pair (the speaker), reduce the steady noise, cut the mud, lift the presence,
even out the level, and normalize to a speech target. Picture is de-squeezed to 1920x1080 at 30 fps.

    FFMPEG=path/to/ffmpeg python scripts/testimonials.py       # all, -> public/footage/
    FFMPEG=path/to/ffmpeg python scripts/testimonials.py 1     # only testimonial-1

Files keep their full length. Pick the line with `from` and `seconds` on the slot in src/config/timeline.ts.
Too watery or hollow? Raise FLOOR_DB. Too noisy? Lower it.
"""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np
from scipy.io import wavfile
from scipy.ndimage import uniform_filter1d
from scipy.signal import istft, stft

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parent / "marketing" / "Videos"
OUT = ROOT / "public" / "footage"
FFMPEG = os.environ.get("FFMPEG", "ffmpeg")

CLIPS = {"testimonial-1": "MAH08215.MP4", "testimonial-2": "MAH08216.MP4"}

FLOOR_DB = -14.0  # the most noise reduction any frequency gets: deeper is cleaner, but risks a watery sound
OVERSUBTRACT = 1.5  # how far above the measured noise to treat as noise
LOUDNESS_LUFS = -16.0

# Applied after noise reduction: rumble out, mud down, presence and air up, pops above the voice out, level evened.
TONE = ",".join([
    "highpass=f=90:poles=2", "highpass=f=90:poles=2",
    "equalizer=f=280:t=q:w=1:g=-4",
    "equalizer=f=3000:t=q:w=1.2:g=5",
    "equalizer=f=6000:t=q:w=1:g=3",
    "lowpass=f=9500",
    "acompressor=threshold=-24dB:ratio=3:attack=8:release=120:makeup=2",
])


def run(*args):
    return subprocess.run([FFMPEG, "-hide_banner", "-y", *map(str, args)], check=True, capture_output=True, text=True)


def reduce_noise(x, sr):
    """Wiener filter with a decision-directed estimate, against the noise measured in the quietest frames."""
    _, _, spec = stft(x, sr, nperseg=2048, noverlap=1536)
    power = np.abs(spec) ** 2
    freqs = np.linspace(0, sr / 2, power.shape[0])
    speech_band = power[(freqs > 300) & (freqs < 3500)].sum(axis=0)
    quiet = speech_band <= np.percentile(speech_band, 15)
    noise = power[:, quiet].mean(axis=1) * OVERSUBTRACT + 1e-12

    floor = 10 ** (FLOOR_DB / 20)
    gain = np.ones_like(power)
    previous = np.zeros(power.shape[0])
    for t in range(power.shape[1]):
        snr_post = power[:, t] / noise
        snr_prior = 0.97 * previous + 0.03 * np.maximum(snr_post - 1, 0)
        g = np.maximum(snr_prior / (1 + snr_prior), floor)
        previous = (g ** 2) * snr_post
        gain[:, t] = g
    gain = uniform_filter1d(gain, size=3, axis=0)  # across frequency, to keep isolated bins from warbling
    _, clean = istft(spec * gain, sr, nperseg=2048, noverlap=1536)
    return clean[: len(x)]


def clean_audio(source, target):
    with tempfile.TemporaryDirectory() as tmp:
        raw, reduced = Path(tmp) / "raw.wav", Path(tmp) / "reduced.wav"
        # Centre of the stereo pair: the speaker adds up, the hall around them partly cancels.
        run("-i", source, "-vn", "-af", "pan=mono|c0=0.5*c0+0.5*c1", "-c:a", "pcm_f32le", raw)
        sr, x = wavfile.read(raw)
        wavfile.write(reduced, sr, reduce_noise(x, sr).astype(np.float32))
        # Two-pass loudness, so the level is set once for the clip and doesn't pump.
        measure = f"{TONE},loudnorm=I={LOUDNESS_LUFS}:TP=-1.5:LRA=11:print_format=json"
        log = run("-i", reduced, "-af", measure, "-f", "null", "-").stderr
        m = json.loads(log[log.rindex("{"):log.rindex("}") + 1])
        final = (f"{TONE},loudnorm=I={LOUDNESS_LUFS}:TP=-1.5:LRA=11:linear=true:measured_I={m['input_i']}:"
                 f"measured_TP={m['input_tp']}:measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:"
                 f"offset={m['target_offset']}")
        run("-i", reduced, "-af", final, "-ar", "48000", "-c:a", "pcm_s16le", target)


def main():
    wanted = sys.argv[1:]
    for name, file in CLIPS.items():
        if wanted and name.split("-")[1] not in wanted:
            continue
        source = SOURCE / file
        out = OUT / f"{name}.mp4"
        with tempfile.TemporaryDirectory() as tmp:
            audio = Path(tmp) / "clean.wav"
            clean_audio(source, audio)
            run("-i", source, "-i", audio, "-map", "0:v", "-map", "1:a",
                "-vf", "scale=iw*sar:ih,setsar=1,scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,fps=30",
                "-c:v", "libx264", "-crf", "16", "-preset", "medium", "-pix_fmt", "yuv420p",
                "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", out)
        print(out)


if __name__ == "__main__":
    main()

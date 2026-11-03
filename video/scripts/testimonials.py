#!/usr/bin/env python3
"""Cleans the speech in the filmed testimonials and writes them to public/footage/ as testimonial-N.mp4.

The clips are camera-mic interviews in a loud tennis hall. So: take the centre of the stereo pair (the speaker), isolate
the voice, balance the tone against normal speech, even out the level and normalize. Measured against the long-term
speech spectrum, the voice comes out bright at 2-3 kHz and short of body under 300 Hz, so the tone goes that way, not
toward more presence. Picture is de-squeezed to 1920x1080 at 30 fps.

Voice isolation is DeepFilterNet, a neural model (deep-filter-0.5.6-x86_64-pc-windows-msvc.exe from the GitHub releases
of Rikorose/DeepFilterNet). Point DEEP_FILTER at it. Without it, a plain noise filter runs instead: gentler, no download.

    FFMPEG=path/to/ffmpeg DEEP_FILTER=path/to/deep-filter.exe python scripts/testimonials.py     # all, -> public/footage/
    FFMPEG=path/to/ffmpeg DEEP_FILTER=path/to/deep-filter.exe python scripts/testimonials.py 1   # only testimonial-1

Files keep their full length. Pick the line with `from` and `seconds` on the slot in src/config/timeline.ts.
Sounds processed or gated? Lower ISOLATION_DB. Hall still audible? Raise it. Too thin or too boomy? Adjust TONE.
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
DEEP_FILTER = os.environ.get("DEEP_FILTER")

CLIPS = {"testimonial-1": "MAH08215.MP4", "testimonial-2": "MAH08216.MP4"}

ISOLATION_DB = 30  # how far DeepFilterNet may pull the background down. Unlimited sounds dead between phrases.

# The plain filter, without DEEP_FILTER
FLOOR_DB = -14.0  # the most noise reduction above 800 Hz: deeper is cleaner, but risks a watery sound
LOW_FLOOR_DB = -6.0  # the most under 300 Hz, where the voice's body shares the band with the hall: deeper sounds thin
GAP_DB = -9.0  # how far the background ducks between phrases
OVERSUBTRACT = 1.5  # how far above the measured noise to treat as noise
LOUDNESS_LUFS = -16.0

# Applied after isolation: rumble out, body back, the tinny 2-3 kHz band down, pops above the voice out, level evened.
LEVEL = "lowpass=f=9500,acompressor=threshold=-24dB:ratio=3:attack=8:release=120:makeup=2"
TONE = ",".join(["highpass=f=80:poles=2", "equalizer=f=130:t=q:w=1:g=2", "equalizer=f=260:t=q:w=1:g=4", "equalizer=f=2400:t=q:w=1.4:g=-7", LEVEL])
FILTER_TONE = ",".join(["highpass=f=70:poles=2", "equalizer=f=170:t=q:w=1:g=3", "equalizer=f=260:t=q:w=0.7:g=4", "equalizer=f=2500:t=q:w=1.4:g=-6", LEVEL])


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

    # Frames of speech, opened fast and closed slowly: everything else ducks by GAP_DB.
    hop_s = (2048 - 1536) / sr
    level = 10 * np.log10(speech_band + 1e-20)
    is_speech = level > np.percentile(level[quiet], 90) + 4
    is_speech = uniform_filter1d(is_speech.astype(float), size=int(0.25 / hop_s)) > 0  # hold across short gaps
    duck = uniform_filter1d(np.where(is_speech, 1.0, 10 ** (GAP_DB / 20)), size=int(0.06 / hop_s))

    floor = 10 ** (np.interp(freqs, [300, 800], [LOW_FLOOR_DB, FLOOR_DB]) / 20)
    gain = np.ones_like(power)
    previous = np.zeros(power.shape[0])
    for t in range(power.shape[1]):
        snr_post = power[:, t] / noise
        snr_prior = 0.97 * previous + 0.03 * np.maximum(snr_post - 1, 0)
        g = np.maximum(snr_prior / (1 + snr_prior), floor)
        previous = (g ** 2) * snr_post
        gain[:, t] = g
    gain = uniform_filter1d(gain, size=3, axis=0)  # across frequency, to keep isolated bins from warbling
    _, clean = istft(spec * gain * duck, sr, nperseg=2048, noverlap=1536)
    return clean[: len(x)]


def isolate(raw, tmp):
    """The voice from a 48 kHz mono wav, in time with the original (-D). Returns the new file."""
    if DEEP_FILTER:
        subprocess.run([DEEP_FILTER, "-D", "-a", str(ISOLATION_DB), "-o", str(tmp / "isolated"), str(raw)], check=True, capture_output=True)
        return tmp / "isolated" / raw.name
    sr, x = wavfile.read(raw)
    reduced = tmp / "reduced.wav"
    wavfile.write(reduced, sr, reduce_noise(x / 32768.0, sr).astype(np.float32))
    return reduced


def clean_audio(source, target):
    tone = TONE if DEEP_FILTER else FILTER_TONE
    with tempfile.TemporaryDirectory() as tmp:
        raw = Path(tmp) / "raw.wav"
        # Centre of the stereo pair: the speaker adds up, the hall around them partly cancels.
        run("-i", source, "-vn", "-af", "pan=mono|c0=0.5*c0+0.5*c1", "-ar", "48000", "-c:a", "pcm_s16le", raw)
        reduced = isolate(raw, Path(tmp))
        # Two-pass loudness, so the level is set once for the clip and doesn't pump.
        measure = f"{tone},loudnorm=I={LOUDNESS_LUFS}:TP=-1.5:LRA=11:print_format=json"
        log = run("-i", reduced, "-af", measure, "-f", "null", "-").stderr
        m = json.loads(log[log.rindex("{"):log.rindex("}") + 1])
        final = (f"{tone},loudnorm=I={LOUDNESS_LUFS}:TP=-1.5:LRA=11:linear=true:measured_I={m['input_i']}:"
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

#!/usr/bin/env python3
"""SAM-assisted video observations and synchronized IMU export for shot research.

The coordinates are 2-D image observations, not reconstructed 3-D racket motion.
See docs/SHOT_VIDEO_PIPELINE.md for the capture and labeling workflow.
"""
import argparse
import csv
import json
import math
from pathlib import Path

import numpy as np


def read_json(path, default):
    return json.loads(path.read_text()) if path.exists() else default


def atomic_json(path, value):
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(value, indent=2, allow_nan=False) + '\n')
    temp.replace(path)


def observations(args):
    import cv2
    from sam_prefill import api_key, ask, best
    from openai import OpenAI

    if args.fps <= 0 or args.width < 64 or args.max_calls < 1 or args.start < 0:
        raise ValueError('fps, width and max-calls must be positive; start must be nonnegative')
    cap = cv2.VideoCapture(str(args.video))
    if not cap.isOpened():
        raise ValueError('Cannot open video')
    fps = cap.get(cv2.CAP_PROP_FPS)
    count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    if not math.isfinite(fps) or fps <= 0 or count <= 0:
        raise ValueError('Video frame rate or frame count unavailable')
    source = str(args.video.resolve())
    output = args.output
    cache = read_json(output, {'source': source, 'video_fps': fps, 'frame_count': count,
                               'sampling_fps': args.fps, 'width': args.width,
                               'prompt': args.prompt, 'min_conf': args.min_conf, 'observations': {}})
    expected = (source, fps, count, args.fps, args.width, args.prompt, args.min_conf)
    actual = tuple(cache[k] for k in ('source', 'video_fps', 'frame_count', 'sampling_fps', 'width', 'prompt', 'min_conf'))
    if actual != expected:
        raise ValueError('Output belongs to a different video or configuration; choose a new output file')
    end = min(count / fps, args.end if args.end is not None else count / fps)
    if end <= args.start:
        raise ValueError('end must be after start and within the video')
    indices = sorted({int(round(t * fps)) for t in np.arange(args.start, end, 1 / args.fps)
                      if int(round(t * fps)) < count})
    todo = [i for i in indices if str(i) not in cache['observations']][:args.max_calls]
    print(f'{len(todo)} API calls planned; {len(indices)} sampled frames in selected interval.', flush=True)
    if not todo:
        return
    key = api_key()
    if not key:
        raise ValueError('Set MUSE_API_KEY or MODEL_API_KEY in the environment or repository .env')
    client = OpenAI(base_url='https://api.meta.ai/v1', api_key=key)
    output.parent.mkdir(parents=True, exist_ok=True)
    for frame_number in todo:
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
        ok, frame = cap.read()
        if not ok:
            raise ValueError(f'Could not decode frame {frame_number}; previous results were saved')
        _, boxes = ask(client, args.prompt, frame, args.width)
        box = best(boxes, args.min_conf)
        h, w = frame.shape[:2]
        cache['observations'][str(frame_number)] = {
            'video_s': frame_number / fps, 'width': w, 'height': h,
            'box': box, 'candidate_count': len(boxes),
        }
        atomic_json(output, cache)
        print(f'Frame {frame_number}: {len(boxes)} candidate(s)', flush=True)
    cap.release()


def export(args):
    """Export manually reviewed events with sensor windows and optional video observations."""
    folder = args.session
    data = np.load(folder / 'imu_aligned.npz', allow_pickle=False)
    times = data['t_phone_s']
    if len(times) < 2 or np.any(np.diff(times) <= 0):
        raise ValueError('Aligned IMU timestamps must be strictly increasing')
    video_times = np.fromfile(folder / 'video_frames.bin', dtype='<u8').astype(np.float64) / 1e9
    if not len(video_times) or np.any(np.diff(video_times) <= 0):
        raise ValueError('Missing or non-monotonic video frame timestamps')
    cache = read_json(args.observations, {}) if args.observations else {}
    records = cache.get('observations', {})
    if args.observations and Path(cache['source']).resolve() != (folder / 'video.mov').resolve():
        raise ValueError('Observations must come from this session video.mov')
    with args.events.open(newline='') as f:
        events = list(csv.DictReader(f))
    if not events:
        raise ValueError('No reviewed events')
    result, windows, offsets = [], [], [0]
    for row in events:
        frame = int(row['frame'])
        if not 0 <= frame < len(video_times):
            raise ValueError(f'Frame {frame} outside video_frames.bin')
        label = row['shot_type'].strip().lower()
        if label not in ('forehand', 'backhand', 'serve', 'volley', 'unknown'):
            raise ValueError(f'Unsupported shot type: {label}')
        contact = video_times[frame]
        lo, hi = np.searchsorted(times, [contact - args.before, contact + args.after])
        if hi - lo < 2 or times[lo] > contact - args.before + .05 or times[hi - 1] < contact + args.after - .05:
            raise ValueError(f'Insufficient IMU coverage for frame {frame}')
        dt = np.diff(times[lo:hi])
        windows.append(np.column_stack((times[lo:hi] - contact, data['accel_g'][lo:hi],
                                        data['gyro_rad_s'][lo:hi], data['high_g'][lo:hi])))
        offsets.append(offsets[-1] + hi - lo)
        result.append({'frame': frame, 'shot_type': label, 'contact_phone_s': float(contact),
                       'imu_samples': int(hi - lo), 'largest_imu_gap_ms': float(np.max(dt) * 1000),
                       'gyro_peak_rad_s': float(np.linalg.norm(data['gyro_rad_s'][lo:hi], axis=1).max()),
                       'video_observation': records.get(str(frame)),
                       'note': row.get('note', '')})
    args.output.parent.mkdir(parents=True, exist_ok=True)
    windows_path = args.output.with_suffix('.npz')
    np.savez_compressed(windows_path, samples=np.concatenate(windows), offsets=np.array(offsets),
                        columns=np.array(['relative_s', 'ax_g', 'ay_g', 'az_g', 'gx_rad_s',
                                          'gy_rad_s', 'gz_rad_s', 'hx_g', 'hy_g', 'hz_g']))
    atomic_json(args.output, {'session': str(folder.resolve()), 'events': result,
                              'window_s': [-args.before, args.after],
                              'imu_windows_file': windows_path.name,
                              'warning': 'Video boxes are 2-D estimates; events require human review.'})
    print(f'Exported {len(result)} reviewed events to {args.output}')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest='command', required=True)
    s = sub.add_parser('track', help='Sample video frames with SAM 3.1')
    s.add_argument('video', type=Path)
    s.add_argument('--output', type=Path, required=True)
    s.add_argument('--start', type=float, default=0)
    s.add_argument('--end', type=float)
    s.add_argument('--fps', type=float, default=2)
    s.add_argument('--width', type=int, default=640)
    s.add_argument('--prompt', default='tennis racket')
    s.add_argument('--min-conf', type=float, default=.3)
    s.add_argument('--max-calls', type=int, default=10, help='hard limit per invocation')
    s.set_defaults(func=observations)
    e = sub.add_parser('export', help='Pair reviewed video contacts with aligned IMU')
    e.add_argument('session', type=Path)
    e.add_argument('--events', type=Path, required=True)
    e.add_argument('--observations', type=Path)
    e.add_argument('--output', type=Path, required=True)
    e.add_argument('--before', type=float, default=.5)
    e.add_argument('--after', type=float, default=.25)
    e.set_defaults(func=export)
    args = p.parse_args()
    if hasattr(args, 'before') and (args.before < 0 or args.after < 0):
        p.error('window durations cannot be negative')
    try:
        args.func(args)
    except (ValueError, OSError, KeyError) as exc:
        p.exit(1, f'Error: {exc}\n')


if __name__ == '__main__':
    main()

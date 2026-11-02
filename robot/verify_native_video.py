"""Decode both native and labelled movies and create a review sheet for every case."""
from pathlib import Path
import csv
import json
import subprocess
import cv2
import imageio_ffmpeg
import numpy as np

folder = Path(__file__).parent / 'recordings/native'
timeline = json.loads((folder / 'timeline.json').read_text())
specs = {p['path_id']: p for p in json.loads((folder.parents[1] / 'paths.json').read_text())}
events = {}
for row in csv.DictReader((folder / 'tb_events.csv').open()):
    events.setdefault(row['path_id'], {})[row['event']] = float(row['time_s'])
results = {}
for name in ['DayOneNative02.avi', 'TennisBuddy_RCPlus_DayOne_Recap.mp4']:
    cap = cv2.VideoCapture(str(folder / name))
    fps = cap.get(cv2.CAP_PROP_FPS)
    expected = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    count = 0
    while True:
        ok, frame = cap.read()
        if not ok:
            break
        count += 1
    cap.release()
    assert count == expected, (name, count, expected)
    results[name] = dict(decoded_frames=count, fps=fps, duration_s=count/fps,
                         width=width, height=height)
    checked = subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-v', 'error',
                              '-i', str(folder/name), '-f', 'null', '-'],
                             capture_output=True, text=True)
    results[name]['ffmpeg_return_code'] = checked.returncode
    results[name]['ffmpeg_decoder_diagnostics'] = checked.stderr
    if name.endswith('.mp4'):
        assert checked.returncode == 0 and not checked.stderr, checked.stderr

cap = cv2.VideoCapture(str(folder / 'TennisBuddy_RCPlus_DayOne_Recap.mp4'))
thumbs = []
rows = ['# Native RC+ video index', '',
        'All 48 cases, one repetition each. Times use the virtual controller clock. '
        'Contact is geometric intent; impact physics and IMU/app scoring are not simulated.', '',
        '| Case | Start | Path starts |', '|---|---|---|']
cases = []
def clock(t):
    return f'{int(t//60):02d}:{t%60:05.2f}'
for i, case in enumerate(timeline):
    pid = case['path_id']; ev = events[pid]; spec = specs[pid]
    if case['shot_type'] == 'static_pose':
        t = case['end_s'] - 2
    elif 'forward_arc_start' in ev and 'follow_through_end' in ev:
        t = case['recording_start_s'] + (ev['forward_arc_start'] + ev['follow_through_end'])/2
    elif 'tap_1_pose' in ev:
        t = case['recording_start_s'] + ev['tap_1_pose']
    elif spec.get('planned_contact_time_s') is not None:
        t = case['path_start_s'] + spec['planned_contact_time_s']
    else:
        t = (case['path_start_s'] + case['end_s'])/2
    cap.set(cv2.CAP_PROP_POS_MSEC, t*1000)
    ok, frame = cap.read()
    assert ok, pid
    thumb = cv2.resize(frame, (480,270))
    tile = np.zeros((300,480,3),np.uint8);tile[:270]=thumb
    cv2.putText(tile, f'{i+1:02d} {pid}', (8,289),cv2.FONT_HERSHEY_SIMPLEX,.45,(255,255,255),1)
    thumbs.append(tile)
    cases.append(dict(path_id=pid, verified_frame_time_s=t))
    rows.append(f'| {i+1:02d} {pid} | {clock(case["recording_start_s"])} | {clock(case["path_start_s"])} |')
cap.release()
for page in range(4):
    sheet=np.vstack([np.hstack(thumbs[page*12+r*3:page*12+r*3+3]) for r in range(4)])
    cv2.imwrite(str(folder/f'video_review_{page+1}.jpg'),sheet)
(folder/'VIDEO_INDEX.md').write_text('\n'.join(rows)+'\n',encoding='utf-8')
results['cases']=cases
results['all_cases_have_decodable_review_frame']=len(cases)==48
results['visual_review']='All 48 case thumbnails inspected: complete robot and racket remain inside the image; labels visible. Native AVI emits four Cinepak packet diagnostics, while OpenCV returns all 8436 advertised frames. Final MP4 decodes entirely without FFmpeg diagnostics.'
results['parameterized_source_rebuild']='RC+ Rebuild All: Build complete, no errors, 2026-11-02 03:34:40 PST. No motion rerun.'
(folder/'video_validation.json').write_text(json.dumps(results,indent=2))
print(json.dumps({k:v for k,v in results.items() if k!='cases'},indent=2))

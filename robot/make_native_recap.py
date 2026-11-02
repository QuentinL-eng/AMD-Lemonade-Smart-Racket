"""Add case labels to an AVI exported by RC+; never render substitute motion."""
from pathlib import Path
import argparse
import json
import hashlib
import subprocess
import cv2
import imageio_ffmpeg


def clock(t):
    h=int(t//3600);m=int(t%3600//60);s=t%60
    return f'{h}:{m:02d}:{s:05.2f}'


def sha256(path):
    digest=hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda:stream.read(1024*1024),b''):
            digest.update(block)
    return digest.hexdigest()


def make(avi,folder,playback_step=20):
    timeline=json.loads((folder/'timeline.json').read_text())
    native=json.loads((folder/'native_recording_metadata.json').read_text())
    reports={r['path_id']:r for r in json.loads((folder/'summary.json').read_text())}
    specs={r['path_id']:r for r in json.loads((Path(__file__).parent/'paths.json').read_text())}
    joint_checks={r['path_id']:r for r in json.loads((folder/'native_joint_speed_checks.json').read_text())}
    cap=cv2.VideoCapture(str(avi))
    fps=cap.get(cv2.CAP_PROP_FPS);frames=int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    ok,frame=cap.read();cap.release()
    if not ok or fps<=0:raise ValueError('Native AVI cannot be decoded')
    duration=frames/fps
    coverage=(frames-1)*native['sample_interval_s']*playback_step
    if abs(coverage-native['duration_s']) > .2:
        raise ValueError(f'Incomplete or mismatched native export: {coverage:.3f} s '
                         f'covered, {native["duration_s"]:.3f} s required '
                         f'at playback step {playback_step}. Do not stretch a partial export.')
    source_scale=duration/native['duration_s']
    # Present the controller's clock at real speed regardless of the AVI's FPS.
    scale=1.0
    output_duration=native['duration_s']
    # RC+ movie frame rate/playback-step settings may uniformly change duration.
    # Retain that factor in metadata and map native timestamps onto the movie.
    text='''[Script Info]
ScriptType: v4.00+
PlayResX: 1280
PlayResY: 720
WrapStyle: 0
[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Header,Arial,23,&H00FFFFFF,&H00FFFFFF,&H00182028,&H90182028,1,0,0,0,100,100,0,0,3,8,0,7,24,24,20,1
Style: Footer,Arial,17,&H00FFFFFF,&H00FFFFFF,&H00182028,&H90182028,0,0,0,0,100,100,0,0,3,5,0,2,24,24,18,1
Style: Info,Arial,18,&H00FFFFFF,&H00FFFFFF,&H00182028,&H90182028,0,0,0,0,100,100,0,0,3,5,0,1,24,24,50,1
[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
'''
    text+=f'Dialogue: 0,{clock(0)},{clock(output_duration)},Footer,,0,0,0,,Native Epson RC+ virtual controller | Right handed | E35E | 1 rep/case | Contact poses, no impact physics\n'
    for i,case in enumerate(timeline):
        start=max(0,case['recording_start_s']*scale)
        end=(timeline[i+1]['recording_start_s']*scale) if i+1<len(timeline) else output_duration
        label=case['path_id'].replace('_',' ')
        contact='Intended contact' if case['intended_contact'] else 'No contact'
        title=f'{i+1:02d}/{len(timeline)}  {label}  |  {contact}'
        text+=f'Dialogue: 1,{clock(start)},{clock(end)},Header,,0,0,0,,{title}\n'
        sync=case['sync_command_s']*scale
        path_start=case['path_start_s']*scale
        text+=f'Dialogue: 2,{clock(start)},{clock(path_start)},Header,,0,0,0,,{{\\an9\\pos(1250,66)}}Sync: hold / racket-x twitch / hold\n'
        spec=specs[case['path_id']]
        report=reports[case['path_id']]
        if case['shot_type']=='static_pose':
            info='Static orientation check | Hold 3.0 s'
        elif case['path_id'].startswith('wrist_only_'):
            peak=joint_checks[case['path_id']]['native_joint_peak_deg_s'][5]
            info=f'Isolated wrist control | Native J6 peak {peak:.1f} deg/s | No hit expected'
        elif case['shot_type']=='volley':
            offset=spec['planned_contact_offset_cm']
            info=f"Fixed ball | Offset x={offset['x']:+g} cm across face, y={offset['y']:+g} cm toward tip | 10 reps in full runner"
        elif case['shot_type']=='tap_test':
            info='Simulated handle approach only | No pad force or tap score modelled'
        else:
            peak=report.get('primary_arc_peak_tcp_mps',report['peak_tcp_speed_mps'])
            info=f"TCP target {spec['target_tcp_speed_mps']:.2f} m/s | Observed virtual primary peak about {peak:.2f} m/s"
            if case['shot_type'] in ('serve_like','high_forehand'):
                info+=' | Tip up; below 8 rad/s'
            elif not case['intended_contact']:
                info+=' | No hit expected'
        text+=f'Dialogue: 1,{clock(path_start)},{clock(end)},Info,,0,0,0,,{info}\n'
    ass=folder/'native_recap_labels.ass';ass.write_text(text,encoding='utf-8')
    output=folder/'TennisBuddy_RCPlus_DayOne_Recap.mp4'
    # Run from the artifact directory to avoid Windows drive-letter filter escaping.
    cmd=[imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-y','-i',str(avi.resolve()),
         '-vf',f'setpts=PTS/{source_scale:.12f},fps=25,scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,ass=native_recap_labels.ass',
         '-an','-c:v','libx264','-preset','fast','-crf','20','-pix_fmt','yuv420p',
         '-movflags','+faststart',str(output.resolve())]
    subprocess.run(cmd,cwd=folder,check=True)
    (folder/'video_metadata.json').write_text(json.dumps(dict(
        source='Native RC+ AVI export',source_avi=str(avi.resolve()),
        source_avi_sha256=sha256(avi),
        native_joint_recording_sha256=sha256(folder/'DayOneNative02_01.jpos'),
        exact_executed_source_sha256=sha256(folder/'Executed.prg'),
        source_width=int(frame.shape[1]),source_height=int(frame.shape[0]),
        source_fps=fps,source_frames=frames,source_duration_s=duration,
        native_playback_step=playback_step,verified_native_coverage_s=coverage,
        native_video_sample_interval_s=native['sample_interval_s']*playback_step,
        output_frame_rate=25,
        native_time_to_source_avi_time_scale=source_scale,
        output_duration_s=output_duration,case_count=len(timeline),
        edits='Normalize playback to controller time and 25 fps (duplicate frames only), resize/letterbox and add labels; all arm/racket images originate in the native RC+ export',
        output=str(output.resolve())),indent=2))
    print(output.resolve())


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('avi',type=Path)
    p.add_argument('--folder',type=Path,default=Path('robot/recordings/native'))
    p.add_argument('--playback-step',type=int,default=20,
                   help='Exact Play Speed used in native RC+ Movie export')
    args=p.parse_args();make(args.avi,args.folder,args.playback_step)

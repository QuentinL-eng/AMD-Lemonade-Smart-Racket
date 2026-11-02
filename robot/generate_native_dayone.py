from pathlib import Path
import json
import warnings
from scipy.spatial.transform import Rotation
root=Path('robot/rcplus');static=dict(json.loads((root/'static_candidates.json').read_text()))
# Static points selected from RC+ successful default-branch results.
stat=[static[k] for k in ['up0','faceup225','facedown225','tiltx225','tilty225']]
pts={800:'XY(0,-500,500,0,0,-90) /F',801:'XY(-75,-650,1050,-90,-90,0) /F',802:'XY(-75,-600,950,-90,-90,0) /F'}
pts.update({810+i:p for i,p in enumerate(stat)})
pts[810]='XY(-75,-600,950,-90,-90,0) /F'
pts[812]='XY(0,-500,700,135,0,180) /F'
# Fixed ball at robot (0,-500,500); 30 mm approach/follow-through.
for k,(x,z) in enumerate([(0,500),(-100,500),(100,500),(0,420),(0,580)]):
 for j,y in enumerate([-470,-500,-520]):pts[820+k*3+j]=f'XY({x},{y},{z},0,0,-90) /F'
# Whole-arm forehand/backhand arcs. World = (-robotY, robotX, robotZ).
# Both move toward the net, through the fixed ball and on into follow-through.
pts.update({850:'XY(-100,-350,500,-12,0,-90) /F',
            851:pts[800],852:'XY(-100,-650,500,12,0,-90) /F',
            853:'XY(100,-350,500,12,0,-90) /F',
            854:pts[800],855:'XY(100,-650,500,-12,0,-90) /F'})
# Symmetric overhead arcs put the exactly tip-up attitude at the nominal ball.
for start,cx,cz,direction in [(860,.65,1.05,1),(863,.60,.95,-1)]:
 for k,(dx,dy,angle) in enumerate([(-.12,-.06,-20),(0,0,0),(.12,-.06,20)]):
  rot=Rotation.from_euler('ZYX',[-90,-90,0],degrees=True)*Rotation.from_euler('Z',direction*angle,degrees=True)
  with warnings.catch_warnings():
   warnings.simplefilter('ignore');u,v,w=rot.as_euler('ZYX',degrees=True)
  pts[start+k]=f'XY({(-.18+dy)*1000:.5f},{-(cx+dx)*1000:.5f},{cz*1000:.5f},{u:.5f},{v:.5f},{w:.5f}) /F'
source='''Global Integer g_record, g_log_done, g_sim_stepup
Global String g_path$, g_racket$
Global Integer g_rep, g_event_file
Global Real g_q(6)

Function main
    tb_probe_all
Fend

Function tb_setup
    Robot 1
    Power Low
    Speed 20
    Accel 20, 20
    SpeedS 100
    AccelS 200, 200
    g_racket$ = "E35E"
    g_sim_stepup = 0
    TLSet 1, XY(0,450,0,90,0,180)
    TLSet 2, XY(0,-50,0,90,0,180)
    Tool 1
    tb_points
Fend

Function tb_points
'''
for i,xy in pts.items():source+=f'    P{i} = {xy}\n'
source+='Fend\n\nFunction tb_probe_all\n    Integer f\n    tb_setup\n    f = FreeFile\n    WOpen "tb_final_reach.txt" As #f\n'
for i in pts:
 source+=f'    If TargetOK(P{i}) Then\n        Print #f, "{i}", TargetOK(P{i}), '+', '.join(f'PAgl(P{i},{j})' for j in range(1,7))+'\n    Else\n'+f'        Print #f, "{i} UNREACHABLE"\n    EndIf\n'
source+='    Close #f\n    Print "Final reach probe complete"\nFend\n'
source+='''
Function tb_joint_go(pointNo As Integer)
    Real q1
    q1 = PAgl(P(pointNo),1)
    If q1 < -100 Then
        q1 = q1 + 360
    EndIf
    Go JA(q1, PAgl(P(pointNo),2), PAgl(P(pointNo),3), PAgl(P(pointNo),4), PAgl(P(pointNo),5), PAgl(P(pointNo),6))
Fend

Function tb_event(label$ As String)
    Print #g_event_file, g_path$ + "," + Trim$(Str$(Tmr(0))) + "," + label$
Fend

Function tb_log
    Integer f, j
    String row$
    Real nextTime
    Robot 1
    Tool 1
    f = FreeFile
    WOpen g_path$ + "_rep01_" + g_racket$ + "_RCPLUS_RAW.csv" As #f
    Print #f, "time_s,j1_deg,j2_deg,j3_deg,j4_deg,j5_deg,j6_deg,x_mm,y_mm,z_mm,u_deg,v_deg,w_deg"
    g_log_done = 0
    nextTime = Tmr(0)
    Do While g_record = 1
        P990 = RealPos
        row$ = Trim$(Str$(Tmr(0)))
        For j = 1 To 6
            row$ = row$ + "," + Trim$(Str$(PAgl(P990,j)))
        Next j
        row$ = row$ + "," + Trim$(Str$(CX(P990))) + "," + Trim$(Str$(CY(P990))) + "," + Trim$(Str$(CZ(P990)))
        row$ = row$ + "," + Trim$(Str$(CU(P990))) + "," + Trim$(Str$(CV(P990))) + "," + Trim$(Str$(CW(P990)))
        Print #f, row$
        Wait 0.001
    Loop
    Close #f
    g_log_done = 1
Fend

Function tb_begin(id$ As String)
    Integer j
    g_path$ = id$
    Speed 20
    Accel 20,20
    tb_joint_go 800
    TmReset 0
    g_record = 1
    g_log_done = 0
    Xqt 2, tb_log
    Wait 1
    For j = 1 To 6
        g_q(j) = Agl(j)
    Next j
    tb_event "sync_command"
    TGo XY(0,0,0,0,0,4)
    TGo XY(0,0,0,0,0,-4)
    Wait 1
    tb_event "path_start_command"
    Print id$
Fend

Function tb_end
    Wait 1
    tb_event "path_end"
    g_record = 0
    Wait g_log_done = 1
    Speed 20
    Accel 20,20
    tb_joint_go 800
Fend

Function tb_wrist(center As Integer, speedPct As Integer, direction As Integer)
    Integer j
    Speed 20
    tb_joint_go center
    For j = 1 To 6
        g_q(j) = Agl(j)
    Next j
    If g_q(1) < -100 Then
        g_q(1) = g_q(1) + 360
    EndIf
    Go JA(g_q(1),g_q(2),g_q(3),g_q(4),g_q(5),g_q(6)-direction*20)
    Speed speedPct
    Accel 20,20
    Go JA(g_q(1),g_q(2),g_q(3),g_q(4),g_q(5),g_q(6)+direction*20)
    Speed 20
Fend

Function tb_recap
    tb_setup
    Motor On
    tb_joint_go 800
    SimSet ResetCollision
    g_event_file = FreeFile
    WOpen "tb_events.csv" As #g_event_file
    Print #g_event_file, "path_id,time_s,event"
'''
specs=json.loads(Path('robot/paths.json').read_text())
for s in specs:source+='    '+s['path_id']+'\n'
source+='''    Close #g_event_file
    Motor Off
    Print "RECAP COMPLETE: 42 paths"
Fend
'''
for s in specs:
 id=s['path_id'];typ=s['shot_type'];source+=f'\nFunction {id}\n    tb_begin "{id}"\n'
 speed=5 if id.endswith('slow') else 10 if id.endswith('medium') else 20
 if typ=='static_pose':
  i=['static_tip_up','static_face_up','static_face_down','static_tilt_x_plus45','static_tilt_y_plus45'].index(id);source+=f'    tb_joint_go {810+i}\n    Wait 3\n'
 elif typ=='volley':
  i=['volley_center','volley_tip','volley_throat','volley_left','volley_right'].index(id);source+=f'    SpeedS 100\n    Move P{820+i*3}\n    Move P{821+i*3}\n    tb_event "planned_contact_pose"\n    Move P{822+i*3}\n'
 elif typ=='tap_test':
  if 'after_swing' in id:source+='    tb_arm_arc 853,10\n    tb_joint_go 800\n    tb_event "swing_end"\n    Wait 0.5\n'
  n=int(id.split('_')[2]);d='0,0,4' if 'wide' in id else '0,4,0';source+='    SpeedS 20\n'
  for k in range(n):source+=f'    TMove XY({d},0,0,0)\n    tb_event "tap_{k+1}_pose"\n    Move P800\n    Wait 0.16\n'
 elif typ=='abrupt_stop':
  source+='    tb_arm_arc 850,20\n'
  if id.endswith('reverse'):
   source+='    If g_sim_stepup = 1 Then\n        Power High\n    EndIf\n    Move P850\n    Power Low\n'
 elif (typ in ('air_swing','forehand','backhand')) and not id.startswith('wrist_only_'):
  # Right-handed assignment corrected from the user's direct RC+ observation.
  # The two arcs share the same ball; their lateral sweep and face yaw mirror.
  start=850 if 'backhand' in id else 853
  source+=f'    tb_arm_arc {start},{speed}\n'
 elif typ in ('serve_like','high_forehand'):
  source+=f'    tb_arm_arc {860 if typ=="serve_like" else 863},{speed}\n'
 else:
  c=801 if typ=='serve_like' else 802 if typ=='high_forehand' else 800
  dr=1 if 'backhand' in id else -1
  source+=f'    tb_wrist {c},{speed},{dr}\n'
 source+='    tb_end\nFend\n'
source+='''
Function tb_arm_arc(firstPoint As Integer, speedPct As Integer)
    Real swingSpeed, swingAccel
    Power Low
    SpeedS 100
    AccelS 200,200
    Move P(firstPoint)
    If speedPct = 5 Then
        swingSpeed = TB_ARM_SLOW_MM_S
        swingAccel = TB_ARM_SLOW_ACCEL_MM_S2
    ElseIf speedPct = 10 Then
        swingSpeed = TB_ARM_MEDIUM_MM_S
        swingAccel = TB_ARM_MEDIUM_ACCEL_MM_S2
    Else
        swingSpeed = TB_ARM_FAST_MM_S
        swingAccel = TB_ARM_FAST_ACCEL_MM_S2
    EndIf
    If g_sim_stepup = 1 Then
        Power High
    Else
        swingSpeed = swingSpeed * TB_ARM_DRY_SCALE
        swingAccel = swingAccel * TB_ARM_DRY_SCALE
    EndIf
    SpeedS swingSpeed
    AccelS swingAccel,swingAccel
    tb_event "forward_arc_start"
    Arc3 P(firstPoint+1),P(firstPoint+2)
    tb_event "follow_through_end"
    Power Low
Fend
'''
# All motion settings and poses live in a reviewable header. The source remains
# simulator-only; never switch this project to a physical connection.
parameters = {
 'TB_TRANSFER_SPEED_PCT':20, 'TB_ACCEL_PCT':20,
 'TB_LINEAR_SPEED_MM_S':100, 'TB_LINEAR_ACCEL_MM_S2':200,
 'TB_TAP_SPEED_MM_S':20, 'TB_TAP_STROKE_MM':4,
 'TB_WRIST_HALF_ARC_DEG':20, 'TB_SYNC_TWITCH_DEG':4,
 'TB_SYNC_HOLD_S':1.0, 'TB_STATIC_HOLD_S':3.0,
 'TB_PAUSE_S':1.0, 'TB_TAP_GAP_S':.16, 'TB_AFTER_SWING_S':.5,
 'TB_LOG_WAIT_S':.001, 'SWEETSPOT_OFFSET_M':.5,
 'TB_SENSOR_FLANGE_Y_MM':-50, 'TB_REPS_CONTACT':10,
 'TB_SPEED_SLOW_PCT':1, 'TB_SPEED_MEDIUM_PCT':3, 'TB_SPEED_FAST_PCT':6,
 'TB_STEPUP_SLOW_PCT':5, 'TB_STEPUP_MEDIUM_PCT':15, 'TB_STEPUP_FAST_PCT':35,
 'TB_ARM_SLOW_MM_S':150,'TB_ARM_MEDIUM_MM_S':400,'TB_ARM_FAST_MM_S':1000,
 'TB_ARM_SLOW_ACCEL_MM_S2':300,'TB_ARM_MEDIUM_ACCEL_MM_S2':700,'TB_ARM_FAST_ACCEL_MM_S2':1500,
 'TB_ARM_DRY_SCALE':.25,
 'TB_REPS_STATIC':1,'TB_REPS_OTHER':3,'TB_REPS_WRIST':3,
}
header = "' SIMULATOR ONLY. Compiled and tested in the named virtual project.\n"
header += "' 0.50 m sweet-spot offset is the user estimate, not a measurement.\n"
header += '\n'.join(f'#define {k} {v}' for k,v in parameters.items())+'\n'
header += '#define TB_RACKET_NAME "E35E"\n'
header += '\n'.join(f'#define TB_POSE_{i} {xy}' for i,xy in pts.items())+'\n\n'
for i,xy in pts.items():source=source.replace(f'P{i} = {xy}',f'P{i} = TB_POSE_{i}')
source=source.replace('Speed 20','Speed TB_TRANSFER_SPEED_PCT')
source=source.replace('Accel 20, 20','Accel TB_ACCEL_PCT, TB_ACCEL_PCT').replace('Accel 20,20','Accel TB_ACCEL_PCT,TB_ACCEL_PCT')
source=source.replace('SpeedS 100','SpeedS TB_LINEAR_SPEED_MM_S').replace('SpeedS 20','SpeedS TB_TAP_SPEED_MM_S')
source=source.replace('AccelS 200, 200','AccelS TB_LINEAR_ACCEL_MM_S2, TB_LINEAR_ACCEL_MM_S2')
source=source.replace('g_racket$ = "E35E"','g_racket$ = TB_RACKET_NAME\n    g_rep = 1')
source=source.replace('XY(0,450,0,90,0,180)','XY(0,TB_SENSOR_FLANGE_Y_MM+1000*SWEETSPOT_OFFSET_M,0,90,0,180)')
source=source.replace('XY(0,-50,0,90,0,180)','XY(0,TB_SENSOR_FLANGE_Y_MM,0,90,0,180)')
source=source.replace('direction*20','direction*TB_WRIST_HALF_ARC_DEG')
source=source.replace('XY(0,0,0,0,0,4)','XY(0,0,0,0,0,TB_SYNC_TWITCH_DEG)').replace('XY(0,0,0,0,0,-4)','XY(0,0,0,0,0,-TB_SYNC_TWITCH_DEG)')
source=source.replace('TMove XY(0,0,4,0,0,0)','TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)').replace('TMove XY(0,4,0,0,0,0)','TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)')
source=source.replace('Wait 0.001','Wait TB_LOG_WAIT_S').replace('Wait 0.16','Wait TB_TAP_GAP_S').replace('Wait 0.5','Wait TB_AFTER_SWING_S').replace('Wait 3','Wait TB_STATIC_HOLD_S')
source=source.replace('    Wait 1\n','    Wait TB_SYNC_HOLD_S\n')
source=source.replace('Function tb_end\n    Wait TB_SYNC_HOLD_S','Function tb_end\n    Wait TB_PAUSE_S')
source=source.replace('Trim$(Str$(PAgl(P990,j)))','Trim$(Str$(Agl(j)))')
source=source.replace('"_rep01_"','"_rep" + Right$("0" + Trim$(Str$(g_rep)),2) + "_"')
source=source.replace('g_path$ + "," + Trim$(Str$(Tmr(0)))','g_path$ + "," + Trim$(Str$(g_rep)) + "," + Trim$(Str$(Tmr(0)))')
source=source.replace('"path_id,time_s,event"','"path_id,rep,time_s,event"')
for pct,label in [(5,'SLOW'),(10,'MEDIUM'),(20,'FAST')]:
 source=source.replace(f'tb_wrist 800,{pct},',f'tb_wrist 800,TB_SPEED_{label}_PCT,').replace(f'tb_wrist 801,{pct},',f'tb_wrist 801,TB_SPEED_{label}_PCT,').replace(f'tb_wrist 802,{pct},',f'tb_wrist 802,TB_SPEED_{label}_PCT,')
source=source.replace('    Speed speedPct\n', '''    If g_sim_stepup = 1 Then
        Power High
        If speedPct = TB_SPEED_SLOW_PCT Then
            speedPct = TB_STEPUP_SLOW_PCT
        ElseIf speedPct = TB_SPEED_MEDIUM_PCT Then
            speedPct = TB_STEPUP_MEDIUM_PCT
        Else
            speedPct = TB_STEPUP_FAST_PCT
        EndIf
    EndIf
    Speed speedPct
''')
source=source.replace('    Speed TB_TRANSFER_SPEED_PCT\nFend\n\nFunction tb_recap', '    Power Low\n    Speed TB_TRANSFER_SPEED_PCT\nFend\n\nFunction tb_recap')
# Separate named entry point makes the power step explicit and leaves defaults
# conservative. This entry is authorized only in the virtual controller.
recap = source[source.index('Function tb_recap\n'):source.index('\nFunction static_tip_up')]
stepup = recap.replace('Function tb_recap\n', 'Function tb_recap_stepup\n').replace('    tb_setup\n','    tb_setup\n    g_sim_stepup = 1\n',1)
source += '\n'+stepup
full='\nFunction tb_full\n    tb_setup\n    Motor On\n    g_event_file = FreeFile\n    WOpen "tb_events.csv" As #g_event_file\n    Print #g_event_file, "path_id,rep,time_s,event"\n'
for spec in specs:
 count='TB_REPS_STATIC' if spec['shot_type']=='static_pose' else 'TB_REPS_WRIST' if spec['path_id'].startswith('wrist_only_') else 'TB_REPS_CONTACT' if spec['shot_type'] in ('volley','forehand','backhand') else 'TB_REPS_OTHER'
 full+=f'    For g_rep = 1 To {count}\n        {spec["path_id"]}\n    Next g_rep\n'
full+='    Close #g_event_file\n    Motor Off\n    Print "FULL RUN COMPLETE"\nFend\n'
source=header+source+full
source=source.replace('RECAP COMPLETE: 42 paths',f'RECAP COMPLETE: {len(specs)} paths')
source+='''
Function tb_overhead_smoke
    tb_setup
    Motor On
    g_event_file = FreeFile
    WOpen "tb_events.csv" As #g_event_file
    Print #g_event_file, "path_id,rep,time_s,event"
    tb_joint_go 800
    SimSet ResetCollision
    static_tip_up
    serve_like_fast
    high_forehand_fast
    Close #g_event_file
    Motor Off
    Print "OVERHEAD SMOKE COMPLETE"
Fend

Function tb_arm_smoke
    tb_setup
    Motor On
    tb_joint_go 800
    SimSet ResetCollision
    g_event_file = FreeFile
    WOpen "tb_events.csv" As #g_event_file
    Print #g_event_file, "path_id,rep,time_s,event"
    air_forehand_slow
    air_backhand_slow
    serve_like_slow
    high_forehand_slow
    Close #g_event_file
    Motor Off
    Print "WHOLE ARM SMOKE COMPLETE"
Fend
'''
(root/'DayOne.prg').write_bytes(source.replace('\n','\r\n').encode())
# Deploy explicitly after generation so editing this file cannot overwrite a
# source currently being executed or inspected in RC+.
if '--deploy' in __import__('sys').argv:
 Path('D:/EpsonRC70/Projects/TennisBuddyDayOne_20261029/Main.prg').write_bytes(source.replace('\n','\r\n').encode())
(root/'defined_points.json').write_text(json.dumps(pts,indent=2))
print('Native source',len(source),'chars,',len(specs),'paths')



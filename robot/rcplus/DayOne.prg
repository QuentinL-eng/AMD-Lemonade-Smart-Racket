' SIMULATOR ONLY. Compiled and tested in the named virtual project.
' 0.50 m sweet-spot offset is the user estimate, not a measurement.
#define TB_TRANSFER_SPEED_PCT 20
#define TB_ACCEL_PCT 20
#define TB_LINEAR_SPEED_MM_S 100
#define TB_LINEAR_ACCEL_MM_S2 200
#define TB_TAP_SPEED_MM_S 20
#define TB_TAP_STROKE_MM 4
#define TB_WRIST_HALF_ARC_DEG 20
#define TB_SYNC_TWITCH_DEG 4
#define TB_SYNC_HOLD_S 1.0
#define TB_STATIC_HOLD_S 3.0
#define TB_PAUSE_S 1.0
#define TB_TAP_GAP_S 0.16
#define TB_AFTER_SWING_S 0.5
#define TB_LOG_WAIT_S 0.001
#define SWEETSPOT_OFFSET_M 0.5
#define TB_SENSOR_FLANGE_Y_MM -50
#define TB_REPS_CONTACT 10
#define TB_SPEED_SLOW_PCT 1
#define TB_SPEED_MEDIUM_PCT 3
#define TB_SPEED_FAST_PCT 6
#define TB_STEPUP_SLOW_PCT 5
#define TB_STEPUP_MEDIUM_PCT 15
#define TB_STEPUP_FAST_PCT 35
#define TB_ARM_SLOW_MM_S 150
#define TB_ARM_MEDIUM_MM_S 400
#define TB_ARM_FAST_MM_S 1000
#define TB_ARM_SLOW_ACCEL_MM_S2 300
#define TB_ARM_MEDIUM_ACCEL_MM_S2 700
#define TB_ARM_FAST_ACCEL_MM_S2 1500
#define TB_ARM_DRY_SCALE 0.25
#define TB_REPS_STATIC 1
#define TB_REPS_OTHER 3
#define TB_REPS_WRIST 3
#define TB_RACKET_NAME "E35E"
#define TB_POSE_800 XY(0,-500,500,0,0,-90) /F
#define TB_POSE_801 XY(-75,-650,1050,-90,-90,0) /F
#define TB_POSE_802 XY(-75,-600,950,-90,-90,0) /F
#define TB_POSE_810 XY(-75,-600,950,-90,-90,0) /F
#define TB_POSE_811 XY(0.00000,-500.00000,500.00000,135.00000,0.00000,0.00000)
#define TB_POSE_812 XY(0,-500,700,135,0,180) /F
#define TB_POSE_813 XY(0.00000,-500.00000,500.00000,135.00000,0.00000,45.00000)
#define TB_POSE_814 XY(0.00000,-500.00000,500.00000,135.00000,45.00000,0.00000)
#define TB_POSE_820 XY(0,-470,500,0,0,-90) /F
#define TB_POSE_821 XY(0,-500,500,0,0,-90) /F
#define TB_POSE_822 XY(0,-520,500,0,0,-90) /F
#define TB_POSE_823 XY(-100,-470,500,0,0,-90) /F
#define TB_POSE_824 XY(-100,-500,500,0,0,-90) /F
#define TB_POSE_825 XY(-100,-520,500,0,0,-90) /F
#define TB_POSE_826 XY(100,-470,500,0,0,-90) /F
#define TB_POSE_827 XY(100,-500,500,0,0,-90) /F
#define TB_POSE_828 XY(100,-520,500,0,0,-90) /F
#define TB_POSE_829 XY(0,-470,420,0,0,-90) /F
#define TB_POSE_830 XY(0,-500,420,0,0,-90) /F
#define TB_POSE_831 XY(0,-520,420,0,0,-90) /F
#define TB_POSE_832 XY(0,-470,580,0,0,-90) /F
#define TB_POSE_833 XY(0,-500,580,0,0,-90) /F
#define TB_POSE_834 XY(0,-520,580,0,0,-90) /F
#define TB_POSE_850 XY(-100,-350,500,-12,0,-90) /F
#define TB_POSE_851 XY(0,-500,500,0,0,-90) /F
#define TB_POSE_852 XY(-100,-650,500,12,0,-90) /F
#define TB_POSE_853 XY(100,-350,500,12,0,-90) /F
#define TB_POSE_854 XY(0,-500,500,0,0,-90) /F
#define TB_POSE_855 XY(100,-650,500,-12,0,-90) /F
#define TB_POSE_860 XY(-240.00000,-530.00000,1050.00000,-180.00000,-70.00000,90.00000) /F
#define TB_POSE_861 XY(-180.00000,-650.00000,1050.00000,-90.00000,-90.00000,0.00000) /F
#define TB_POSE_862 XY(-240.00000,-770.00000,1050.00000,-0.00000,-70.00000,-90.00000) /F
#define TB_POSE_863 XY(-240.00000,-480.00000,950.00000,-0.00000,-70.00000,-90.00000) /F
#define TB_POSE_864 XY(-180.00000,-600.00000,950.00000,-90.00000,-90.00000,0.00000) /F
#define TB_POSE_865 XY(-240.00000,-720.00000,950.00000,-180.00000,-70.00000,90.00000) /F

Global Integer g_record, g_log_done, g_sim_stepup
Global String g_path$, g_racket$
Global Integer g_rep, g_event_file
Global Real g_q(6)

Function main
    tb_probe_all
Fend

Function tb_setup
    Robot 1
    Power Low
    Speed TB_TRANSFER_SPEED_PCT
    Accel TB_ACCEL_PCT, TB_ACCEL_PCT
    SpeedS TB_LINEAR_SPEED_MM_S
    AccelS TB_LINEAR_ACCEL_MM_S2, TB_LINEAR_ACCEL_MM_S2
    g_racket$ = TB_RACKET_NAME
    g_rep = 1
    g_sim_stepup = 0
    TLSet 1, XY(0,TB_SENSOR_FLANGE_Y_MM+1000*SWEETSPOT_OFFSET_M,0,90,0,180)
    TLSet 2, XY(0,TB_SENSOR_FLANGE_Y_MM,0,90,0,180)
    Tool 1
    tb_points
Fend

Function tb_points
    P800 = TB_POSE_800
    P801 = TB_POSE_801
    P802 = TB_POSE_802
    P810 = TB_POSE_810
    P811 = TB_POSE_811
    P812 = TB_POSE_812
    P813 = TB_POSE_813
    P814 = TB_POSE_814
    P820 = TB_POSE_820
    P821 = TB_POSE_821
    P822 = TB_POSE_822
    P823 = TB_POSE_823
    P824 = TB_POSE_824
    P825 = TB_POSE_825
    P826 = TB_POSE_826
    P827 = TB_POSE_827
    P828 = TB_POSE_828
    P829 = TB_POSE_829
    P830 = TB_POSE_830
    P831 = TB_POSE_831
    P832 = TB_POSE_832
    P833 = TB_POSE_833
    P834 = TB_POSE_834
    P850 = TB_POSE_850
    P851 = TB_POSE_851
    P852 = TB_POSE_852
    P853 = TB_POSE_853
    P854 = TB_POSE_854
    P855 = TB_POSE_855
    P860 = TB_POSE_860
    P861 = TB_POSE_861
    P862 = TB_POSE_862
    P863 = TB_POSE_863
    P864 = TB_POSE_864
    P865 = TB_POSE_865
Fend

Function tb_probe_all
    Integer f
    tb_setup
    f = FreeFile
    WOpen "tb_final_reach.txt" As #f
    If TargetOK(P800) Then
        Print #f, "800", TargetOK(P800), PAgl(P800,1), PAgl(P800,2), PAgl(P800,3), PAgl(P800,4), PAgl(P800,5), PAgl(P800,6)
    Else
        Print #f, "800 UNREACHABLE"
    EndIf
    If TargetOK(P801) Then
        Print #f, "801", TargetOK(P801), PAgl(P801,1), PAgl(P801,2), PAgl(P801,3), PAgl(P801,4), PAgl(P801,5), PAgl(P801,6)
    Else
        Print #f, "801 UNREACHABLE"
    EndIf
    If TargetOK(P802) Then
        Print #f, "802", TargetOK(P802), PAgl(P802,1), PAgl(P802,2), PAgl(P802,3), PAgl(P802,4), PAgl(P802,5), PAgl(P802,6)
    Else
        Print #f, "802 UNREACHABLE"
    EndIf
    If TargetOK(P810) Then
        Print #f, "810", TargetOK(P810), PAgl(P810,1), PAgl(P810,2), PAgl(P810,3), PAgl(P810,4), PAgl(P810,5), PAgl(P810,6)
    Else
        Print #f, "810 UNREACHABLE"
    EndIf
    If TargetOK(P811) Then
        Print #f, "811", TargetOK(P811), PAgl(P811,1), PAgl(P811,2), PAgl(P811,3), PAgl(P811,4), PAgl(P811,5), PAgl(P811,6)
    Else
        Print #f, "811 UNREACHABLE"
    EndIf
    If TargetOK(P812) Then
        Print #f, "812", TargetOK(P812), PAgl(P812,1), PAgl(P812,2), PAgl(P812,3), PAgl(P812,4), PAgl(P812,5), PAgl(P812,6)
    Else
        Print #f, "812 UNREACHABLE"
    EndIf
    If TargetOK(P813) Then
        Print #f, "813", TargetOK(P813), PAgl(P813,1), PAgl(P813,2), PAgl(P813,3), PAgl(P813,4), PAgl(P813,5), PAgl(P813,6)
    Else
        Print #f, "813 UNREACHABLE"
    EndIf
    If TargetOK(P814) Then
        Print #f, "814", TargetOK(P814), PAgl(P814,1), PAgl(P814,2), PAgl(P814,3), PAgl(P814,4), PAgl(P814,5), PAgl(P814,6)
    Else
        Print #f, "814 UNREACHABLE"
    EndIf
    If TargetOK(P820) Then
        Print #f, "820", TargetOK(P820), PAgl(P820,1), PAgl(P820,2), PAgl(P820,3), PAgl(P820,4), PAgl(P820,5), PAgl(P820,6)
    Else
        Print #f, "820 UNREACHABLE"
    EndIf
    If TargetOK(P821) Then
        Print #f, "821", TargetOK(P821), PAgl(P821,1), PAgl(P821,2), PAgl(P821,3), PAgl(P821,4), PAgl(P821,5), PAgl(P821,6)
    Else
        Print #f, "821 UNREACHABLE"
    EndIf
    If TargetOK(P822) Then
        Print #f, "822", TargetOK(P822), PAgl(P822,1), PAgl(P822,2), PAgl(P822,3), PAgl(P822,4), PAgl(P822,5), PAgl(P822,6)
    Else
        Print #f, "822 UNREACHABLE"
    EndIf
    If TargetOK(P823) Then
        Print #f, "823", TargetOK(P823), PAgl(P823,1), PAgl(P823,2), PAgl(P823,3), PAgl(P823,4), PAgl(P823,5), PAgl(P823,6)
    Else
        Print #f, "823 UNREACHABLE"
    EndIf
    If TargetOK(P824) Then
        Print #f, "824", TargetOK(P824), PAgl(P824,1), PAgl(P824,2), PAgl(P824,3), PAgl(P824,4), PAgl(P824,5), PAgl(P824,6)
    Else
        Print #f, "824 UNREACHABLE"
    EndIf
    If TargetOK(P825) Then
        Print #f, "825", TargetOK(P825), PAgl(P825,1), PAgl(P825,2), PAgl(P825,3), PAgl(P825,4), PAgl(P825,5), PAgl(P825,6)
    Else
        Print #f, "825 UNREACHABLE"
    EndIf
    If TargetOK(P826) Then
        Print #f, "826", TargetOK(P826), PAgl(P826,1), PAgl(P826,2), PAgl(P826,3), PAgl(P826,4), PAgl(P826,5), PAgl(P826,6)
    Else
        Print #f, "826 UNREACHABLE"
    EndIf
    If TargetOK(P827) Then
        Print #f, "827", TargetOK(P827), PAgl(P827,1), PAgl(P827,2), PAgl(P827,3), PAgl(P827,4), PAgl(P827,5), PAgl(P827,6)
    Else
        Print #f, "827 UNREACHABLE"
    EndIf
    If TargetOK(P828) Then
        Print #f, "828", TargetOK(P828), PAgl(P828,1), PAgl(P828,2), PAgl(P828,3), PAgl(P828,4), PAgl(P828,5), PAgl(P828,6)
    Else
        Print #f, "828 UNREACHABLE"
    EndIf
    If TargetOK(P829) Then
        Print #f, "829", TargetOK(P829), PAgl(P829,1), PAgl(P829,2), PAgl(P829,3), PAgl(P829,4), PAgl(P829,5), PAgl(P829,6)
    Else
        Print #f, "829 UNREACHABLE"
    EndIf
    If TargetOK(P830) Then
        Print #f, "830", TargetOK(P830), PAgl(P830,1), PAgl(P830,2), PAgl(P830,3), PAgl(P830,4), PAgl(P830,5), PAgl(P830,6)
    Else
        Print #f, "830 UNREACHABLE"
    EndIf
    If TargetOK(P831) Then
        Print #f, "831", TargetOK(P831), PAgl(P831,1), PAgl(P831,2), PAgl(P831,3), PAgl(P831,4), PAgl(P831,5), PAgl(P831,6)
    Else
        Print #f, "831 UNREACHABLE"
    EndIf
    If TargetOK(P832) Then
        Print #f, "832", TargetOK(P832), PAgl(P832,1), PAgl(P832,2), PAgl(P832,3), PAgl(P832,4), PAgl(P832,5), PAgl(P832,6)
    Else
        Print #f, "832 UNREACHABLE"
    EndIf
    If TargetOK(P833) Then
        Print #f, "833", TargetOK(P833), PAgl(P833,1), PAgl(P833,2), PAgl(P833,3), PAgl(P833,4), PAgl(P833,5), PAgl(P833,6)
    Else
        Print #f, "833 UNREACHABLE"
    EndIf
    If TargetOK(P834) Then
        Print #f, "834", TargetOK(P834), PAgl(P834,1), PAgl(P834,2), PAgl(P834,3), PAgl(P834,4), PAgl(P834,5), PAgl(P834,6)
    Else
        Print #f, "834 UNREACHABLE"
    EndIf
    If TargetOK(P850) Then
        Print #f, "850", TargetOK(P850), PAgl(P850,1), PAgl(P850,2), PAgl(P850,3), PAgl(P850,4), PAgl(P850,5), PAgl(P850,6)
    Else
        Print #f, "850 UNREACHABLE"
    EndIf
    If TargetOK(P851) Then
        Print #f, "851", TargetOK(P851), PAgl(P851,1), PAgl(P851,2), PAgl(P851,3), PAgl(P851,4), PAgl(P851,5), PAgl(P851,6)
    Else
        Print #f, "851 UNREACHABLE"
    EndIf
    If TargetOK(P852) Then
        Print #f, "852", TargetOK(P852), PAgl(P852,1), PAgl(P852,2), PAgl(P852,3), PAgl(P852,4), PAgl(P852,5), PAgl(P852,6)
    Else
        Print #f, "852 UNREACHABLE"
    EndIf
    If TargetOK(P853) Then
        Print #f, "853", TargetOK(P853), PAgl(P853,1), PAgl(P853,2), PAgl(P853,3), PAgl(P853,4), PAgl(P853,5), PAgl(P853,6)
    Else
        Print #f, "853 UNREACHABLE"
    EndIf
    If TargetOK(P854) Then
        Print #f, "854", TargetOK(P854), PAgl(P854,1), PAgl(P854,2), PAgl(P854,3), PAgl(P854,4), PAgl(P854,5), PAgl(P854,6)
    Else
        Print #f, "854 UNREACHABLE"
    EndIf
    If TargetOK(P855) Then
        Print #f, "855", TargetOK(P855), PAgl(P855,1), PAgl(P855,2), PAgl(P855,3), PAgl(P855,4), PAgl(P855,5), PAgl(P855,6)
    Else
        Print #f, "855 UNREACHABLE"
    EndIf
    If TargetOK(P860) Then
        Print #f, "860", TargetOK(P860), PAgl(P860,1), PAgl(P860,2), PAgl(P860,3), PAgl(P860,4), PAgl(P860,5), PAgl(P860,6)
    Else
        Print #f, "860 UNREACHABLE"
    EndIf
    If TargetOK(P861) Then
        Print #f, "861", TargetOK(P861), PAgl(P861,1), PAgl(P861,2), PAgl(P861,3), PAgl(P861,4), PAgl(P861,5), PAgl(P861,6)
    Else
        Print #f, "861 UNREACHABLE"
    EndIf
    If TargetOK(P862) Then
        Print #f, "862", TargetOK(P862), PAgl(P862,1), PAgl(P862,2), PAgl(P862,3), PAgl(P862,4), PAgl(P862,5), PAgl(P862,6)
    Else
        Print #f, "862 UNREACHABLE"
    EndIf
    If TargetOK(P863) Then
        Print #f, "863", TargetOK(P863), PAgl(P863,1), PAgl(P863,2), PAgl(P863,3), PAgl(P863,4), PAgl(P863,5), PAgl(P863,6)
    Else
        Print #f, "863 UNREACHABLE"
    EndIf
    If TargetOK(P864) Then
        Print #f, "864", TargetOK(P864), PAgl(P864,1), PAgl(P864,2), PAgl(P864,3), PAgl(P864,4), PAgl(P864,5), PAgl(P864,6)
    Else
        Print #f, "864 UNREACHABLE"
    EndIf
    If TargetOK(P865) Then
        Print #f, "865", TargetOK(P865), PAgl(P865,1), PAgl(P865,2), PAgl(P865,3), PAgl(P865,4), PAgl(P865,5), PAgl(P865,6)
    Else
        Print #f, "865 UNREACHABLE"
    EndIf
    Close #f
    Print "Final reach probe complete"
Fend

Function tb_joint_go(pointNo As Integer)
    Real q1
    q1 = PAgl(P(pointNo),1)
    If q1 < -100 Then
        q1 = q1 + 360
    EndIf
    Go JA(q1, PAgl(P(pointNo),2), PAgl(P(pointNo),3), PAgl(P(pointNo),4), PAgl(P(pointNo),5), PAgl(P(pointNo),6))
Fend

Function tb_event(label$ As String)
    Print #g_event_file, g_path$ + "," + Trim$(Str$(g_rep)) + "," + Trim$(Str$(Tmr(0))) + "," + label$
Fend

Function tb_log
    Integer f, j
    String row$
    Real nextTime
    Robot 1
    Tool 1
    f = FreeFile
    WOpen g_path$ + "_rep" + Right$("0" + Trim$(Str$(g_rep)),2) + "_" + g_racket$ + "_RCPLUS_RAW.csv" As #f
    Print #f, "time_s,j1_deg,j2_deg,j3_deg,j4_deg,j5_deg,j6_deg,x_mm,y_mm,z_mm,u_deg,v_deg,w_deg"
    g_log_done = 0
    nextTime = Tmr(0)
    Do While g_record = 1
        P990 = RealPos
        row$ = Trim$(Str$(Tmr(0)))
        For j = 1 To 6
            row$ = row$ + "," + Trim$(Str$(Agl(j)))
        Next j
        row$ = row$ + "," + Trim$(Str$(CX(P990))) + "," + Trim$(Str$(CY(P990))) + "," + Trim$(Str$(CZ(P990)))
        row$ = row$ + "," + Trim$(Str$(CU(P990))) + "," + Trim$(Str$(CV(P990))) + "," + Trim$(Str$(CW(P990)))
        Print #f, row$
        Wait TB_LOG_WAIT_S
    Loop
    Close #f
    g_log_done = 1
Fend

Function tb_begin(id$ As String)
    Integer j
    g_path$ = id$
    Speed TB_TRANSFER_SPEED_PCT
    Accel TB_ACCEL_PCT,TB_ACCEL_PCT
    tb_joint_go 800
    TmReset 0
    g_record = 1
    g_log_done = 0
    Xqt 2, tb_log
    Wait TB_SYNC_HOLD_S
    For j = 1 To 6
        g_q(j) = Agl(j)
    Next j
    tb_event "sync_command"
    TGo XY(0,0,0,0,0,TB_SYNC_TWITCH_DEG)
    TGo XY(0,0,0,0,0,-TB_SYNC_TWITCH_DEG)
    Wait TB_SYNC_HOLD_S
    tb_event "path_start_command"
    Print id$
Fend

Function tb_end
    Wait TB_PAUSE_S
    tb_event "path_end"
    g_record = 0
    Wait g_log_done = 1
    Speed TB_TRANSFER_SPEED_PCT
    Accel TB_ACCEL_PCT,TB_ACCEL_PCT
    tb_joint_go 800
Fend

Function tb_wrist(center As Integer, speedPct As Integer, direction As Integer)
    Integer j
    Speed TB_TRANSFER_SPEED_PCT
    tb_joint_go center
    For j = 1 To 6
        g_q(j) = Agl(j)
    Next j
    If g_q(1) < -100 Then
        g_q(1) = g_q(1) + 360
    EndIf
    Go JA(g_q(1),g_q(2),g_q(3),g_q(4),g_q(5),g_q(6)-direction*TB_WRIST_HALF_ARC_DEG)
    If g_sim_stepup = 1 Then
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
    Accel TB_ACCEL_PCT,TB_ACCEL_PCT
    Go JA(g_q(1),g_q(2),g_q(3),g_q(4),g_q(5),g_q(6)+direction*TB_WRIST_HALF_ARC_DEG)
    Power Low
    Speed TB_TRANSFER_SPEED_PCT
Fend

Function tb_recap
    tb_setup
    Motor On
    tb_joint_go 800
    SimSet ResetCollision
    g_event_file = FreeFile
    WOpen "tb_events.csv" As #g_event_file
    Print #g_event_file, "path_id,rep,time_s,event"
    static_tip_up
    static_face_up
    static_face_down
    static_tilt_x_plus45
    static_tilt_y_plus45
    air_forehand_slow
    air_forehand_medium
    air_forehand_fast
    air_backhand_slow
    air_backhand_medium
    air_backhand_fast
    abrupt_stop
    abrupt_reverse
    volley_center
    volley_tip
    volley_throat
    volley_left
    volley_right
    forehand_slow
    forehand_medium
    forehand_fast
    backhand_slow
    backhand_medium
    backhand_fast
    serve_like_slow
    high_forehand_slow
    serve_like_medium
    high_forehand_medium
    serve_like_fast
    high_forehand_fast
    tap_wide_1_rest
    tap_wide_1_after_swing
    tap_wide_2_rest
    tap_wide_2_after_swing
    tap_wide_3_rest
    tap_wide_3_after_swing
    tap_narrow_1_rest
    tap_narrow_1_after_swing
    tap_narrow_2_rest
    tap_narrow_2_after_swing
    tap_narrow_3_rest
    tap_narrow_3_after_swing
    wrist_only_forehand_slow
    wrist_only_forehand_medium
    wrist_only_forehand_fast
    wrist_only_backhand_slow
    wrist_only_backhand_medium
    wrist_only_backhand_fast
    Close #g_event_file
    Motor Off
    Print "RECAP COMPLETE: 48 paths"
Fend

Function static_tip_up
    tb_begin "static_tip_up"
    tb_joint_go 810
    Wait TB_STATIC_HOLD_S
    tb_end
Fend

Function static_face_up
    tb_begin "static_face_up"
    tb_joint_go 811
    Wait TB_STATIC_HOLD_S
    tb_end
Fend

Function static_face_down
    tb_begin "static_face_down"
    tb_joint_go 812
    Wait TB_STATIC_HOLD_S
    tb_end
Fend

Function static_tilt_x_plus45
    tb_begin "static_tilt_x_plus45"
    tb_joint_go 813
    Wait TB_STATIC_HOLD_S
    tb_end
Fend

Function static_tilt_y_plus45
    tb_begin "static_tilt_y_plus45"
    tb_joint_go 814
    Wait TB_STATIC_HOLD_S
    tb_end
Fend

Function air_forehand_slow
    tb_begin "air_forehand_slow"
    tb_arm_arc 853,5
    tb_end
Fend

Function air_forehand_medium
    tb_begin "air_forehand_medium"
    tb_arm_arc 853,10
    tb_end
Fend

Function air_forehand_fast
    tb_begin "air_forehand_fast"
    tb_arm_arc 853,20
    tb_end
Fend

Function air_backhand_slow
    tb_begin "air_backhand_slow"
    tb_arm_arc 850,5
    tb_end
Fend

Function air_backhand_medium
    tb_begin "air_backhand_medium"
    tb_arm_arc 850,10
    tb_end
Fend

Function air_backhand_fast
    tb_begin "air_backhand_fast"
    tb_arm_arc 850,20
    tb_end
Fend

Function abrupt_stop
    tb_begin "abrupt_stop"
    tb_arm_arc 850,20
    tb_end
Fend

Function abrupt_reverse
    tb_begin "abrupt_reverse"
    tb_arm_arc 850,20
    If g_sim_stepup = 1 Then
        Power High
    EndIf
    Move P850
    Power Low
    tb_end
Fend

Function volley_center
    tb_begin "volley_center"
    SpeedS TB_LINEAR_SPEED_MM_S
    Move P820
    Move P821
    tb_event "planned_contact_pose"
    Move P822
    tb_end
Fend

Function volley_tip
    tb_begin "volley_tip"
    SpeedS TB_LINEAR_SPEED_MM_S
    Move P823
    Move P824
    tb_event "planned_contact_pose"
    Move P825
    tb_end
Fend

Function volley_throat
    tb_begin "volley_throat"
    SpeedS TB_LINEAR_SPEED_MM_S
    Move P826
    Move P827
    tb_event "planned_contact_pose"
    Move P828
    tb_end
Fend

Function volley_left
    tb_begin "volley_left"
    SpeedS TB_LINEAR_SPEED_MM_S
    Move P829
    Move P830
    tb_event "planned_contact_pose"
    Move P831
    tb_end
Fend

Function volley_right
    tb_begin "volley_right"
    SpeedS TB_LINEAR_SPEED_MM_S
    Move P832
    Move P833
    tb_event "planned_contact_pose"
    Move P834
    tb_end
Fend

Function forehand_slow
    tb_begin "forehand_slow"
    tb_arm_arc 853,5
    tb_end
Fend

Function forehand_medium
    tb_begin "forehand_medium"
    tb_arm_arc 853,10
    tb_end
Fend

Function forehand_fast
    tb_begin "forehand_fast"
    tb_arm_arc 853,20
    tb_end
Fend

Function backhand_slow
    tb_begin "backhand_slow"
    tb_arm_arc 850,5
    tb_end
Fend

Function backhand_medium
    tb_begin "backhand_medium"
    tb_arm_arc 850,10
    tb_end
Fend

Function backhand_fast
    tb_begin "backhand_fast"
    tb_arm_arc 850,20
    tb_end
Fend

Function serve_like_slow
    tb_begin "serve_like_slow"
    tb_arm_arc 860,5
    tb_end
Fend

Function high_forehand_slow
    tb_begin "high_forehand_slow"
    tb_arm_arc 863,5
    tb_end
Fend

Function serve_like_medium
    tb_begin "serve_like_medium"
    tb_arm_arc 860,10
    tb_end
Fend

Function high_forehand_medium
    tb_begin "high_forehand_medium"
    tb_arm_arc 863,10
    tb_end
Fend

Function serve_like_fast
    tb_begin "serve_like_fast"
    tb_arm_arc 860,20
    tb_end
Fend

Function high_forehand_fast
    tb_begin "high_forehand_fast"
    tb_arm_arc 863,20
    tb_end
Fend

Function tap_wide_1_rest
    tb_begin "tap_wide_1_rest"
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_wide_1_after_swing
    tb_begin "tap_wide_1_after_swing"
    tb_arm_arc 853,10
    tb_joint_go 800
    tb_event "swing_end"
    Wait TB_AFTER_SWING_S
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_wide_2_rest
    tb_begin "tap_wide_2_rest"
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_wide_2_after_swing
    tb_begin "tap_wide_2_after_swing"
    tb_arm_arc 853,10
    tb_joint_go 800
    tb_event "swing_end"
    Wait TB_AFTER_SWING_S
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_wide_3_rest
    tb_begin "tap_wide_3_rest"
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_wide_3_after_swing
    tb_begin "tap_wide_3_after_swing"
    tb_arm_arc 853,10
    tb_joint_go 800
    tb_event "swing_end"
    Wait TB_AFTER_SWING_S
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,0,TB_TAP_STROKE_MM,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_narrow_1_rest
    tb_begin "tap_narrow_1_rest"
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_narrow_1_after_swing
    tb_begin "tap_narrow_1_after_swing"
    tb_arm_arc 853,10
    tb_joint_go 800
    tb_event "swing_end"
    Wait TB_AFTER_SWING_S
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_narrow_2_rest
    tb_begin "tap_narrow_2_rest"
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_narrow_2_after_swing
    tb_begin "tap_narrow_2_after_swing"
    tb_arm_arc 853,10
    tb_joint_go 800
    tb_event "swing_end"
    Wait TB_AFTER_SWING_S
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_narrow_3_rest
    tb_begin "tap_narrow_3_rest"
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function tap_narrow_3_after_swing
    tb_begin "tap_narrow_3_after_swing"
    tb_arm_arc 853,10
    tb_joint_go 800
    tb_event "swing_end"
    Wait TB_AFTER_SWING_S
    SpeedS TB_TAP_SPEED_MM_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait TB_TAP_GAP_S
    TMove XY(0,TB_TAP_STROKE_MM,0,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait TB_TAP_GAP_S
    tb_end
Fend

Function wrist_only_forehand_slow
    tb_begin "wrist_only_forehand_slow"
    tb_wrist 800,TB_SPEED_SLOW_PCT,-1
    tb_end
Fend

Function wrist_only_forehand_medium
    tb_begin "wrist_only_forehand_medium"
    tb_wrist 800,TB_SPEED_MEDIUM_PCT,-1
    tb_end
Fend

Function wrist_only_forehand_fast
    tb_begin "wrist_only_forehand_fast"
    tb_wrist 800,TB_SPEED_FAST_PCT,-1
    tb_end
Fend

Function wrist_only_backhand_slow
    tb_begin "wrist_only_backhand_slow"
    tb_wrist 800,TB_SPEED_SLOW_PCT,1
    tb_end
Fend

Function wrist_only_backhand_medium
    tb_begin "wrist_only_backhand_medium"
    tb_wrist 800,TB_SPEED_MEDIUM_PCT,1
    tb_end
Fend

Function wrist_only_backhand_fast
    tb_begin "wrist_only_backhand_fast"
    tb_wrist 800,TB_SPEED_FAST_PCT,1
    tb_end
Fend

Function tb_arm_arc(firstPoint As Integer, speedPct As Integer)
    Real swingSpeed, swingAccel
    Power Low
    SpeedS TB_LINEAR_SPEED_MM_S
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

Function tb_recap_stepup
    tb_setup
    g_sim_stepup = 1
    Motor On
    tb_joint_go 800
    SimSet ResetCollision
    g_event_file = FreeFile
    WOpen "tb_events.csv" As #g_event_file
    Print #g_event_file, "path_id,rep,time_s,event"
    static_tip_up
    static_face_up
    static_face_down
    static_tilt_x_plus45
    static_tilt_y_plus45
    air_forehand_slow
    air_forehand_medium
    air_forehand_fast
    air_backhand_slow
    air_backhand_medium
    air_backhand_fast
    abrupt_stop
    abrupt_reverse
    volley_center
    volley_tip
    volley_throat
    volley_left
    volley_right
    forehand_slow
    forehand_medium
    forehand_fast
    backhand_slow
    backhand_medium
    backhand_fast
    serve_like_slow
    high_forehand_slow
    serve_like_medium
    high_forehand_medium
    serve_like_fast
    high_forehand_fast
    tap_wide_1_rest
    tap_wide_1_after_swing
    tap_wide_2_rest
    tap_wide_2_after_swing
    tap_wide_3_rest
    tap_wide_3_after_swing
    tap_narrow_1_rest
    tap_narrow_1_after_swing
    tap_narrow_2_rest
    tap_narrow_2_after_swing
    tap_narrow_3_rest
    tap_narrow_3_after_swing
    wrist_only_forehand_slow
    wrist_only_forehand_medium
    wrist_only_forehand_fast
    wrist_only_backhand_slow
    wrist_only_backhand_medium
    wrist_only_backhand_fast
    Close #g_event_file
    Motor Off
    Print "RECAP COMPLETE: 48 paths"
Fend

Function tb_full
    tb_setup
    Motor On
    g_event_file = FreeFile
    WOpen "tb_events.csv" As #g_event_file
    Print #g_event_file, "path_id,rep,time_s,event"
    For g_rep = 1 To TB_REPS_STATIC
        static_tip_up
    Next g_rep
    For g_rep = 1 To TB_REPS_STATIC
        static_face_up
    Next g_rep
    For g_rep = 1 To TB_REPS_STATIC
        static_face_down
    Next g_rep
    For g_rep = 1 To TB_REPS_STATIC
        static_tilt_x_plus45
    Next g_rep
    For g_rep = 1 To TB_REPS_STATIC
        static_tilt_y_plus45
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        air_forehand_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        air_forehand_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        air_forehand_fast
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        air_backhand_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        air_backhand_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        air_backhand_fast
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        abrupt_stop
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        abrupt_reverse
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        volley_center
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        volley_tip
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        volley_throat
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        volley_left
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        volley_right
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        forehand_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        forehand_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        forehand_fast
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        backhand_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        backhand_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_CONTACT
        backhand_fast
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        serve_like_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        high_forehand_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        serve_like_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        high_forehand_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        serve_like_fast
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        high_forehand_fast
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_wide_1_rest
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_wide_1_after_swing
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_wide_2_rest
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_wide_2_after_swing
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_wide_3_rest
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_wide_3_after_swing
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_narrow_1_rest
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_narrow_1_after_swing
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_narrow_2_rest
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_narrow_2_after_swing
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_narrow_3_rest
    Next g_rep
    For g_rep = 1 To TB_REPS_OTHER
        tap_narrow_3_after_swing
    Next g_rep
    For g_rep = 1 To TB_REPS_WRIST
        wrist_only_forehand_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_WRIST
        wrist_only_forehand_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_WRIST
        wrist_only_forehand_fast
    Next g_rep
    For g_rep = 1 To TB_REPS_WRIST
        wrist_only_backhand_slow
    Next g_rep
    For g_rep = 1 To TB_REPS_WRIST
        wrist_only_backhand_medium
    Next g_rep
    For g_rep = 1 To TB_REPS_WRIST
        wrist_only_backhand_fast
    Next g_rep
    Close #g_event_file
    Motor Off
    Print "FULL RUN COMPLETE"
Fend

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

Global Integer g_record, g_log_done
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
    TLSet 1, XY(0,450,0,90,0,180)
    TLSet 2, XY(0,-50,0,90,0,180)
    Tool 1
    tb_points
Fend

Function tb_points
    P800 = XY(0,-500,500,0,0,90)
    P801 = XY(0,-500,750,90,-90,0)
    P802 = XY(0,-500,700,90,-90,0)
    P810 = XY(0.00000,-500.00000,700.00000,90.00000,-90.00000,0.00000)
    P811 = XY(0.00000,-500.00000,500.00000,135.00000,0.00000,0.00000)
    P812 = XY(0.00000,-500.00000,500.00000,135.00000,0.00000,180.00000)
    P813 = XY(0.00000,-500.00000,500.00000,135.00000,0.00000,45.00000)
    P814 = XY(0.00000,-500.00000,500.00000,135.00000,45.00000,0.00000)
    P820 = XY(0,-470,500,0,0,90)
    P821 = XY(0,-500,500,0,0,90)
    P822 = XY(0,-520,500,0,0,90)
    P823 = XY(-100,-470,500,0,0,90)
    P824 = XY(-100,-500,500,0,0,90)
    P825 = XY(-100,-520,500,0,0,90)
    P826 = XY(100,-470,500,0,0,90)
    P827 = XY(100,-500,500,0,0,90)
    P828 = XY(100,-520,500,0,0,90)
    P829 = XY(0,-470,580,0,0,90)
    P830 = XY(0,-500,580,0,0,90)
    P831 = XY(0,-520,580,0,0,90)
    P832 = XY(0,-470,420,0,0,90)
    P833 = XY(0,-500,420,0,0,90)
    P834 = XY(0,-520,420,0,0,90)
Fend

Function tb_probe_all
    Integer f
    tb_setup
    f = FreeFile
    WOpen "tb_final_reach.txt" As #f
    Print #f, "800", TargetOK(P800), TargetOK(P800 /B), PAgl(P800,1), PAgl(P800,2), PAgl(P800,3), PAgl(P800,4), PAgl(P800,5), PAgl(P800,6)
    Print #f, "801", TargetOK(P801), TargetOK(P801 /B), PAgl(P801,1), PAgl(P801,2), PAgl(P801,3), PAgl(P801,4), PAgl(P801,5), PAgl(P801,6)
    Print #f, "802", TargetOK(P802), TargetOK(P802 /B), PAgl(P802,1), PAgl(P802,2), PAgl(P802,3), PAgl(P802,4), PAgl(P802,5), PAgl(P802,6)
    Print #f, "810", TargetOK(P810), TargetOK(P810 /B), PAgl(P810,1), PAgl(P810,2), PAgl(P810,3), PAgl(P810,4), PAgl(P810,5), PAgl(P810,6)
    Print #f, "811", TargetOK(P811), TargetOK(P811 /B), PAgl(P811,1), PAgl(P811,2), PAgl(P811,3), PAgl(P811,4), PAgl(P811,5), PAgl(P811,6)
    Print #f, "812", TargetOK(P812), TargetOK(P812 /B), PAgl(P812,1), PAgl(P812,2), PAgl(P812,3), PAgl(P812,4), PAgl(P812,5), PAgl(P812,6)
    Print #f, "813", TargetOK(P813), TargetOK(P813 /B), PAgl(P813,1), PAgl(P813,2), PAgl(P813,3), PAgl(P813,4), PAgl(P813,5), PAgl(P813,6)
    Print #f, "814", TargetOK(P814), TargetOK(P814 /B), PAgl(P814,1), PAgl(P814,2), PAgl(P814,3), PAgl(P814,4), PAgl(P814,5), PAgl(P814,6)
    Print #f, "820", TargetOK(P820), TargetOK(P820 /B), PAgl(P820,1), PAgl(P820,2), PAgl(P820,3), PAgl(P820,4), PAgl(P820,5), PAgl(P820,6)
    Print #f, "821", TargetOK(P821), TargetOK(P821 /B), PAgl(P821,1), PAgl(P821,2), PAgl(P821,3), PAgl(P821,4), PAgl(P821,5), PAgl(P821,6)
    Print #f, "822", TargetOK(P822), TargetOK(P822 /B), PAgl(P822,1), PAgl(P822,2), PAgl(P822,3), PAgl(P822,4), PAgl(P822,5), PAgl(P822,6)
    Print #f, "823", TargetOK(P823), TargetOK(P823 /B), PAgl(P823,1), PAgl(P823,2), PAgl(P823,3), PAgl(P823,4), PAgl(P823,5), PAgl(P823,6)
    Print #f, "824", TargetOK(P824), TargetOK(P824 /B), PAgl(P824,1), PAgl(P824,2), PAgl(P824,3), PAgl(P824,4), PAgl(P824,5), PAgl(P824,6)
    Print #f, "825", TargetOK(P825), TargetOK(P825 /B), PAgl(P825,1), PAgl(P825,2), PAgl(P825,3), PAgl(P825,4), PAgl(P825,5), PAgl(P825,6)
    Print #f, "826", TargetOK(P826), TargetOK(P826 /B), PAgl(P826,1), PAgl(P826,2), PAgl(P826,3), PAgl(P826,4), PAgl(P826,5), PAgl(P826,6)
    Print #f, "827", TargetOK(P827), TargetOK(P827 /B), PAgl(P827,1), PAgl(P827,2), PAgl(P827,3), PAgl(P827,4), PAgl(P827,5), PAgl(P827,6)
    Print #f, "828", TargetOK(P828), TargetOK(P828 /B), PAgl(P828,1), PAgl(P828,2), PAgl(P828,3), PAgl(P828,4), PAgl(P828,5), PAgl(P828,6)
    Print #f, "829", TargetOK(P829), TargetOK(P829 /B), PAgl(P829,1), PAgl(P829,2), PAgl(P829,3), PAgl(P829,4), PAgl(P829,5), PAgl(P829,6)
    Print #f, "830", TargetOK(P830), TargetOK(P830 /B), PAgl(P830,1), PAgl(P830,2), PAgl(P830,3), PAgl(P830,4), PAgl(P830,5), PAgl(P830,6)
    Print #f, "831", TargetOK(P831), TargetOK(P831 /B), PAgl(P831,1), PAgl(P831,2), PAgl(P831,3), PAgl(P831,4), PAgl(P831,5), PAgl(P831,6)
    Print #f, "832", TargetOK(P832), TargetOK(P832 /B), PAgl(P832,1), PAgl(P832,2), PAgl(P832,3), PAgl(P832,4), PAgl(P832,5), PAgl(P832,6)
    Print #f, "833", TargetOK(P833), TargetOK(P833 /B), PAgl(P833,1), PAgl(P833,2), PAgl(P833,3), PAgl(P833,4), PAgl(P833,5), PAgl(P833,6)
    Print #f, "834", TargetOK(P834), TargetOK(P834 /B), PAgl(P834,1), PAgl(P834,2), PAgl(P834,3), PAgl(P834,4), PAgl(P834,5), PAgl(P834,6)
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
    Go JA(g_q(1),g_q(2),g_q(3),g_q(4),g_q(5),g_q(6)-direction*20)
    Speed speedPct
    Accel 20,20
    Go JA(g_q(1),g_q(2),g_q(3),g_q(4),g_q(5),g_q(6)+direction*20)
    Speed 20
Fend

Function tb_recap
    tb_setup
    Motor On
    g_event_file = FreeFile
    WOpen "tb_events.csv" As #g_event_file
    Print #g_event_file, "path_id,time_s,event"
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
    Close #g_event_file
    Motor Off
    Print "RECAP COMPLETE: 42 paths"
Fend

Function static_tip_up
    tb_begin "static_tip_up"
    tb_joint_go 810
    Wait 3
    tb_end
Fend

Function static_face_up
    tb_begin "static_face_up"
    tb_joint_go 811
    Wait 3
    tb_end
Fend

Function static_face_down
    tb_begin "static_face_down"
    tb_joint_go 812
    Wait 3
    tb_end
Fend

Function static_tilt_x_plus45
    tb_begin "static_tilt_x_plus45"
    tb_joint_go 813
    Wait 3
    tb_end
Fend

Function static_tilt_y_plus45
    tb_begin "static_tilt_y_plus45"
    tb_joint_go 814
    Wait 3
    tb_end
Fend

Function air_forehand_slow
    tb_begin "air_forehand_slow"
    tb_wrist 800,5,1
    tb_end
Fend

Function air_forehand_medium
    tb_begin "air_forehand_medium"
    tb_wrist 800,10,1
    tb_end
Fend

Function air_forehand_fast
    tb_begin "air_forehand_fast"
    tb_wrist 800,20,1
    tb_end
Fend

Function air_backhand_slow
    tb_begin "air_backhand_slow"
    tb_wrist 800,5,-1
    tb_end
Fend

Function air_backhand_medium
    tb_begin "air_backhand_medium"
    tb_wrist 800,10,-1
    tb_end
Fend

Function air_backhand_fast
    tb_begin "air_backhand_fast"
    tb_wrist 800,20,-1
    tb_end
Fend

Function abrupt_stop
    tb_begin "abrupt_stop"
    tb_wrist 800,20,1
    tb_end
Fend

Function abrupt_reverse
    tb_begin "abrupt_reverse"
    tb_wrist 800,20,1
    tb_wrist 800,20,-1
    tb_end
Fend

Function volley_center
    tb_begin "volley_center"
    SpeedS 100
    Move P820
    Move P821
    tb_event "planned_contact_pose"
    Move P822
    tb_end
Fend

Function volley_tip
    tb_begin "volley_tip"
    SpeedS 100
    Move P823
    Move P824
    tb_event "planned_contact_pose"
    Move P825
    tb_end
Fend

Function volley_throat
    tb_begin "volley_throat"
    SpeedS 100
    Move P826
    Move P827
    tb_event "planned_contact_pose"
    Move P828
    tb_end
Fend

Function volley_left
    tb_begin "volley_left"
    SpeedS 100
    Move P829
    Move P830
    tb_event "planned_contact_pose"
    Move P831
    tb_end
Fend

Function volley_right
    tb_begin "volley_right"
    SpeedS 100
    Move P832
    Move P833
    tb_event "planned_contact_pose"
    Move P834
    tb_end
Fend

Function forehand_slow
    tb_begin "forehand_slow"
    tb_wrist 800,5,1
    tb_end
Fend

Function forehand_medium
    tb_begin "forehand_medium"
    tb_wrist 800,10,1
    tb_end
Fend

Function forehand_fast
    tb_begin "forehand_fast"
    tb_wrist 800,20,1
    tb_end
Fend

Function backhand_slow
    tb_begin "backhand_slow"
    tb_wrist 800,5,-1
    tb_end
Fend

Function backhand_medium
    tb_begin "backhand_medium"
    tb_wrist 800,10,-1
    tb_end
Fend

Function backhand_fast
    tb_begin "backhand_fast"
    tb_wrist 800,20,-1
    tb_end
Fend

Function serve_like_slow
    tb_begin "serve_like_slow"
    tb_wrist 801,5,1
    tb_end
Fend

Function high_forehand_slow
    tb_begin "high_forehand_slow"
    tb_wrist 802,5,-1
    tb_end
Fend

Function serve_like_medium
    tb_begin "serve_like_medium"
    tb_wrist 801,10,1
    tb_end
Fend

Function high_forehand_medium
    tb_begin "high_forehand_medium"
    tb_wrist 802,10,-1
    tb_end
Fend

Function serve_like_fast
    tb_begin "serve_like_fast"
    tb_wrist 801,20,1
    tb_end
Fend

Function high_forehand_fast
    tb_begin "high_forehand_fast"
    tb_wrist 802,20,-1
    tb_end
Fend

Function tap_wide_1_rest
    tb_begin "tap_wide_1_rest"
    SpeedS 20
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_wide_1_after_swing
    tb_begin "tap_wide_1_after_swing"
    tb_wrist 800,10,1
    tb_joint_go 800
    Wait 0.5
    SpeedS 20
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_wide_2_rest
    tb_begin "tap_wide_2_rest"
    SpeedS 20
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_wide_2_after_swing
    tb_begin "tap_wide_2_after_swing"
    tb_wrist 800,10,1
    tb_joint_go 800
    Wait 0.5
    SpeedS 20
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_wide_3_rest
    tb_begin "tap_wide_3_rest"
    SpeedS 20
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_wide_3_after_swing
    tb_begin "tap_wide_3_after_swing"
    tb_wrist 800,10,1
    tb_joint_go 800
    Wait 0.5
    SpeedS 20
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    TMove XY(0,0,4,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_narrow_1_rest
    tb_begin "tap_narrow_1_rest"
    SpeedS 20
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_narrow_1_after_swing
    tb_begin "tap_narrow_1_after_swing"
    tb_wrist 800,10,1
    tb_joint_go 800
    Wait 0.5
    SpeedS 20
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_narrow_2_rest
    tb_begin "tap_narrow_2_rest"
    SpeedS 20
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_narrow_2_after_swing
    tb_begin "tap_narrow_2_after_swing"
    tb_wrist 800,10,1
    tb_joint_go 800
    Wait 0.5
    SpeedS 20
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_narrow_3_rest
    tb_begin "tap_narrow_3_rest"
    SpeedS 20
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

Function tap_narrow_3_after_swing
    tb_begin "tap_narrow_3_after_swing"
    tb_wrist 800,10,1
    tb_joint_go 800
    Wait 0.5
    SpeedS 20
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_1_pose"
    Move P800
    Wait 0.16
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_2_pose"
    Move P800
    Wait 0.16
    TMove XY(0,4,0,0,0,0)
    tb_event "tap_3_pose"
    Move P800
    Wait 0.16
    tb_end
Fend

' Native RC+ simulation project. No physical robot connection.
Function main
    tb_probe
Fend

Function tb_tool
    Robot 1
    TLSet 1, XY(0, 450, 0, 90, 0, 180)
    TLSet 2, XY(0, -50, 0, 90, 0, 180)
    Tool 1
    Power Low
    Speed 20
    Accel 20, 20
    SpeedS 150
    AccelS 200, 200
Fend

Function tb_probe
    Integer bad, iFile
    tb_tool
    iFile = FreeFile
    WOpen "tb_reach.txt" As #iFile
    bad = 0
    P100 = XY(0.0000, -600.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "100 static_tip_up", TargetOK(P100), TargetOK(P100 /B), TargetOK(P100 /L), TargetOK(P100 /L /B), TargetOK(P100 /F), TargetOK(P100 /B /F), TargetOK(P100 /L /F), TargetOK(P100 /L /B /F)
    P101 = XY(0.0000, -600.0000, 700.0000, 0.0000, 0.0000, 94.0000)
    Print #iFile, "101 static_tip_up", TargetOK(P101), TargetOK(P101 /B), TargetOK(P101 /L), TargetOK(P101 /L /B), TargetOK(P101 /F), TargetOK(P101 /B /F), TargetOK(P101 /L /F), TargetOK(P101 /L /B /F)
    P102 = XY(0.0000, -600.0000, 700.0000, 90.0000, -90.0000, 0.0000)
    Print #iFile, "102 static_tip_up", TargetOK(P102), TargetOK(P102 /B), TargetOK(P102 /L), TargetOK(P102 /L /B), TargetOK(P102 /F), TargetOK(P102 /B /F), TargetOK(P102 /L /F), TargetOK(P102 /L /B /F)
    P103 = XY(0.0000, -600.0000, 700.0000, -90.0000, 0.0000, 0.0000)
    Print #iFile, "103 static_face_up", TargetOK(P103), TargetOK(P103 /B), TargetOK(P103 /L), TargetOK(P103 /L /B), TargetOK(P103 /F), TargetOK(P103 /B /F), TargetOK(P103 /L /F), TargetOK(P103 /L /B /F)
    P104 = XY(0.0000, -600.0000, 700.0000, -90.0000, 0.0000, 180.0000)
    Print #iFile, "104 static_face_down", TargetOK(P104), TargetOK(P104 /B), TargetOK(P104 /L), TargetOK(P104 /L /B), TargetOK(P104 /F), TargetOK(P104 /B /F), TargetOK(P104 /L /F), TargetOK(P104 /L /B /F)
    P105 = XY(0.0000, -600.0000, 700.0000, 0.0000, 0.0000, 135.0000)
    Print #iFile, "105 static_tilt_x_plus45", TargetOK(P105), TargetOK(P105 /B), TargetOK(P105 /L), TargetOK(P105 /L /B), TargetOK(P105 /F), TargetOK(P105 /B /F), TargetOK(P105 /L /F), TargetOK(P105 /L /B /F)
    P106 = XY(0.0000, -600.0000, 700.0000, 45.0000, 0.0000, 90.0000)
    Print #iFile, "106 static_tilt_y_plus45", TargetOK(P106), TargetOK(P106 /B), TargetOK(P106 /L), TargetOK(P106 /L /B), TargetOK(P106 /F), TargetOK(P106 /B /F), TargetOK(P106 /L /F), TargetOK(P106 /L /B /F)
    P107 = XY(-120.0000, -600.0000, 700.0000, 0.0000, 18.0000, 90.0000)
    Print #iFile, "107 air_forehand_slow", TargetOK(P107), TargetOK(P107 /B), TargetOK(P107 /L), TargetOK(P107 /L /B), TargetOK(P107 /F), TargetOK(P107 /B /F), TargetOK(P107 /L /F), TargetOK(P107 /L /B /F)
    P108 = XY(120.0000, -600.0000, 700.0000, 0.0000, -18.0000, 90.0000)
    Print #iFile, "108 air_forehand_slow", TargetOK(P108), TargetOK(P108 /B), TargetOK(P108 /L), TargetOK(P108 /L /B), TargetOK(P108 /F), TargetOK(P108 /B /F), TargetOK(P108 /L /F), TargetOK(P108 /L /B /F)
    P109 = XY(120.0000, -600.0000, 700.0000, 0.0000, 18.0000, 90.0000)
    Print #iFile, "109 air_backhand_slow", TargetOK(P109), TargetOK(P109 /B), TargetOK(P109 /L), TargetOK(P109 /L /B), TargetOK(P109 /F), TargetOK(P109 /B /F), TargetOK(P109 /L /F), TargetOK(P109 /L /B /F)
    P110 = XY(-120.0000, -600.0000, 700.0000, 0.0000, -18.0000, 90.0000)
    Print #iFile, "110 air_backhand_slow", TargetOK(P110), TargetOK(P110 /B), TargetOK(P110 /L), TargetOK(P110 /L /B), TargetOK(P110 /F), TargetOK(P110 /B /F), TargetOK(P110 /L /F), TargetOK(P110 /L /B /F)
    P111 = XY(0.0000, -540.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "111 volley_center", TargetOK(P111), TargetOK(P111 /B), TargetOK(P111 /L), TargetOK(P111 /L /B), TargetOK(P111 /F), TargetOK(P111 /B /F), TargetOK(P111 /L /F), TargetOK(P111 /L /B /F)
    P112 = XY(0.0000, -660.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "112 volley_center", TargetOK(P112), TargetOK(P112 /B), TargetOK(P112 /L), TargetOK(P112 /L /B), TargetOK(P112 /F), TargetOK(P112 /B /F), TargetOK(P112 /L /F), TargetOK(P112 /L /B /F)
    P113 = XY(-100.0000, -540.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "113 volley_tip", TargetOK(P113), TargetOK(P113 /B), TargetOK(P113 /L), TargetOK(P113 /L /B), TargetOK(P113 /F), TargetOK(P113 /B /F), TargetOK(P113 /L /F), TargetOK(P113 /L /B /F)
    P114 = XY(-100.0000, -600.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "114 volley_tip", TargetOK(P114), TargetOK(P114 /B), TargetOK(P114 /L), TargetOK(P114 /L /B), TargetOK(P114 /F), TargetOK(P114 /B /F), TargetOK(P114 /L /F), TargetOK(P114 /L /B /F)
    P115 = XY(-100.0000, -660.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "115 volley_tip", TargetOK(P115), TargetOK(P115 /B), TargetOK(P115 /L), TargetOK(P115 /L /B), TargetOK(P115 /F), TargetOK(P115 /B /F), TargetOK(P115 /L /F), TargetOK(P115 /L /B /F)
    P116 = XY(100.0000, -540.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "116 volley_throat", TargetOK(P116), TargetOK(P116 /B), TargetOK(P116 /L), TargetOK(P116 /L /B), TargetOK(P116 /F), TargetOK(P116 /B /F), TargetOK(P116 /L /F), TargetOK(P116 /L /B /F)
    P117 = XY(100.0000, -600.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "117 volley_throat", TargetOK(P117), TargetOK(P117 /B), TargetOK(P117 /L), TargetOK(P117 /L /B), TargetOK(P117 /F), TargetOK(P117 /B /F), TargetOK(P117 /L /F), TargetOK(P117 /L /B /F)
    P118 = XY(100.0000, -660.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "118 volley_throat", TargetOK(P118), TargetOK(P118 /B), TargetOK(P118 /L), TargetOK(P118 /L /B), TargetOK(P118 /F), TargetOK(P118 /B /F), TargetOK(P118 /L /F), TargetOK(P118 /L /B /F)
    P119 = XY(0.0000, -540.0000, 780.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "119 volley_left", TargetOK(P119), TargetOK(P119 /B), TargetOK(P119 /L), TargetOK(P119 /L /B), TargetOK(P119 /F), TargetOK(P119 /B /F), TargetOK(P119 /L /F), TargetOK(P119 /L /B /F)
    P120 = XY(0.0000, -600.0000, 780.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "120 volley_left", TargetOK(P120), TargetOK(P120 /B), TargetOK(P120 /L), TargetOK(P120 /L /B), TargetOK(P120 /F), TargetOK(P120 /B /F), TargetOK(P120 /L /F), TargetOK(P120 /L /B /F)
    P121 = XY(0.0000, -660.0000, 780.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "121 volley_left", TargetOK(P121), TargetOK(P121 /B), TargetOK(P121 /L), TargetOK(P121 /L /B), TargetOK(P121 /F), TargetOK(P121 /B /F), TargetOK(P121 /L /F), TargetOK(P121 /L /B /F)
    P122 = XY(0.0000, -540.0000, 620.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "122 volley_right", TargetOK(P122), TargetOK(P122 /B), TargetOK(P122 /L), TargetOK(P122 /L /B), TargetOK(P122 /F), TargetOK(P122 /B /F), TargetOK(P122 /L /F), TargetOK(P122 /L /B /F)
    P123 = XY(0.0000, -600.0000, 620.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "123 volley_right", TargetOK(P123), TargetOK(P123 /B), TargetOK(P123 /L), TargetOK(P123 /L /B), TargetOK(P123 /F), TargetOK(P123 /B /F), TargetOK(P123 /L /F), TargetOK(P123 /L /B /F)
    P124 = XY(0.0000, -660.0000, 620.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "124 volley_right", TargetOK(P124), TargetOK(P124 /B), TargetOK(P124 /L), TargetOK(P124 /L /B), TargetOK(P124 /F), TargetOK(P124 /B /F), TargetOK(P124 /L /F), TargetOK(P124 /L /B /F)
    P125 = XY(-120.0000, -600.0000, 950.0000, -90.0000, -75.0000, 180.0000)
    Print #iFile, "125 serve_like_slow", TargetOK(P125), TargetOK(P125 /B), TargetOK(P125 /L), TargetOK(P125 /L /B), TargetOK(P125 /F), TargetOK(P125 /B /F), TargetOK(P125 /L /F), TargetOK(P125 /L /B /F)
    P126 = XY(0.0000, -600.0000, 950.0000, 90.0000, -90.0000, 0.0000)
    Print #iFile, "126 serve_like_slow", TargetOK(P126), TargetOK(P126 /B), TargetOK(P126 /L), TargetOK(P126 /L /B), TargetOK(P126 /F), TargetOK(P126 /B /F), TargetOK(P126 /L /F), TargetOK(P126 /L /B /F)
    P127 = XY(120.0000, -600.0000, 950.0000, 90.0000, -75.0000, 0.0000)
    Print #iFile, "127 serve_like_slow", TargetOK(P127), TargetOK(P127 /B), TargetOK(P127 /L), TargetOK(P127 /L /B), TargetOK(P127 /F), TargetOK(P127 /B /F), TargetOK(P127 /L /F), TargetOK(P127 /L /B /F)
    P128 = XY(0.0000, -600.0000, 704.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "128 tap_wide_1_rest", TargetOK(P128), TargetOK(P128 /B), TargetOK(P128 /L), TargetOK(P128 /L /B), TargetOK(P128 /F), TargetOK(P128 /B /F), TargetOK(P128 /L /F), TargetOK(P128 /L /B /F)
    P129 = XY(-100.0000, -600.0000, 700.0000, 0.0000, 10.0000, 90.0000)
    Print #iFile, "129 tap_wide_1_after_swing", TargetOK(P129), TargetOK(P129 /B), TargetOK(P129 /L), TargetOK(P129 /L /B), TargetOK(P129 /F), TargetOK(P129 /B /F), TargetOK(P129 /L /F), TargetOK(P129 /L /B /F)
    P130 = XY(0.0000, -604.0000, 700.0000, 0.0000, 0.0000, 90.0000)
    Print #iFile, "130 tap_narrow_1_rest", TargetOK(P130), TargetOK(P130 /B), TargetOK(P130 /L), TargetOK(P130 /L /B), TargetOK(P130 /F), TargetOK(P130 /B /F), TargetOK(P130 /L /F), TargetOK(P130 /L /B /F)
    Close #iFile
    Print "Reach report written: 31 unique poses, 8 branches"
Fend

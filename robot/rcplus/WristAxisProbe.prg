Function main
    Integer f
    Robot 1
    TLSet 1, XY(0,450,0,90,0,180)
    Tool 1
    f=FreeFile
    WOpen "tb_wrist_axis_probe.txt" As #f
    P900=JA(170,-45,45,0,0,90)
    If TargetOK(P900) Then
        Print #f, "-45 0 0 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,45,0,90)
    If TargetOK(P900) Then
        Print #f, "-45 45 0 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,0,0,91)
    If TargetOK(P900) Then
        Print #f, "-45 0 0 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,-120,0,63.3333)
    If TargetOK(P900) Then
        Print #f, "-45 -120 0 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,120,0,116.6667)
    If TargetOK(P900) Then
        Print #f, "-45 120 0 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,0,90,90)
    If TargetOK(P900) Then
        Print #f, "-45 0 90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,45,90,90)
    If TargetOK(P900) Then
        Print #f, "-45 45 90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,0,90,91)
    If TargetOK(P900) Then
        Print #f, "-45 0 90 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,-120,90,63.3333)
    If TargetOK(P900) Then
        Print #f, "-45 -120 90 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,120,90,116.6667)
    If TargetOK(P900) Then
        Print #f, "-45 120 90 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,0,-90,90)
    If TargetOK(P900) Then
        Print #f, "-45 0 -90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,45,-90,90)
    If TargetOK(P900) Then
        Print #f, "-45 45 -90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,0,-90,91)
    If TargetOK(P900) Then
        Print #f, "-45 0 -90 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,-120,-90,63.3333)
    If TargetOK(P900) Then
        Print #f, "-45 -120 -90 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-45,45,120,-90,116.6667)
    If TargetOK(P900) Then
        Print #f, "-45 120 -90 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,0,0,90)
    If TargetOK(P900) Then
        Print #f, "-60 0 0 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,45,0,90)
    If TargetOK(P900) Then
        Print #f, "-60 45 0 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,0,0,91)
    If TargetOK(P900) Then
        Print #f, "-60 0 0 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,-120,0,63.3333)
    If TargetOK(P900) Then
        Print #f, "-60 -120 0 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,120,0,116.6667)
    If TargetOK(P900) Then
        Print #f, "-60 120 0 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,0,90,90)
    If TargetOK(P900) Then
        Print #f, "-60 0 90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,45,90,90)
    If TargetOK(P900) Then
        Print #f, "-60 45 90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,0,90,91)
    If TargetOK(P900) Then
        Print #f, "-60 0 90 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,-120,90,63.3333)
    If TargetOK(P900) Then
        Print #f, "-60 -120 90 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,120,90,116.6667)
    If TargetOK(P900) Then
        Print #f, "-60 120 90 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,0,-90,90)
    If TargetOK(P900) Then
        Print #f, "-60 0 -90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,45,-90,90)
    If TargetOK(P900) Then
        Print #f, "-60 45 -90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,0,-90,91)
    If TargetOK(P900) Then
        Print #f, "-60 0 -90 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,-120,-90,63.3333)
    If TargetOK(P900) Then
        Print #f, "-60 -120 -90 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-60,60,120,-90,116.6667)
    If TargetOK(P900) Then
        Print #f, "-60 120 -90 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,0,0,90)
    If TargetOK(P900) Then
        Print #f, "-75 0 0 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,45,0,90)
    If TargetOK(P900) Then
        Print #f, "-75 45 0 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,0,0,91)
    If TargetOK(P900) Then
        Print #f, "-75 0 0 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,-120,0,63.3333)
    If TargetOK(P900) Then
        Print #f, "-75 -120 0 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,120,0,116.6667)
    If TargetOK(P900) Then
        Print #f, "-75 120 0 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,0,90,90)
    If TargetOK(P900) Then
        Print #f, "-75 0 90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,45,90,90)
    If TargetOK(P900) Then
        Print #f, "-75 45 90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,0,90,91)
    If TargetOK(P900) Then
        Print #f, "-75 0 90 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,-120,90,63.3333)
    If TargetOK(P900) Then
        Print #f, "-75 -120 90 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,120,90,116.6667)
    If TargetOK(P900) Then
        Print #f, "-75 120 90 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,0,-90,90)
    If TargetOK(P900) Then
        Print #f, "-75 0 -90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,45,-90,90)
    If TargetOK(P900) Then
        Print #f, "-75 45 -90 90", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,0,-90,91)
    If TargetOK(P900) Then
        Print #f, "-75 0 -90 91", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,-120,-90,63.3333)
    If TargetOK(P900) Then
        Print #f, "-75 -120 -90 63.3333", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    P900=JA(170,-75,75,120,-90,116.6667)
    If TargetOK(P900) Then
        Print #f, "-75 120 -90 116.6667", CX(P900),CY(P900),CZ(P900),CU(P900),CV(P900),CW(P900)
    EndIf
    Close #f
    Print "Wrist axis probe complete"
Fend

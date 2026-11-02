Function main
    Integer f
    Robot 1
    TLSet 1, XY(0,450,0,90,0,180)
    Tool 1
    f=FreeFile
    WOpen "tb_facedown_grid.txt" As #f
    P900=XY(0,-400,400,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,400,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,400,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,400,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,400,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,400,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,400,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,400,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 400 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,400,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 400 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,500,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 500 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,500,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 500 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,600,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 600 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,600,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 600 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,650,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 650 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,650,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 650 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,700,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 700 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,700,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 700 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-400,750,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-400 750 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-400,750,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-400 750 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,400,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 400 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,400,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 400 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,500,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 500 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,500,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 500 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,600,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 600 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,600,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 600 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,650,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 650 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,650,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 650 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,700,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 700 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,700,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 700 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,750,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-500 750 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,750,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-500 750 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,400,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 400 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,400,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 400 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,500,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 500 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,500,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 500 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,600,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 600 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,600,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 600 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,650,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 650 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,650,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 650 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,700,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 700 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,700,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 700 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,0,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,0,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,180,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,180,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,-135,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,-135,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,-90,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,-90,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,750,-45,0,180)
    If TargetOK(P900) Then
        Print #f, "-600 750 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,750,-45,0,180)
    If TargetOK(P900 /F) Then
        Print #f, "-600 750 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    Close #f
    Print "Face-down grid complete"
Fend

Function main
    Integer f
    Robot 1
    TLSet 1, XY(0,450,0,90,0,180)
    Tool 1
    f=FreeFile
    WOpen "tb_overhead_grid.txt" As #f
    P900=XY(0,-500,850,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,850,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,850,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,850,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,850,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,850,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,850,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,850,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 850 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,850,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 850 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,850,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 850 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,850,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 850 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,950,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 950 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,950,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 950 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,950,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 950 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,950,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 950 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-500,1050,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-500 1050 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-500,1050,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-500 1050 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-500,1050,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-500 1050 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-500,1050,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-500 1050 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,850,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 850 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,850,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 850 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,850,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 850 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,850,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 850 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,950,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 950 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,950,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 950 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,950,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 950 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,950,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 950 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-550,1050,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-550 1050 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-550,1050,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-550 1050 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-550,1050,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-550 1050 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-550,1050,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-550 1050 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,850,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 850 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,850,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 850 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,850,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 850 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,850,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 850 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,950,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 950 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,950,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 950 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,950,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 950 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,950,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 950 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-600,1050,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-600 1050 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-600,1050,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-600 1050 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-600,1050,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-600 1050 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-600,1050,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-600 1050 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,850,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 850 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,850,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 850 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,850,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 850 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,850,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 850 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,950,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 950 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,950,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 950 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,950,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 950 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,950,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 950 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-650,1050,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-650 1050 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-650,1050,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-650 1050 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-650,1050,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-650 1050 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-650,1050,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-650 1050 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,850,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 850 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,850,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 850 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,850,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 850 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,850,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 850 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,950,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 950 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,950,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 950 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,950,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 950 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,950,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 950 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,0,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 0 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,0,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 0  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,0,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 0  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,0,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 0  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,180,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 180 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,180,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 180  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,180,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 180  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,180,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 180  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,-135,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 -135 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,-135,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 -135  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,-135,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 -135  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,-135,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 -135  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,-90,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 -90 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,-90,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 -90  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,-90,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 -90  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,-90,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 -90  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    P900=XY(0,-700,1050,-45,-90,0)
    If TargetOK(P900) Then
        Print #f, "-700 1050 -45 ", PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    EndIf
    P900=XY(0,-700,1050,-45,-90,0)
    If TargetOK(P900 /B) Then
        Print #f, "-700 1050 -45  /B", PAgl(P900 /B,1), PAgl(P900 /B,2), PAgl(P900 /B,3), PAgl(P900 /B,4), PAgl(P900 /B,5), PAgl(P900 /B,6)
    EndIf
    P900=XY(0,-700,1050,-45,-90,0)
    If TargetOK(P900 /F) Then
        Print #f, "-700 1050 -45  /F", PAgl(P900 /F,1), PAgl(P900 /F,2), PAgl(P900 /F,3), PAgl(P900 /F,4), PAgl(P900 /F,5), PAgl(P900 /F,6)
    EndIf
    P900=XY(0,-700,1050,-45,-90,0)
    If TargetOK(P900 /B /F) Then
        Print #f, "-700 1050 -45  /B /F", PAgl(P900 /B /F,1), PAgl(P900 /B /F,2), PAgl(P900 /B /F,3), PAgl(P900 /B /F,4), PAgl(P900 /B /F,5), PAgl(P900 /B /F,6)
    EndIf
    Close #f
    Print "Overhead grid complete"
Fend

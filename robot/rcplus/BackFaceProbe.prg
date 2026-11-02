Function main
    Integer f
    Robot 1
    TLSet 1, XY(0,450,0,90,0,180)
    Tool 1
    f=FreeFile
    WOpen "tb_backface.txt" As #f
    P900=XY(0,-500,500,0,0,-90)
    Print #f, "home_back", TargetOK(P900), PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    P900=XY(0,-500,500,0,0,-90) /F
    Print #f, "home_back_F", TargetOK(P900), PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    P900=XY(0,-600,950,-90,-90,0)
    Print #f, "up_back", TargetOK(P900), PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    P900=XY(0,-600,950,-90,-90,0) /F
    Print #f, "up_back_F", TargetOK(P900), PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    P900=XY(0,-650,1050,-90,-90,0)
    Print #f, "serve_back", TargetOK(P900), PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    P900=XY(0,-650,1050,-90,-90,0) /F
    Print #f, "serve_back_F", TargetOK(P900), PAgl(P900,1), PAgl(P900,2), PAgl(P900,3), PAgl(P900,4), PAgl(P900,5), PAgl(P900,6)
    Close #f
    Print "Back-face reach complete"
Fend

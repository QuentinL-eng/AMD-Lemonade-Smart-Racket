# Tennis Buddy — native Epson RC+ simulation

## Assumptions to check first

- This work runs only in the RC+ 7.5.4A R1 **Simulator**, robot 1 **C8-A901S**, Dry Run. It is not a physical-arm commissioning package.
- `SWEETSPOT_OFFSET_M = 0.50` comes directly from the user's estimate from the handle IMU toward the tip. It is not a measured racket dimension. The provisional simulator flange-to-handle translation is `(0,-0.05,0)` m; sweet spot is `(0,0.45,0)` m in flange coordinates.
- Racket axes expressed in flange coordinates are `x=(0,1,0)`, `y=(1,0,0)`, `z=(0,0,-1)`. This follows the inherited CAD mounting along flange +Y and still needs physical measurement. The CAD object's displayed world placement is not an IMU transform.
- World +x = robot -Y (toward ball/net), world +y = robot +X, world +z = robot +Z (up). This is the provisional interpretation of the supplied green/red image. Green is world x >= 0. The image supplies no numeric height or clearance boundary. Full-arm swept-volume certification is not established by a TCP check.
- Racket proxy dimensions for log checks: x from -0.55 to +0.18 m about the sweet spot, half-width 0.145 m, half-thickness 0.015 m. This deliberately encloses a rough racket shape; it is not a measured CAD collision mesh.
- The nominal ball is at robot `(0,-500,500)` mm. Volley offsets: centre `(0,0)`, tip `(0,10)`, throat `(0,-10)`, left `(-8,0)`, right `(8,0)` cm. Ball fixtures and handle pads have no validated stiffness or impact physics. Intended contact is a label for a nominal pose, not evidence of impact.
- Catalog wrist limits: J4/J5 450 deg/s, J6 720 deg/s. C8-A901 rated reach is 901 mm at P point and 981 mm at flange. These do not describe the usable swept envelope with a racket.
- Simulated racket identity defaults to E35E; E912 is selectable in the parameter header. This is a run label, not a BLE connection or an IMU recording. The handle contains the user's LSM6DSV320X, sampling gyro and low/high-g acceleration at 1 kHz on hardware.
- No physical payload, centre of mass, inertia, supply-wire repair, or real-cell clearance has been measured here. The earlier fast-spin reboot must be resolved before a physical fast-spin run.

## Native project and files

The working copy is `D:/EpsonRC70/Projects/TennisBuddyDayOne_20261029`. It preserves the original `RacketSim_20261025` project and its mounted racket. Do not use the older P0/P2 tests: their recorded results include an unreachable point and a red collision indication.

`rcplus/ExecutedRecap_20261029.prg` preserves the source used for the first native recap. `rcplus/DayOne.prg` is the parameterized version with one function for each of the 48 entries in `paths.json`, plus shared helpers and runners. `generate_native_dayone.py` regenerates it; `--deploy` explicitly copies it into the working RC+ project. Rebuild All in RC+ after external source changes. Close an old Main.prg editor first if it contains an older in-memory version.

The earlier files under `generated/` are a rejected tool-space illustration. They are not RC+ output and are not the requested simulator recap. Native executed exports belong under `recordings/`.

## Frames and tools

The homogeneous flange-to-handle transform (translation in metres) is:

```
[0  1  0   0   ]
[1  0  0  -0.05]
[0  0 -1   0   ]
[0  0  0   1   ]
```

The sensor-to-sweet-spot transform translates +0.50 m along racket x. The resulting Epson tools, in mm and degrees, are:

```
TLSet 1, XY(0,450,0,90,0,180)   ' sweet spot
TLSet 2, XY(0,-50,0,90,0,180)   ' sensor/handle
Tool 1
```

Epson U,V,W mean Z,Y,X Euler rotations. CSV orientation is a unit quaternion in world coordinates, ordered **w,x,y,z**. The 90 degree world rotation maps robot `(X,Y,Z)` to world `(-Y,X,Z)`.

Manifest contact offsets deliberately use their requested names: `x` is across the face (racket y), `y` is toward the tip (racket x). Zero is the sweet spot. Right-handed is a test label; confirm the sign against app conventions. Face angle is signed yaw of the face normal from world +x, viewed from above. Swing-path angle is elevation of velocity above horizontal at nominal contact; null is used when a single angle is undefined.

## Run sequence

1. Open the working project and select **Simulator**, never USB or a real-controller connection. Verify C8-A901S and Dry Run in the status bar.
2. Rebuild All. Open Simulator with Ctrl+F5 and the Run window with F5.
3. `tb_probe_all` checks endpoint reachability without commanding motion. This does not check intervening motion or self-collision.
4. `tb_recap` runs one example of all 48 paths (42 requested cases plus six isolated wrist controls). Each begins at the home pose, records a 1 s still hold, commands a +4/-4 degree tool-x twitch, holds another 1 s, logs path start, executes the path, pauses, and returns home.
5. `tb_full` uses named repetition parameters: 10 for volleys and forehand/backhand contact paths, three for other moving tests and wrist controls, and one for static poses. Each repetition gets its own trajectory file and sync gesture. Set the racket name before compiling; no automatic physical-racket discovery is performed.
6. `tb_recap_stepup` is the explicitly named virtual-controller step-up. It uses Power High during the main Cartesian arc or isolated J6 sweep and returns to Power Low afterward. Do not run that entry on hardware.

The conservative defaults are Power Low, transfer Speed/Accel 20%, linear speed 100 mm/s and acceleration 200 mm/s², tap speed 20 mm/s and stroke 4 mm. In the initial run, Power Low capped J6 near 43 deg/s, making commanded 5/10/20% cases effectively identical. The revised conservative sweep settings are 1/3/6%; rating bounds are 7.2/21.6/43.2 deg/s. Step-up uses 5/15/35%, with J6 bounds 36/108/252 deg/s. These are upper bounds before acceleration, short-path and controller power restrictions, not achieved peaks.

A 0.45 m radius at 252 deg/s gives 1.98 m/s sweet-spot speed. This is the nominal upper bound for the J6 portion, excluding transfers; inspect executed data. It cannot reproduce 25–40 m/s tennis swings. At that radius, 8 rad/s would imply 3.6 m/s, beyond the user's normal 2 m/s limit. The current serve-like/high-forehand pair exercises the tip-up distinction below that threshold; it does not establish classification above 8 rad/s.

## Day-one coverage

- A: tip up, face up/down, +45 degree local-x and local-y tilts, each held 3 s. Tilt reference is the face-up orientation with 135 degree yaw selected for reachability.
- B: forehand/backhand whole-arm arcs at three settings, intended no contact. The app should report no hit; no app output has been collected in this simulator task.
- C: abrupt-stop and reversal cases at the configured acceleration limit. They are no-contact false-hit tests, not an emergency stop.
- D: short linear volley punches through the five fixed-ball offsets above. Full runner uses 10 repetitions each.
- E: forehand/backhand whole-arm contact-labelled arcs at three settings, 10 repetitions each in full runner. Contact is nominal centre crossing, not impact physics.
- F: tip-up overhead and high-forehand paths, three settings. They deliberately carry different shot labels despite tip-up orientation. Threshold crossing is an outstanding coverage limit.
- G: wide/narrow single/double/triple pad-approach gestures at rest and after a swing. The source waits 0.5 s after returning from the swing before the tap approach. No handle impact force or tap score is simulated.

Each isolated wrist control stages 20 degrees from the J6 centre, then sweeps 40 degrees with J1-J5 fixed. Forehand/backhand and overhead shots use coordinated whole-arm Arc3 moves. Static and overhead transfers use endpoint inverse kinematics and a consistent J1 representation to avoid an unnecessary long turn. Endpoint tests passed; complete collision checking still needs the actual scene geometry.

## Executed trajectory logging and sync

The logger reads **RealPos**, not CurPos (the latter is a target). The initial source derives joint angles with `PAgl(RealPos,j)`; the parameterized revision reads `Agl(j)` to retain the controller's actual joint representation. Values are virtual-controller observations, not physical encoders. Time, pose and joint reads are serial and are not an atomic hardware latch.

Raw files are `<path_id>_repNN_<racket>_RCPLUS_RAW.csv`: seconds, joint degrees, robot-frame mm, U/V/W degrees. `tb_events.csv` records exact controller command timestamps for sync and path start; the revised version includes repetition. A command timestamp is not detected IMU onset or ball impact. Align the user's 1 kHz IMU with the measured twitch after collecting real sensor data.

Export without interpolation:

```
python robot/export_rcplus_logs.py D:/EpsonRC70/Projects/TennisBuddyDayOne_20261029
python robot/check_trajectory.py robot/recordings/native/static_tip_up_rep01_E35E.csv
```

Exports use the requested `<path_id>_repNN_<racket>.csv` names and columns `time_s,j1_rad,...,j6_rad,tcp_x_m,tcp_y_m,tcp_z_m,qw,qx,qy,qz`. JSON sidecars retain source, timestamp precision, cadence, gaps, speed estimates, world transform and assumed flange-to-handle transform. Raw files are preserved. Export after the task closes all files: RC+ buffers output while running. Do not interpret an actively growing file as a completed run.

The logger requests a 1 ms wait. The final 48-case run has 466,859 exported samples at approximately 875-917 Hz per file. Maximum gaps range from 4 to 21 ms, so this is not a guaranteed uninterrupted 100 Hz stream. The native joint recording samples at fixed 2 ms (500 Hz). Every gap is reported; missing CSV samples are not invented. Simulator cadence does not guarantee equivalent physical controller capability.

## Native recording and export

The finished [labelled native RC+ recap](recordings/native/TennisBuddy_RCPlus_DayOne_Recap.mp4) runs 11 minutes 15 seconds and covers all 48 entries once, including the corrected right-handed whole-arm forehand/backhand paths. Use the [case index](recordings/native/VIDEO_INDEX.md) to navigate. It was exported from the preserved native playback on 2 November 2026; no motion was rerun. The final parameterized repetition runner rebuilt successfully in RC+ at 03:34:40 PST that day, with no errors. Its only changes from `Executed.prg` are named repetition counts in `tb_full`.

The native Cinepak AVI contains 8,436 frames at 12.5 fps (Play Speed 40 over 2 ms joint samples). The H.264 MP4 has 16,870 frames at 25 fps, using frame duplication, labels and letterboxing. It does not add motion between native frames. Both files were fully decoded and every case reviewed in `video_review_1.jpg` through `video_review_4.jpg`; details are in `video_validation.json` and `video_metadata.json`. Native AVI decoding emits four Cinepak packet diagnostics despite returning all advertised frames; the final MP4 decodes without errors. The joint recording remains the higher-rate motion evidence.

The original USB package was verified on 29 October. That drive was absent when video export completed, so the finished movie is local and has not been added to the USB. Copy the MP4, `VIDEO_INDEX.md`, `video_metadata.json` and `video_validation.json` into that package's `Recordings/` folder when the same drive is reconnected.

Coverage limits remain: only one repetition per case was recorded, impact forces and IMU/app scores are not simulated, the 8 rad/s serve threshold was not crossed, and the green half-plane proxy is not full-arm clearance certification. Post-swing tap timing measures the 0.5 s wait before approach, rather than contact exactly 0.5 s after the swing.

In Simulation mode, choose a recording (the current first recap is `DayOneNative02`) and turn the record button red before starting the program. RC+ overwrites that recording each time a program starts, so preserve successful `.jpos` files before another run. After completion, change to Playback, choose Movie, set an AVI output, and export. Adjust the playback camera so the whole arm and racket are visible. Retain the native `.jpos` and convert the AVI to H.264 for convenient viewing if needed. A native recording is only complete when its export plays and covers the expected cases.

## Envelope and remaining limits

Programmed sweet-spot centres are near world x=0.5 m; static/overhead heights reach 1.05 m, volley heights are 0.42–0.58 m. J6 arcs move the sweet spot around the flange. The exporter checks a conservative racket proxy against world x>=0 and reports its actual min/max coordinates. That check excludes the arm and the fixture, and the image sign remains provisional until checked in the top view. Historical simulator collision-pair settings were disabled for some objects, so absence of red alone is not a clearance certificate.

Keep simulation motion in the supplied green half-plane and inspect the whole arm, racket and transitions. Use reduced-speed dry runs without a ball for later real commissioning. Numeric table, mount and stop-clearance limits must come from the real cell; they cannot be recovered from the screenshot. This task does not authorize any physical robot motion.

## References

- User prompt: 0.50 m sweet-spot estimate, axis conventions, 2 m/s normal limit, two racket names and requested tests.
- Epson C8 data sheet: https://files.support.epson.com/far/docs/epson_c8_6-axis_robots.pdf
- Installed RC+ 7.5 SPEL+ reference: RealPos, PAgl, Agl, TGo, TMove, TLSet, Tmr, Xqt and file I/O.
- Installed RC+ User's Guide 7.5 section 8: native record/playback and AVI export.


## Whole-arm correction and handedness

After the user reviewed the simulator, the shot paths were changed from isolated wrist motion to coordinated whole-arm circular paths. Both forehand and backhand now move the sweet spot from world x=0.35 m to x=0.65 m, pass through the fixed ball at `(0.50,0,0.50)` m, and recover home. The shoulder, elbow and wrist all contribute. Their lateral arcs and face yaw mirror about the ball. The right-handed assignment was corrected from the user's direct RC+ feedback: **forehand uses P853/P854/P855; backhand uses P850/P851/P852**. The same assignment applies to air and contact-labelled cases. Separate `wrist_only_forehand_*` and `wrist_only_backhand_*` controls retain isolated wrist testing.

Whole-arm step-up TCP targets are 0.15/0.40/1.00 m/s, with acceleration 0.30/0.70/1.50 m/s². Dry-run values scale by 0.25 and retain Power Low. These are requested speeds; short paths and controller limits reduce achieved peaks. Forehand/backhand arcs rotate the face by 24 degrees over approximately 0.382 m; the programmed orientation-rate bound is `(24/0.382) * TCP speed` degrees/s. The overhead arcs translate 0.24 m toward the net while rotating 40 degrees, passing through exactly tip-up at the middle of a symmetric arc. Serve-like nominal ball is world `(0.65,-0.18,1.05)` m; high-forehand nominal ball is `(0.60,-0.18,0.95)` m. Their wrist rotation directions oppose. These repeatable diagnostic strokes approximate selected player motions; no biomechanical model or impact dynamics are claimed.

The original wrist-based 42-case baseline is preserved in `recordings/wrist_baseline_20261029/` as diagnostic evidence. The corrected 48-case native run completed on 29 October 2026 at 11:09:48 without a controller error or latched red C8 indication. `recordings/native/Executed.prg` preserves its exact source. The native `.jpos` has 337,425 samples at 2 ms, spanning 674.848 s. Every CSV was matched to all six native joint traces chronologically; maximum alignment RMS was below 0.007 degrees.

The final sampled racket proxy spans world x=0.221-1.197 m, y=-0.747-0.491 m, z=0.148-1.269 m, including logged sync and transfers within each case. All sampled corners remain in the assumed green half-plane. Initial home and post-run return are in native playback but outside the per-case CSV proxy calculation. See `recordings/native/executed_envelope.png` and `summary.json`.

CSV time and position reads are serial. Their 20 ms differences report approximately 264 deg/s and 2.073 m/s for the fastest isolated wrist controls. The independent fixed-2-ms native joint recording verifies J6 at 252.007 deg/s (float32 rounding), consistent with 35% of 720 deg/s and approximately 1.979 m/s at the assumed 0.45 m radius. Do not treat the noisy CSV difference as a hardware speed measurement. Whole-arm fast forehands/backhands reach approximately 0.63-0.65 m/s over the short arc.

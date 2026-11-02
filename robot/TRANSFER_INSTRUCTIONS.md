# Tennis Buddee: transfer to the robot PC

This package contains the corrected right-handed, whole-arm RC+ simulation, its mounted racket CAD, path labels, and executed virtual trajectories. Tested here with Epson RC+ 7.5.4A R1 and a virtual C8-A901S. The main forehand/backhand moves the sweet spot forward 300 mm and then recovers.

## Contents

- `RCPlusProject/`: the native project and the exact `Main.prg` used for the successful 48-case run. Open `TennisBuddyDayOne_20261029.sprj`.
- `SimulatorScene/SimObjects.dat`: the native scene snapshot, including the mounted racket and collision settings.
- `CAD/Robot Arm Test Setup.xv3`: the racket CAD required by that scene.
- `Sources/`: the parameterized program, generator, manifest, full README, and log conversion tools. `DayOne.prg` has the same motion definitions; its full-run repetition counts use named parameters. That repetition-only revision needs Rebuild All before use.
- `Recordings/`: 48 executed virtual CSV files, per-file metadata, raw logs, event times, native 500 Hz playback, timeline, envelope plot and exact executed source.
- `SHA256SUMS.json`: checksums for verifying this copy.

RC+ itself is not included. Use the robot PC's installed, licensed RC+; Python is not needed to run the SPEL+ programs. For the optional CSV conversion tools, use Python 3.10+ with NumPy and SciPy. Only export_rcplus_logs.py and check_trajectory.py are intended to be run directly from Sources in this transfer. The generator, manifest-update, matching and plotting scripts retain the development repository layout assumptions and are included as reference; do not run the generator with --deploy on the robot PC.

## Open and replay in simulation

1. Copy this whole folder from the USB drive to a local folder on the PC. Keep a separate copy of that PC's existing robot project.
2. In RC+, select **Simulator** and verify the status bar identifies a virtual C8-A901S / Dry Run before starting any motion function.
3. Open `RCPlusProject/TennisBuddyDayOne_20261029.sprj`. Use RC+'s Save As to save the local working copy, then **Rebuild All** (Ctrl+Shift+B). Do not use the historical `racket_*` functions from the inherited project.
4. Open Robot Simulator (Ctrl+F5). The supplied scene has absolute source-machine references. Original paths were:
   - scene: `D:\EpsonRC70\Simulator\Simulator\SimObjects.dat`
   - CAD: `C:\Users\qslma\Downloads\Robot Arm Test Setup.xv3`
   - project: `D:\EpsonRC70\Projects\TennisBuddyDayOne_20261029`
   Keep these paths only if appropriate on the destination PC, or reconnect the scene/CAD using RC+'s native project and CAD controls. The XV3 file is included so the CAD does not depend on this machine. The CAD filename property is read-only in RC+; a missing-file prompt, or loading the supplied XV3 again through the CAD toolbar, may be needed. Preserve the mounted-device transform from `SimulatorScene/SimObjects.dat` when reattaching it to robot 1, joint 6. Do not substitute the displayed CAD world position for the tool/IMU transform.
5. The scene snapshot is for the virtual controller. Never restore its robot parameters over the real controller's calibration, safety settings, or existing project. This transfer has not been tested on a second PC; inspect the racket mounting after relocating CAD.
6. Open Run (F5). `main` calls `tb_probe_all`, which checks endpoint reachability without moving. Start with that check.
7. Run `tb_recap` for reduced-speed, Power Low simulation of one repetition of every case. Run `tb_recap_stepup` only in the virtual controller for the faster comparison used in the recorded recap. It uses Power High during the primary stroke.
8. `tb_full` runs the repetition set. The exact tested project source uses 10 for non-static requested tests and three for wrist controls. The parameterized `Sources/DayOne.prg` uses 10 for contact volleys/forehands/backhands, three for other moving tests, and one for static holds. To use that revision, replace the local project's Main.prg, close any older editor tab, and Rebuild All.

Each run performs home, 1 s still, a +4/-4 degree racket-x sync twitch, 1 s still, path, pause and home. The event CSV records commanded sync and path-start times. A command time is not an IMU-detected onset or impact time.

## Choose racket and keep logs

Set `TB_RACKET_NAME` at the top of Main.prg to `E35E` or `E912` before rebuilding, corresponding to BLE names `Tennis Buddy E35E` and `Tennis Buddy E912`. This is a label; the robot does not discover or connect to BLE automatically. Collect the IMU/app recording separately.

Use a new local project/run folder for each session so files are not overwritten. SPEL+ writes `<path_id>_repNN_<racket>_RCPLUS_RAW.csv` and `tb_events.csv` in its project working folder. The logger reads RealPos and Agl, not target positions. After the task closes the files, optionally convert them:

```text
python Sources/export_rcplus_logs.py "C:/your/local/RCPlusProject" --dest "C:/your/local/converted"
python Sources/check_trajectory.py "C:/your/local/converted/forehand_slow_rep01_E35E.csv"
```

Converted CSV columns are time in seconds, six joint angles in radians, TCP metres, and quaternion w,x,y,z. World x = robot -Y toward the net, world y = robot +X, world z = up. Contact offsets in paths.json use x across the face and y toward the tip.

The fixed-rate native `.jpos` is 500 Hz. CSV polling achieved approximately 875-917 Hz here, with occasional gaps up to 21 ms. This is simulator evidence, not a guaranteed physical-controller sampling rate.

## Before adapting this to physical robot motion

The supplied source is marked **SIMULATOR ONLY**. It contains automatic Motor On in motion runners, absolute simulator poses, simulator-specific SimSet calls, and a virtual-only Power High step-up. Copying it onto the robot PC does not validate those commands for the real arm. No controller download or physical motion was performed during this task.

For physical commissioning, first use a copy of the real robot's existing project and retain its calibrated robot model, base, mastering and controller settings. A responsible robot operator must measure the mounting/tool transform, payload and inertia, teach a collision-free home and all approach/return routes, configure the cell's numeric soft limits and clearances, and validate the complete swept arm/racket envelope at reduced speed without a ball. Adapt simulator-only commands and the automatic motor enable to the site's normal start procedure. The supplied screenshot only defines a provisional green half-plane; it is not a measured cell boundary.

The assumed sweet spot is 0.50 m along racket +x from the handle IMU, directly from the user's estimate. Assumed tools are `TLSet 1, XY(0,450,0,90,0,180)` for the sweet spot and `TLSet 2, XY(0,-50,0,90,0,180)` for the sensor, in mm/degrees. Measure these before physical use. Resolve the earlier suspected loose power wire before fast spins. Start with Power Low and the conservative parameters; do not select the virtual step-up on hardware.

The current simulation labels intended ball/tap contact but does not model impact force, IMU readings, or app scores. Tip-up serve/high-forehand examples remain below 8 rad/s, so coverage above that classifier threshold is outstanding. After-swing tap approaches begin 0.5 s after swing recovery; actual nominal pad contact follows the short approach and is later than 0.5 s.

## Verify the transfer

`SHA256SUMS.json` lists every included file and its SHA-256. The copy process verifies destination bytes against those hashes. Preserve `Recordings/DayOneNative02_01.jpos` before starting another recorded run: RC+ can overwrite a recording when a program starts.

The labelled native movie finished on 2 November 2026 at `robot/recordings/native/TennisBuddy_RCPlus_DayOne_Recap.mp4`. It covers all 48 cases once in 11 minutes 15 seconds. The USB was absent at completion, so its original verified package does not yet contain this movie. Add the MP4, `VIDEO_INDEX.md`, `video_metadata.json` and `video_validation.json` to that package's `Recordings/` folder and update `SHA256SUMS.json` after reconnecting the same drive. The native playback and all 48 trajectories were already included in the original transfer.

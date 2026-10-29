# Android validation — pending hardware/build

Run `scripts/android-build.sh` in the pinned CI environment. Require export success, apksigner verification and ZIP integrity before reporting an APK. Store artifact with commit SHA. Device testing cannot be replaced by headless host benchmarks.

1. Install verified APK on an actual low-end Android handset. Record model, SoC, RAM, Android/WebGL irrelevant (native Godot), OS, resolution, renderer, APK SHA256 and commit. Use a cool device, no charging, fixed brightness.
2. Cold boot three times; record time to controllable battle and crashes. Test touch selection, focused attack, pause/hold and single-unit pad movement. Release pad during focus loss; confirm movement stops.
3. Deploy each legal blueprint; confirm weight/budget rejection. Run siege plan and capture test independently. Territory strategy viability is explicitly blocked in STATUS.md.
4. Finish battle, force-close app, relaunch. Verify outcome counted once, territory owner and history persist. Check write-failure messages and corrupted-file recovery separately in test profile.
5. Run 15 minutes with at least 10 active units and repeated deployments. Capture frame-time p50/p95/p99, CPU/GPU timing where available, peak Android PSS, Godot render video memory and thermal throttling. Proposed target: sustained 30 FPS (33.3 ms), p95 ≤40 ms after warmup. Memory budget must be established from device evidence.
6. For memory pressure, use `adb shell dumpsys meminfo com.frontlinezero.game` before/after battles and after five restarts. PSS and engine video-memory figures are distinct; do not sum them as independent allocations. Check for growth, low-memory kills and asset leaks.
7. For frame-time limits, compare same camera, unit count and scripted commands at fixed resolution versus reduced resolution, then reduced visible units. Record on-device CPU/GPU traces with Android tools; Godot's HUD FPS/draw count is supplementary.
8. Treat headless timings as simulation-only. No visual-quality, Android GPU, battery or thermal pass from CI. Record blockers, exact errors and at most two fixes per issue.

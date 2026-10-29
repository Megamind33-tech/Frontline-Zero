# FRONTLINE ZERO — status / 2026-10-29

Current task: first offline Android RTS vertical slice. Canonical runtime: Godot 4.7.2, Compatibility renderer. Repository: Megamind33-tech/Frontline-Zero.

## Implemented
- Aster Republic player versus Veyr Directorate AI; one 100×65 m battlefield.
- Scouts, tanks and artillery; selection, move/focus-fire orders, pause/hold, single-unit direct movement with keyboard or touch pad.
- Modular chassis/weapon/armor blueprints: payload validation, 600-credit deployment budget, actual stat changes.
- Relay capture, HQ destruction, army elimination, six-minute limit; woods reduce damage, mud slows movement, howitzers have minimum range.
- Atomic local outcome persistence, territory owner, wins/losses, capped history, duplicate outcome protection. This is local campaign ownership, not online territorial simulation.
- Three original generated Godot vehicle scenes with firing/recoil animation. Repeatable asset builder; Blender generator also provided but blocked locally.
- Experimental standalone web reference, independently tested simulation. Godot is the Android product; web is a fallback artifact.

## Executable evidence
Run `GODOT_BIN=/path/to/godot bash scripts/verify.sh`.
- Godot: 12 checks (including siege victory), 90-frame headless scene startup and asset generation. See docs/evidence/.
- JavaScript reference: 9 unit tests; standalone HTML build; 30-battle host simulation benchmark.
- Godot headless host simulation measured roughly 0.04–0.06 ms/step with 10 units. This excludes rendering, GPU, phone memory, heat and Android frame times.
- Automated siege plan wins by HQ destruction in 50 simulated seconds.
- No rendered visual QA, physical Android performance result, APK, or successful CI export is claimed here.

## Blockers / bounded attempts
1. Territory strategy balancing: two attempts. Plan 1: scouts on both relays, armor defending base; defeat by army elimination at 19 s, 0 relay score. Plan 2: tanks support wooded relays, artillery center; defeat at 24 s, 22.63 relay score. Siege plan passed in attempt 2 with two heavy tanks, scout and artillery. Stop balancing territory this session. Next action: inspect scout survival/capture pacing and supporting armor positions with replay evidence; do not simply weaken AI or claim both strategies work.
2. Blender 5.2.3 archive downloaded and SHA256 verified. `blender --background --python scripts/build_assets.py ...` and `blender --version` both exited 139 (Segmentation fault), after correcting executable permission. Stop retries. Next action: run on supported CI host or investigate CPU/runtime compatibility. Godot asset generator replaces the blocked asset build for this slice.
3. Godot export-template download: two attempts to official 4.7.2 release both failed with curl (28), `Proxy CONNECT aborted due to timeout`. No complete template archive. Next action: CI fetch on GitHub runner.
4. Android SDK and complete JDK are absent locally. Android export script and CI provided; unverified until CI executes and signed APK verification passes. No phone attached.
5. Browser QA blocked: runtime Playwright has no browser binary; install command failed with `End of central directory record signature not found` on browser download. Do not repeat installs. Browser smoke script remains unverified.

## Next task / handoff
Run the committed CI, inspect its logs, and fix only reproducible export errors. Preserve this baseline. Download APK if CI succeeds. On real low-end Android: cold start, 15-minute battle, selection/direct-control inputs, save/relaunch, memory/thermal and frame-time capture. Territory balance is a separate feature task after the two-attempt stop.

## First GitHub CI result
Committed baseline: `be0aba00c5d283e10442a32c7ebcf264d00f6703`.
Run: https://github.com/Megamind33-tech/Frontline-Zero/actions/runs/40870357023
The verify job did **not start**. Its check annotation states: "The job was not started because your account is locked due to a billing issue." Android job was skipped. No CI code/build result and no APK exists. No reruns attempted. Next action: account owner resolves the GitHub billing lock, then runs the existing workflow; alternatively use a provisioned local Android build host. Do not treat this as a game-code failure or chargeable authorization to change billing.

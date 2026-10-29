# FRONTLINE ZERO — direct-touch Android development build

Source: [`11a2d3a`](https://github.com/Megamind33-tech/Frontline-Zero/tree/11a2d3a23ae23b25dac7d11ed16785958ac157e6) on `battle/convincing-vertical-slice`. Main remains unchanged. This isolated branch hosts downloadable artifacts; do not merge binaries into main.

## Download

- [Android APK](./FRONTLINE_ZERO-direct-touch-debug.apk?raw=true): complete debug-signed Android package, API 24+ (Android 7+), ARM64 and ARMv7. Not a PCK and not a production/store release.
- [Actual gameplay recording](./DIRECT_TOUCH-gameplay.mp4?raw=true): 33.9-second Godot recording using engine-dispatched scripted gestures/HUD input. Includes HQ management, long press/queue, live-target attacks, pinch/rotation, control groups and a genuine saved defeat. Not manual phone testing. Recorded before the final HQ text-wrap fix; its corrected runtime capture is below.
- [Actual battle screenshot](./IRON_CROSSING-in-engine.png?raw=true), [corrected management screenshot](./DIRECT_TOUCH-management.png?raw=true). Neither image is AI concept art.
- [Host rendered profile](./IRON_CROSSING-host-performance.json?raw=true), [input CPU benchmark](./DIRECT_TOUCH-input-performance.json?raw=true), [verification summary](./verification-summary.log?raw=true), [SHA-256 checksums](./SHA256SUMS.txt?raw=true).

## Implemented controls

Tap friendly units to select; tap terrain to move or hostile units/HQ to attack. Selected units follow live targets and hold legal weapon range. Drag pans, pinch zooms and two fingers rotate. Hold a selected unit for advanced orders. Double tap selects nearby matching classes. Optional additive selection and persistent groups 1–3. Friendly HQ opens actual management/workshop. No permanent Move/Attack/directional camera buttons. Formations, queued orders, direct drive, original AI and result persistence remain.

## Verification and limits

139 Godot checks plus nine JavaScript tests pass, including the unchanged siege regression. APK v2/v3 signature, ZIP integrity, manifest, both native architectures and MIT/original-art notices verified. Source evidence: [tests and performance](https://github.com/Megamind33-tech/Frontline-Zero/tree/11a2d3a23ae23b25dac7d11ed16785958ac157e6/docs/evidence/direct-touch), [input behavior/scope](https://github.com/Megamind33-tech/Frontline-Zero/blob/11a2d3a23ae23b25dac7d11ed16785958ac157e6/docs/DIRECT_TOUCH.md).

No physical Android device is attached. Installation, phone touch latency, frame times, memory pressure and thermals are unverified. Host rendering uses Mesa llvmpipe on three logical CPUs at 1280×720: p50/p95 frame intervals 157/183 ms (below 30 FPS), draw calls 132/146; static/renderer/sample-RSS metrics are separate in the JSON. Headless input dispatch p95 is 0.162 ms; it excludes display/device latency.

The game remains ground-only and uses existing straight-line movement; obstacle-aware pathfinding, collision/separation, air/naval units and strategic defense are not newly implemented. The art is a first original integration pass, not a claim of completed commercial visual quality. No engine change or BAR/GPL gameplay copy.

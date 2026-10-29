# FRONTLINE ZERO — token-controlled development
Read this file, docs/STATUS.md, and the current task. Inspect other files only as needed.
Preserve verified builds. One independently testable feature at a time.
Use scripts for verification. No parallel agents without an independent task and explicit budget.
After two failed attempts on the same blocker, record exact errors, fixes and next action; stop retrying.
Never claim functionality without executable evidence. Commit verified changes and update docs/STATUS.md.
Before stopping, record the next task and blockers. Keep user reports under 150 words.
Canonical runtime: Godot 4.7.2, fully 3D scenes, Compatibility renderer. The JavaScript/Canvas build is an experimental reference only.
Commands: GODOT_BIN=/path/to/godot bash scripts/verify.sh; bash scripts/android-build.sh.
Preserve vendored license notices and pinned provenance in godot/third_party. Do not import BAR art or GPL source into this project without an explicit licensing decision.

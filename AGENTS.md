# FRONTLINE ZERO — token-controlled development
Read this file, docs/STATUS.md, and the current task. Inspect other files only as needed.
Preserve verified builds. One independently testable feature at a time.
Use scripts for verification. No parallel agents without an independent task and explicit budget.
After two failed attempts on the same blocker, record exact errors, fixes and next action; stop retrying.
Never claim functionality without executable evidence. Commit verified changes and update docs/STATUS.md.
Before stopping, record the next task and blockers. Keep user reports under 150 words.
Runtime: dependency-free JavaScript simulation + Canvas UI; native offline Android WebView shell.
Commands: npm run verify; npm run test:browser; bash scripts/android-build.sh.

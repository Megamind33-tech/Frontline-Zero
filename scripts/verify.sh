#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
FZ_GODOT="${GODOT_BIN:-$PWD/.tools/godot}"
mkdir -p dist
run() {
 local logfile="$1"
 shift
 "$@" >"dist/$logfile" 2>&1
 cat "dist/$logfile"
 if rg -q 'SCRIPT ERROR:|^ERROR:|FAIL:' "dist/$logfile"; then return 1; fi
}
run godot-assets.log "$FZ_GODOT" --headless --path godot --script tests/build_assets.gd
run godot-import.log "$FZ_GODOT" --headless --path godot --editor --import --quit
run battle-asset-tests.log "$FZ_GODOT" --headless --path godot --script tests/battle_asset_suite.gd
run godot-tests.log "$FZ_GODOT" --headless --path godot --script tests/suite.gd
run formation-tests.log "$FZ_GODOT" --headless --path godot --script tests/formation_suite.gd
run queue-tests.log "$FZ_GODOT" --headless --path godot --script tests/queue_suite.gd
run battle-tests.log "$FZ_GODOT" --headless --path godot --script tests/battle_suite.gd
run direct-touch-tests.log "$FZ_GODOT" --headless --path godot --script tests/touch_suite.gd
run production-tests.log "$FZ_GODOT" --headless --path godot --script tests/production_suite.gd
run godot-smoke.log "$FZ_GODOT" --headless --path godot --quit-after 90
npm run verify >dist/verify.log 2>&1
cat dist/verify.log
# tactics.gd is an explicit known balance blocker; see docs/STATUS.md.

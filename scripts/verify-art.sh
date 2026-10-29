#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
FZ_ART="$PWD/.tools/art-generated"
FZ_GODOT="${GODOT_BIN:-$PWD/.tools/godot}"
FZ_BLENDER="${BLENDER_BIN:-blender}"
mkdir -p dist "$FZ_ART"
"$FZ_BLENDER" --background --factory-startup --python scripts/build_assets.py -- "$FZ_ART" >dist/blender-pipeline.log 2>&1
cat dist/blender-pipeline.log
if rg -q 'Traceback|Error:|Segmentation fault' dist/blender-pipeline.log; then exit 1; fi
"$FZ_GODOT" --headless --path godot --script tests/art_pipeline_suite.gd -- "$FZ_ART" >dist/art-pipeline-tests.log 2>&1
cat dist/art-pipeline-tests.log
if rg -q 'SCRIPT ERROR:|^ERROR:|FAIL:' dist/art-pipeline-tests.log; then exit 1; fi
python3 - <<'PYKIT'
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
root=Path.cwd()
generated=root/'.tools/art-generated'
with ZipFile(root/'dist/FRONTLINE_ZERO-art-kit.zip','w',ZIP_DEFLATED) as kit:
 for path in sorted(generated.rglob('*')):
  if path.suffix in ['.glb','.blend'] or path.name=='manifest.json':
   kit.write(path,Path('models')/path.relative_to(generated))
 for path in sorted((root/'art').rglob('*')):
  if path.is_file(): kit.write(path,Path('art')/path.relative_to(root/'art'))
 kit.write(root/'godot/icon.svg','art/app-icon.svg')
print('PACKAGED: dist/FRONTLINE_ZERO-art-kit.zip (original art and editable sources)')
PYKIT

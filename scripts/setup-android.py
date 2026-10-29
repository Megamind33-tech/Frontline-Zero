#!/usr/bin/env python3
"""Install pinned Linux x86_64 Android build dependencies inside .tools.

Official downloads only. Run sdkmanager --licenses afterwards to review SDK terms.
No system packages, engine version or project runtime are changed.
"""
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
TOOLS = ROOT / '.tools'
SDK = TOOLS / 'android-sdk'
LOCK = json.loads((ROOT / 'scripts/toolchain-lock.json').read_text())


def install(package):
    archive = TOOLS / 'downloads' / package['url'].split('/')[-1]
    archive.parent.mkdir(parents=True, exist_ok=True)
    algorithm = 'sha256' if 'sha256' in package else 'sha1'

    def valid():
        if not archive.is_file() or archive.stat().st_size != package['size']:
            return False
        with archive.open('rb') as stream:
            return hashlib.file_digest(stream, algorithm).hexdigest() == package[algorithm]

    if not valid():
        part = archive.with_suffix(archive.suffix + '.part')
        print('Downloading', package['id'], flush=True)
        with urllib.request.urlopen(package['url'], timeout=60) as src, part.open('wb') as dst:
            shutil.copyfileobj(src, dst)
        part.replace(archive)
        if not valid():
            raise RuntimeError('Size/checksum mismatch: ' + archive.name)
    print('Verified', package['id'], flush=True)
    with tempfile.TemporaryDirectory(dir=TOOLS) as temporary:
        stage = pathlib.Path(temporary)
        if package['id'] == 'jdk-17':
            with tarfile.open(archive) as bundle:
                bundle.extractall(stage, filter='data')
            source = next(stage.iterdir())
            target = TOOLS / 'jdk-17'
        else:
            with zipfile.ZipFile(archive) as bundle:
                for member in bundle.infolist():
                    destination = (stage / member.filename).resolve()
                    if not destination.is_relative_to(stage.resolve()):
                        raise RuntimeError('Unsafe archive path')
                bundle.extractall(stage)
                # Zip extraction does not preserve the executable mode.
                for member in bundle.infolist():
                    if (member.external_attr >> 16) & 0o111:
                        (stage / member.filename).chmod(0o755)
            source = next(stage.iterdir())
            name = package['id']
            if name.startswith('cmdline-tools;'):
                target = SDK.joinpath(*name.split(';'))
            elif name == 'platform-tools':
                target = SDK / name
            else:
                target = SDK.joinpath(*name.split(';'))
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            shutil.rmtree(target)
        shutil.move(str(source), target)


def main():
    if os.uname().sysname != 'Linux' or os.uname().machine != 'x86_64':
        raise SystemExit('This lock file supports Linux x86_64 only')
    TOOLS.mkdir(exist_ok=True)
    for package in LOCK['packages']:
        install(package)
    # Resolve paths at source time; this file contains no signing secrets.
    (TOOLS / 'android-env.sh').write_text('''# Source from a Bash shell.
FZ_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export ANDROID_HOME="$FZ_ROOT/.tools/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$FZ_ROOT/.tools/android-user"
mkdir -p "$ANDROID_USER_HOME"
export JAVA_HOME="$FZ_ROOT/.tools/jdk-17"
export GODOT_BIN="$FZ_ROOT/.tools/godot"
export XDG_DATA_HOME="$FZ_ROOT/.tools/data"
export XDG_CACHE_HOME="$FZ_ROOT/.tools/cache"
export XDG_CONFIG_HOME="$FZ_ROOT/.tools/config"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/19.0/bin:$ANDROID_HOME/platform-tools:$PATH"
unset FZ_ROOT
''')
    subprocess.run([str(TOOLS / 'jdk-17/bin/javac'), '-version'], check=True)
    print('Source .tools/android-env.sh; review Android terms with sdkmanager --licenses.')


if __name__ == '__main__':
    main()

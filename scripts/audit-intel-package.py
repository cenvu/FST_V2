#!/usr/bin/env python3
"""Fail-closed audit of staged, zipped, or re-downloaded v1.4.0 Intel apps."""
import argparse
import hashlib
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import zipfile


def run(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.STDOUT)


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def audit(app, unsigned):
    require(app.is_dir(), "App missing")
    plist = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    for key, value in {"CFBundleShortVersionString": "1.4.0", "CFBundleVersion": "20261003", "LSMinimumSystemVersion": "13.5"}.items():
        require(plist.get(key) == value, f"Incorrect {key}: {plist.get(key)}")
    main = app / "Contents/MacOS/FishSockTransfer"
    rsync = app / "Contents/Resources/rsync"
    for executable in (main, rsync):
        require(executable.is_file() and os.access(executable, os.X_OK), "Executable missing")
        require(run("/usr/bin/lipo", "-archs", str(executable)).strip() == "x86_64", "Main/rsync architecture mismatch")
    forbidden = re.compile(r"/Users/[^/\s]+/|github_pat_|gh[pousr]_[A-Za-z0-9]{20,}|sk-(?:proj-)?[A-Za-z0-9_-]{20,}|[0-9]{6,12}:[A-Za-z0-9_-]{25,}|(?:chat[_ ]?id)[\"'\s:=]+-?[0-9]{5,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[A-Z0-9]{16}", re.I)
    macho_count = 0
    for path in sorted(app.rglob("*")):
        require(path.name not in (".git", ".DS_Store", "build", "DerivedData", "__MACOSX") and not path.name.startswith("._"), f"Forbidden artifact: {path.name}")
        require(path.suffix.lower() not in (".swift", ".xcresult", ".xcodeproj", ".xcworkspace"), f"Source/build artifact: {path.name}")
        require(not ("screenshot" in path.name.lower() or path.suffix.lower() in (".jpg", ".jpeg")), f"Screenshot artifact: {path.name}")
        if path.is_symlink():
            require(path.resolve().is_relative_to(app.resolve()), "Bundle symlink escapes app")
        if not path.is_file():
            continue
        strings = run("/usr/bin/strings", str(path))
        require(not forbidden.search(strings), f"Privacy scan failed in {path.name}; sensitive value redacted")
        description = run("/usr/bin/file", "-b", str(path))
        if "Mach-O" not in description:
            continue
        macho_count += 1
        architectures = run("/usr/bin/lipo", "-archs", str(path)).strip()
        require(architectures == "x86_64", f"Non-Intel Mach-O: {path.name}: {architectures}")
        linked = run("/usr/bin/otool", "-L", str(path))
        print(f"MACHO={path.relative_to(app)} FILE={description.strip()} ARCH={architectures}\n{linked}", end="")
        require(not re.search(r"/usr/local/(Cellar|opt)|/opt/homebrew|/opt/local", linked), "Homebrew/MacPorts runtime leakage")
        # This package intentionally contains no non-system dylib dependencies.
        for line in linked.splitlines()[1:]:
            dependency = line.strip().split(" ", 1)[0]
            require(dependency.startswith(("/usr/lib/", "/System/Library/")), f"Non-system loader dependency: {dependency}")
        commands = run("/usr/bin/otool", "-l", str(path))
        require(not re.search(r"path /(?:Users/|usr/local/|opt/)", commands), "Unsafe LC_RPATH")
    require(macho_count >= 2, "Missing packaged Mach-O executables")
    version = run(str(rsync), "--version")
    require(re.match(r"^rsync +version 3\.4\.4 +protocol version 32\n", version) is not None, "Incorrect rsync version/protocol")
    print(version)
    smoke(rsync)
    if not unsigned:
        print(run("/usr/bin/codesign", "--verify", "--deep", "--strict", "--verbose=4", str(app)), end="")
    print("APP_VERSION=1.4.0 BUILD_NUMBER=20261003 MIN_MACOS=13.5 APP_ARCH=x86_64")
    print("MACHO_ARCH_SCAN=PASS RSYNC_LOADER_AUDIT=PASS PRIVACY_SCAN=PASS LOCAL_TRANSFER_SMOKE=PASS")


def smoke(rsync):
    # Disposable generated fixtures only. Hashes/mode/mtime prove source unchanged.
    with tempfile.TemporaryDirectory(prefix="fst-intel-smoke-") as root:
        source = Path(root) / "CARD"
        source.mkdir()
        (source / "nested").mkdir()
        (source / "normal.mov").write_bytes(b"FST disposable media\n" * 1024)
        (source / "nested/clip.bin").write_bytes(bytes(range(256)) * 256)
        (source / ".DS_Store").write_text("excluded")
        (source / "nested/.DS_Store").write_text("excluded")
        (source / "._clip").write_text("excluded")
        for name in (".Spotlight-V100", ".Trashes", ".fseventsd", ".TemporaryItems"):
            (source / name).mkdir()
            (source / name / "excluded").write_text("excluded")
        def snapshot():
            return {str(p.relative_to(source)): (hashlib.sha256(p.read_bytes()).hexdigest() if p.is_file() else None, p.stat().st_mode, p.stat().st_mtime_ns) for p in [source, *source.rglob("*")]}
        before = snapshot()
        exclusions = [".DS_Store", "._*", ".Spotlight-V100", ".Trashes", ".fseventsd", ".TemporaryItems"]
        # Unlimited omits --bwlimit; all seven canonical MB/s conversions execute.
        for limit in (None, 51200, 76800, 102400, 128000, 153600, 179200, 204800):
            destination = Path(root) / f"dest-{limit}"
            destination.mkdir()
            args = [str(rsync), "-a", "-h", "--info=name1,progress2", "--outbuf=N"]
            if limit is not None:
                args.append(f"--bwlimit={limit}")
            args += [f"--exclude={pattern}" for pattern in exclusions]
            args += [str(source), str(destination) + "/"]
            output = run(*args)
            require("normal.mov" in output, "rsync name/progress output missing")
            copied = destination / "CARD"
            require(sorted(str(p.relative_to(copied)) for p in copied.rglob("*")) == ["nested", "nested/clip.bin", "normal.mov"], "Copy/exclusion mismatch")
            for name in ("normal.mov", "nested/clip.bin"):
                require((copied / name).read_bytes() == (source / name).read_bytes(), "Transfer content mismatch")
            require(snapshot() == before, "Source changed during disposable transfer")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    parser.add_argument("--unsigned", action="store_true")
    args = parser.parse_args()
    require(run("/usr/bin/uname", "-m").strip() == "x86_64", "Native Intel audit required")
    if args.package.suffix == ".zip":
        with tempfile.TemporaryDirectory(prefix="fst-intel-zip-audit-") as root:
            with zipfile.ZipFile(args.package) as archive:
                for name in archive.namelist():
                    parts = Path(name).parts
                    require(parts and parts[0] == "FishSockTransfer.app" and ".." not in parts, "Unexpected ZIP entry")
            subprocess.run(["/usr/bin/ditto", "-x", "-k", str(args.package.resolve()), root], check=True)
            audit(Path(root) / "FishSockTransfer.app", False)
        print("ZIP_AUDIT=PASS CODESIGN=PASS")
    else:
        audit(args.package.resolve(), args.unsigned)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
# SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
"""
Консистентная ad-hoc переподпись Antigravity.app.

Зачем это нужно
---------------
Оригинальный бандл Google подписан одним Team ID. После патча и ad-hoc
переподписи Team ID исчезает, и dyld отказывается загружать Electron
Framework:

    mapped file has no Team ID and is not a platform binary
    Library not loaded: @rpath/Electron Framework.framework/Electron Framework

Скрипт переподписывает бандл изнутри наружу и добавляет каждому исполняемому
файлу entitlement com.apple.security.cs.disable-library-validation, сохраняя
остальные entitlements (allow-jit, camera, audio и т.д.).

Использование
-------------
    ./scripts/resign.py ~/Applications/Antigravity.app
    ./scripts/resign.py            # путь по умолчанию

Код возврата: 0 — подпись валидна, 1 — есть ошибки.
"""

from __future__ import annotations

import argparse
import os
import plistlib
import subprocess
import sys
import tempfile
from pathlib import Path

KEY = "com.apple.security.cs.disable-library-validation"
MACHO_MAGICS = {
    b"\xcf\xfa\xed\xfe",  # 64-bit little-endian
    b"\xce\xfa\xed\xfe",  # 32-bit little-endian
    b"\xca\xfe\xba\xbe",  # universal (big-endian header)
    b"\xbe\xba\xfe\xca",  # universal (little-endian header)
    b"\xfe\xed\xfa\xce",  # 32-bit big-endian
    b"\xfe\xed\xfa\xcf",  # 64-bit big-endian
}
BUNDLE_SUFFIXES = (".app", ".framework", ".xpc", ".bundle", ".appex")
DEFAULT_APP = Path.home() / "Applications" / "Antigravity.app"


def is_macho(path: Path) -> bool:
    try:
        with path.open("rb") as f:
            return f.read(4) in MACHO_MAGICS
    except OSError:
        return False


def read_entitlements(path: Path) -> dict | None:
    """Читает entitlements; None — если их нет или не удалось разобрать."""
    for fmt in (":-", "-"):
        try:
            r = subprocess.run(
                ["codesign", "-d", "--entitlements", fmt, str(path)],
                capture_output=True,
            )
        except OSError:
            return None
        if not r.stdout.strip():
            continue
        try:
            return plistlib.loads(r.stdout)
        except Exception:
            continue
    return None


def sign(path: Path, entitlements: dict | None, runtime: bool) -> tuple[bool, str]:
    tmp = None
    cmd = ["codesign", "--force", "--sign", "-"]
    if runtime:
        cmd += ["--options", "runtime"]
    if entitlements is not None:
        fd, tmp = tempfile.mkstemp(suffix=".plist")
        os.close(fd)
        with open(tmp, "wb") as f:
            plistlib.dump(entitlements, f)
        cmd += ["--entitlements", tmp]
    cmd.append(str(path))
    try:
        r = subprocess.run(cmd, capture_output=True, text=True)
    finally:
        if tmp:
            os.unlink(tmp)
    return r.returncode == 0, r.stderr.strip()


def bundle_executable(bundle: Path) -> Path | None:
    """Находит главный исполняемый файл бандла."""
    info = bundle / "Contents" / "Info.plist"
    if not info.exists():
        info = bundle / "Resources" / "Info.plist"
    if info.exists():
        try:
            with info.open("rb") as f:
                pl = plistlib.load(f)
            exe = pl.get("CFBundleExecutable")
            if exe:
                for candidate in (
                    bundle / "Contents" / "MacOS" / exe,
                    bundle / exe,
                    bundle / "Versions" / "Current" / exe,
                ):
                    if candidate.exists():
                        return candidate
        except Exception:
            pass
    for base in (bundle / "Versions" / "Current", bundle):
        if base.is_dir():
            for child in base.iterdir():
                if child.is_file() and is_macho(child):
                    return child
    return None


def collect_machos(app: Path) -> list[Path]:
    result: list[Path] = []
    for root, _dirs, files in os.walk(app / "Contents"):
        for name in files:
            path = Path(root) / name
            if path.is_symlink() or name.endswith(".agybak"):
                continue
            if is_macho(path):
                result.append(path)
    # изнутри наружу: сначала глубоко вложенные файлы
    result.sort(key=lambda p: len(p.parts), reverse=True)
    return result


def collect_bundles(app: Path) -> list[Path]:
    result: list[Path] = []
    for root, dirs, _files in os.walk(app / "Contents"):
        for name in dirs:
            if name.endswith(BUNDLE_SUFFIXES):
                result.append(Path(root) / name)
    result.sort(key=lambda p: len(p.parts), reverse=True)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Консистентная ad-hoc переподпись Antigravity.app"
    )
    parser.add_argument(
        "app",
        nargs="?",
        default=str(DEFAULT_APP),
        help=f"путь к .app (по умолчанию: {DEFAULT_APP})",
    )
    parser.add_argument(
        "--no-runtime",
        action="store_true",
        help="не добавлять --options runtime",
    )
    args = parser.parse_args()

    app = Path(args.app).expanduser().resolve()
    if not app.is_dir():
        print(f"Ошибка: не найдено приложение: {app}", file=sys.stderr)
        return 1

    runtime = not args.no_runtime
    failures = 0

    machos = collect_machos(app)
    print(f"Mach-O файлов: {len(machos)}")
    for path in machos:
        ent = read_entitlements(path) or {}
        ent[KEY] = True
        ok, err = sign(path, ent, runtime)
        if not ok:
            failures += 1
            print(f"  FAIL {path.relative_to(app)}: {err[:160]}")

    bundles = collect_bundles(app)
    print(f"Бандлов: {len(bundles)}")
    for bundle in bundles:
        exe = bundle_executable(bundle)
        ent = read_entitlements(exe) if exe else None
        if ent is not None:
            ent[KEY] = True
        ok, err = sign(bundle, ent, runtime)
        if not ok:
            failures += 1
            print(f"  FAIL {bundle.relative_to(app)}: {err[:160]}")

    main_exe = app / "Contents" / "MacOS" / "Antigravity"
    ent = read_entitlements(main_exe) or {}
    ent[KEY] = True
    ok, err = sign(app, ent, runtime)
    if not ok:
        failures += 1
        print(f"  FAIL {app.name}: {err[:160]}")
    else:
        print("Главный бандл: OK")

    verify = subprocess.run(
        ["codesign", "--verify", "--deep", "--strict", str(app)],
        capture_output=True,
        text=True,
    )
    print(f"VERIFY EXIT: {verify.returncode}")
    if verify.stderr.strip():
        print(verify.stderr.strip()[:800])
    print(f"FAILURES: {failures}")

    return 0 if verify.returncode == 0 and failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())

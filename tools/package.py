#!/usr/bin/env python3
"""Build the installable DotaRaid ZIP for a GitHub release tag."""

import argparse
from pathlib import Path
import re
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parent.parent
TOC = ROOT / "DotaRaid.toc"
VERSION_TAG = re.compile(r"v(\d+\.\d+\.\d+)")


def package(tag, output_dir):
    toc = TOC.read_text(encoding="utf-8")
    core = (ROOT / "Core.lua").read_text(encoding="utf-8")
    toc_version = re.search(r"^## Version:[ \t]*(\S+)[ \t]*$", toc, re.MULTILINE)
    core_version = re.search(r'^ns\.VERSION\s*=\s*"([^"]+)"', core, re.MULTILINE)
    if tag is None:
        if not toc_version:
            raise ValueError(f"missing ## Version in {TOC.name}")
        tag = f"v{toc_version[1]}"
    match = VERSION_TAG.fullmatch(tag)
    if not match:
        raise ValueError("release tag must have the form vMAJOR.MINOR.PATCH")
    version = match[1]
    if not toc_version or toc_version[1] != version:
        raise ValueError(f"{tag} does not match ## Version in {TOC.name}")
    if not core_version or core_version[1] != version:
        raise ValueError(f"{tag} does not match ns.VERSION in Core.lua")

    files = [TOC]
    for line in toc.splitlines():
        entry = line.strip()
        if not entry or entry.startswith("#"):
            continue
        path = Path(entry.replace("\\", "/"))
        if path.is_absolute() or ".." in path.parts or not (ROOT / path).is_file():
            raise ValueError(f"invalid or missing TOC entry: {entry}")
        files.append(ROOT / path)
    media = sorted(path for path in (ROOT / "Media").rglob("*") if path.is_file())
    if not media:
        raise ValueError("no Media assets found")
    files.extend(media)

    output_dir.mkdir(parents=True, exist_ok=True)
    archive = output_dir / f"DotaRaid-{tag}-forever.zip"
    with ZipFile(archive, "w", compression=ZIP_DEFLATED) as zipped:
        for path in dict.fromkeys(files):
            zipped.write(path, f"DotaRaid/{path.relative_to(ROOT).as_posix()}")
    with ZipFile(archive) as zipped:
        bad_file = zipped.testzip()
        if bad_file:
            raise ValueError(f"ZIP verification failed: {bad_file}")
    return archive


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tag", nargs="?", help="release tag, e.g. v0.1.0 (defaults to the TOC version)")
    parser.add_argument("--output-dir", type=Path, default=Path("dist"))
    args = parser.parse_args()
    try:
        archive = package(args.tag, args.output_dir)
    except (ValueError, OSError) as error:
        parser.exit(1, f"Packaging failed: {error}\n")
    print(f"Created {archive}")


if __name__ == "__main__":
    main()

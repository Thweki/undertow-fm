"""Build portable desktop archives, a source archive, and optionally the Web export."""
from __future__ import annotations
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "release"
VERSION = "1.0.0"
PREFIX = f"UndertowFM-{VERSION}"
TARGETS = {
    "macOS": ("macOS-universal-unsigned", "UndertowFM.app"),
    "Windows": ("Windows-x64", "Windows/UndertowFM.exe"),
    "Linux": ("Linux-x64", "Linux/UndertowFM.x86_64"),
    "Web": ("Web", "web/index.html"),
}
# Files emitted by the stock 4.7.2 single-threaded template and the Web preset.
# List them explicitly so an older export's service worker cannot enter the zip.
WEB_FILES = (
    "index.html", "index.js", "index.wasm", "index.pck",
    "index.audio.worklet.js", "index.audio.position.worklet.js",
    "index.png", "index.icon.png", "index.apple-touch-icon.png",
)

def add_tree(z: zipfile.ZipFile, folder: Path, base: str):
    for path in sorted(folder.rglob("*")):
        if path.name != ".DS_Store":
            z.write(path, str(Path(base) / path.relative_to(folder)))

def make_binary_archive(key: str):
    platform, entry = TARGETS[key]
    executable = OUT / entry
    archive = OUT / f"{PREFIX}-{platform}.zip"
    with tempfile.TemporaryDirectory(dir=OUT) as temp:
        folder = Path(temp) / "UndertowFM"
        folder.mkdir()
        if key == "Web":
            for name in WEB_FILES:
                shutil.copy2(executable.parent / name, folder / name)
        elif key == "macOS":
            if (executable / "Contents" / "_CodeSignature").exists():
                raise ValueError(
                    f"{executable} contains signature files. Re-export with the unsigned macOS preset."
                )
            shutil.copytree(executable, folder / executable.name)
        else:
            shutil.copy2(executable, folder / executable.name)
            shutil.copy2(executable.with_suffix(".pck"), folder / executable.with_suffix(".pck").name)
        if key != "Web":
            shutil.copy2(ROOT / "tools/pack/游玩说明.txt", folder / "游玩说明.txt")
        shutil.copytree(ROOT / "licenses", folder / "licenses")
        tmp_archive = Path(temp) / "result.zip"
        with zipfile.ZipFile(tmp_archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as output:
            add_tree(output, folder, "" if key == "Web" else "UndertowFM")
        os.replace(tmp_archive, archive)
    return archive

def make_source_archive():
    archive = OUT / f"{PREFIX}-Godot-source.zip"
    files = [
        "project.godot", "export_presets.cfg", ".gitignore", "README.md",
        "README.zh.md", "PACKAGING_NOTES.md", ".github/workflows/package.yml",
    ]
    with zipfile.ZipFile(archive.with_suffix(".tmp"), "w", zipfile.ZIP_DEFLATED, compresslevel=6) as output:
        for name in files:
            output.write(ROOT / name, "UndertowFM/" + name)
        for directory in ["assets", "game", "licenses", "tools"]:
            for path in sorted((ROOT / directory).rglob("*")):
                if not path.is_file() or "__pycache__" in path.parts or path.name == ".DS_Store":
                    continue
                output.write(path, str(Path("UndertowFM") / path.relative_to(ROOT)))
        output.writestr("UndertowFM/release/.gdignore", "")
    os.replace(archive.with_suffix(".tmp"), archive)
    return archive

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pack-only", action="store_true", help="Package existing exports in release/")
    parser.add_argument("--web", action="store_true", help="Also package the desktop-browser Web export")
    args = parser.parse_args()
    OUT.mkdir(exist_ok=True)
    (OUT / ".gdignore").touch()
    godot = os.environ.get("GODOT", "godot")
    if not args.pack_only:
        subprocess.run([godot, "--headless", "--editor", "--import", "--path", str(ROOT)], check=True)
    archives = []
    for key, (_, entry) in TARGETS.items():
        if key == "Web" and not args.web:
            continue
        (OUT / entry).parent.mkdir(parents=True, exist_ok=True)
        if not args.pack_only:
            subprocess.run([godot, "--headless", "--path", str(ROOT), "--export-release", key, str(OUT / entry)], check=True)
        archives.append(make_binary_archive(key))
    archives.append(make_source_archive())
    checksum = OUT / "SHA256SUMS.txt"
    with checksum.open("w", encoding="utf-8") as file:
        for archive in archives:
            with archive.open("rb") as stream:
                digest = hashlib.file_digest(stream, "sha256").hexdigest()
            file.write(f"{digest}  {archive.name}\n")
            print(archive.name, archive.stat().st_size)

if __name__ == "__main__":
    main()

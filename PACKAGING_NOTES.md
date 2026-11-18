# Follow-on packaging for Undertow FM

These changes package version 1.0.0 of the GPT-6.2 Astra test artifact with the official Godot 4.7.2 editor and standard export templates.

## Files changed

| File | Change and reason |
| --- | --- |
| `export_presets.cfg` | Turns off macOS code signing for the unsigned universal build. Adds a Web preset at `release/web/index.html` using the project's Compatibility renderer and Godot's single-threaded template. It disables PWA support, includes the existing license texts, and excludes `tools/` and `release/`. |
| `tools/package_release.py` | Copies the macOS app bundle with Python and preserves Unix executable permissions when archiving on Linux. Labels the macOS zip as unsigned and rejects bundles containing a `_CodeSignature` directory. Adds the optional Web zip and the `GODOT` executable override. Includes both READMEs, the workflow and these notes in the rebuilt project-source zip. |
| `tools/pack/游玩说明.txt` | Corrects the line about local signing. Players now see that the macOS build is unsigned and unnotarized. |
| `game/sound.gd` | Skips installing the Master hard limiter on Web. The game's players use the default sample playback path there, which cannot apply bus effects. Desktop players still use the original limiter. [Godot Web audio documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html#audio-playback) |
| `.github/workflows/package.yml` | Runs the packager on a standard GitHub-hosted Ubuntu runner for any tag push or manual dispatch. Pins the checksum manifest's published SHA-256 and verifies the Linux editor and non-Mono templates against its SHA-512 entries before extraction. Uploads the zips and `SHA256SUMS.txt` together as the `UndertowFM-packages` workflow artifact. [Official release files](https://github.com/godotengine/godot/releases/expanded_assets/4.7.2-stable) |
| `PACKAGING_NOTES.md` | Records the changes made after the snapshot, how to reproduce the packages, and what still needs a launch check. |

## Building locally

From the repository root, use Python 3.11 or newer with the editor and matching templates installed.

```sh
python3 tools/package_release.py --web
```

Omit `--web` for the three desktop zips and the project-source zip. Set `GODOT` to the editor executable if it has another name or path. Add `--pack-only` to reuse exports already made with these presets. From `release/`, run `sha256sum -c SHA256SUMS.txt` to check the zips from that run.

Each desktop zip has an `UndertowFM/` folder with the app or executable, `游玩说明.txt`, and `licenses/`. On Windows and Linux, `UndertowFM.pck` sits beside the executable. The `Godot-source.zip` suffix identifies the editable project rebuilt from this tree. The Web zip has `index.html` at its root. Serve its contents together over HTTPS or localhost, with `application/wasm` for the `.wasm` file. Single-threaded export works without COOP/COEP headers. [Godot Web hosting documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html#serving-the-files)

## Save compatibility and remaining checks

The existing save code writes a temporary file, copies the previous valid save to `broadcast.cfg.bak`, then renames the temporary file. On Web, `globalize_path` resolves `user://` inside Godot's `/userfs` mount. Closing the written file marks the mount for IndexedDB synchronization on a later frame, so the copy and rename can use the existing code. Persistence depends on browser storage permissions. [Godot's directory copy](https://github.com/godotengine/godot/blob/4.7.2-stable/core/io/dir_access.cpp#L276-L282) and [Web filesystem implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/web/os_web.cpp)

Validation for the save-path note above was static. A later desktop-browser session against a local HTTP preview of the Web zip showed the title screen, workshop entry, visible arrow-key movement, and a 继续接力 / 修理铺 continue option after refresh. The tutorial stayed at 校频 1/6 (approaching the cyan marker did not advance it), J-to-punch was not confirmed, and audio was not tested. That record is in the README; it is not a full playthrough and not a confirmed root cause. Gameplay code was not changed to work around it. Windows and macOS launches, and a longer desktop playthrough, still have not been verified here. Gatekeeper may block the downloaded unsigned macOS app. [Godot macOS export documentation](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html#requirements)

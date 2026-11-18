# Undertow FM (逆潮电台)

> **This is a model-capability test artifact, not a finished product.**
> The project snapshot comes from a GPT-6.2 Astra capability test. It is not a mature, supported, or production-ready game, and it should not be treated as a commercial release.

**简体中文：** 这是 GPT-6.2 Astra 的模型能力测试产物，不是成熟的生产产品。完整说明见下方英文正文。原包内的中文游戏手册见 [README.zh.md](README.zh.md)。

---

## What this repository is

This tree is the Godot **source** from the archive `UndertowFM-1.0.0-Godot-source.zip` (version `1.0.0` in `project.godot`). It is a Chinese-language, single-player, pixel side-scrolling game project named 逆潮电台 · UNDERTOW FM.

The original zip is kept unchanged. SHA-256:

`05c5f9acd236c1cd93b02af20ae15e1531dd29d82463de5b6074efaf726b95a6`

The uploader provided that archive as one item from a GPT-6.2 Astra test series. The snapshot itself does **not** contain:

- the original prompt or conversation log
- a model variant or settings record (for example Ultra, temperature, or other decoder options)
- runtime, token, or cost figures
- a formal test report or pass/fail log

Those details are therefore not restated here.

### Model vs. human contribution

The files do not include a prompt log, generation transcript, or authorship map that would let a reader separate model output from later human edits. In-tree comments such as “hand-authored” in art or audio tool sources are wording that already exists in the snapshot; they are not an independently verified split between the model and a person. Treat the gameplay, art, audio, and original scripts as a test artifact unless a later note says otherwise.

If desktop packages, a web build, GitHub Actions, or compatibility patches are present in this repository, they are **follow-on packaging and engineering**. They must not be described as the unmodified original test output. See [Later packaging and compatibility changes](#later-packaging-and-compatibility-changes).

---

## Contents

| Path | Role |
| --- | --- |
| `project.godot` | Godot project settings; main scene `game/Main.tscn` |
| `export_presets.cfg` | Export presets (desktop, and a web preset if later packaging added one) |
| `README.zh.md` | Original in-tree Chinese game manual from the snapshot |
| `game/` | Game scripts (GDScript) and the main scene |
| `assets/` | Pixel art, icon, Fusion Pixel font, music, and sound effects |
| `licenses/` | Godot, engine third-party, and font license texts |
| `tools/` | Asset-generation and QA scripts; excluded from game exports |
| `release/` | Ignored build output (`.gdignore` only in the snapshot) |
| `.gitignore` | Ignores `.godot/`, `__pycache__/`, `.DS_Store`, and `release/` |

The snapshot had no `.git` history, no C# / GDExtension / `addons/` tree, and no prebuilt `.app`, `.exe`, `.pck`, or web export.

Approximate inventory from the unpacked snapshot: 16 GDScript files under `game/`, 75 actor PNGs, 46 world PNGs, 9 Ogg music tracks, 19 WAV effects, and one bundled font (`assets/fonts/FusionPixel.ttf`). The original Chinese manual also describes campaign structure, combat, and options; those design claims have not been independently played through or counted for this write-up.

---

## Running from source

This repository is **source**. The paths `UndertowFM.app`, `UndertowFM.exe`, and `UndertowFM.x86_64` mentioned in the original manual apply to a desktop distribution, not to the snapshot alone.

The bundled Chinese manual says to open this directory’s `project.godot` in **Godot 4.7.2** and run the main scene `game/Main.tscn`. That version was checked against the official Godot Engine releases: tag [`4.7.2-stable`](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) is a published stable release (2026-08-18). `project.godot` declares `config/features` as `"4.7"` and `"GL Compatibility"`. The logical viewport is 640×360, stretched with aspect kept; the window override is 1280×720. The renderer is Compatibility (`gl_compatibility`). Saves use Godot’s `user://broadcast.cfg`, with a backup named `broadcast.cfg.bak`. The project sets a custom user directory name `UndertowFM` (the original manual notes the default macOS location as `~/Library/Application Support/UndertowFM/`).

Keyboard and gamepad controls, difficulty names (故事 / 街机 / 暴潮), and menu labels are documented in [README.zh.md](README.zh.md) and `tools/pack/游玩说明.txt`. No on-screen touch controls were found in the game scripts.

---

## Desktop packages

In-tree `export_presets.cfg` originally defined three **desktop** export presets:

- macOS: universal binary, `release/UndertowFM.app`, codesign flag on, notarization off, bundle id `games.undertowfm.coastalradio`
- Windows Desktop: x86_64, `release/Windows/UndertowFM.exe`, `.pck` not embedded
- Linux: x86_64, `release/Linux/UndertowFM.x86_64`, `.pck` not embedded

All three export game resources, include `licenses/*.txt` and `licenses/fonts/*.txt`, and exclude `tools/*` and `release/*`.

`tools/package_release.py` is the snapshot packager. It is written to import the project with a `godot` CLI and official export templates, wrap each platform into a zip, rebuild a source zip, and write `release/SHA256SUMS.txt`. Windows and Linux zips must keep the executable and its sibling `.pck` together, plus `游玩说明.txt` and `licenses/`.

Those outputs are **portable zip distributions**, not Windows installers (MSI / Setup.exe) or macOS disk images (DMG / PKG). The source zip is not an installer. This repository does not include Apple or Microsoft signing credentials; macOS builds, if provided, should be treated as **unsigned**. Notarization was already off in the original preset. Do not expect Gatekeeper or SmartScreen to treat them as signed software.

Look at [GitHub Releases](https://github.com/Thweki/undertow-fm/releases) for any built packages. Until a build has been started and basic launch checks have passed, any Release should be treated as a **preview**, not a mature 1.0 product.

---

## Web build

The original snapshot had no Web / HTML5 preset. A browser build is plausible: the game is GDScript-only, already uses the Compatibility renderer required for Godot 4 web (WebGL 2.0), and is a 2D 640×360 project. Official Godot 4.7 documentation states that Forward+ and Mobile cannot be used for the stock web export, and that C# projects cannot be exported to the web in Godot 4.

A web port is follow-on work. Intended public path (once deployed): `https://page.thweki.com:8443/undertow-fm/` — an independent subpath of the existing site, not the site root. Desktop browsers are the first target; no touch UI was found. See the later-changes section if a web preset or compatibility patches were added after the snapshot.

---

## Licenses

This snapshot has **no top-level license file that declares terms for the game’s own code, story, or original assets.** None is invented here.

Third-party texts that *are* bundled, and should be kept with any distribution:

- `licenses/Godot.txt` — Godot Engine MIT license
- `licenses/Engine-Third-Party.txt` — engine third-party notices
- `licenses/fonts/Fusion-OFL.txt` — SIL Open Font License for Fusion Pixel Font (the font actually shipped under `assets/fonts/`)
- Additional OFL texts under `licenses/fonts/` for Ark, Cubic, and Galmuri; only `FusionPixel.ttf` is present in `assets/fonts/` in this snapshot

The bundled audio README (`tools/audio/README.md`) states that the soundtrack and effects were synthesized from this project’s sources and were not taken from third-party music, sample packs, or generative music services. That claim is recorded as it appears in the snapshot, not independently audited.

---

## In-tree QA tools

`tools/qa/` contains headless scripts such as `pilot.gd` (commented example: `godot --headless --fixed-fps 60 --audio-driver Dummy -s tools/qa/pilot.gd -- /tmp/fresh-run`) plus wiring, combat, audio, and packing checks. `tools/audio/check.py` documents a decode/loudness check for the shipped audio. Presence of these tools is not a substitute for a published test report.

---

## Later packaging and compatibility changes

This section will list follow-on packaging, CI, and any strictly necessary compatibility edits made after the original GPT-6.2 Astra snapshot. Gameplay, art, and audio from the snapshot are not being redesigned.

*(To be filled when packaging work lands.)*

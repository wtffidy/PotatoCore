# PotatoCore

**A configurable automation toolkit for Minecraft 1.20.1 / Forge 47.4.28.**

PotatoCore is a client-side utility mod focused on reusable click profiles and configurable macros.

## Target environment

- Minecraft: **1.20.1**
- Forge: **47.4.28**
- Java: **17**
- Project Infinity pack: **0.1** (manifest version **0.0.52.1** supplied during setup)

## Click automation

| Key | Action |
| --- | --- |
| F6 | Toggle left-click automation |
| F7 | Toggle right-click automation |
| F9 | Cycle right-click profile |
| O | Open PotatoCore menu |\n| F11 | Toggle Auto Fish |
| F8 | Open Macro Builder |
| F10 | Toggle the configured macro |

Left- and right-click automation have independent enable states and independent timing. They can run at the same time.

Right-click profiles:

- **Right Click**: repeated use input.
- **Pebbles**: holds sneak and repeats right-click.
- **Sieve**: repeats right-click only while the targeted block's registry path contains the word sieve, to avoid clicking unrelated blocks.

Every click profile has an independent interval configured in minutes, seconds, and milliseconds. Automation pauses while a screen is open or the game is paused. Sneak state is shared between Pebbles and macro actions so one feature does not release sneak while the other still needs it.

Minecraft processes player input on client ticks, so very small configured intervals do not guarantee the same number of server-side interactions per second.

## Macro Builder

The in-game Macro Builder edits a reusable action profile:

- Action: left click, right click, or sneak + right click.
- Optional exact main-hand item requirement.
- Optional health safety guard.
- Configurable stop threshold in hearts (one heart is two health points).
- Configurable action interval in milliseconds.
- Optional auto-resume once health recovers above the threshold.

The **Load Blood Magic Knife preset** selects right-click, requires the item currently held in the main hand, enables the health guard, sets the stop threshold to one heart, and enables auto-resume. Hold the Sacrificial Knife before loading the preset, or use **Use item in main hand** to capture its registry ID.

Macro activation is session-only and never silently turns itself on after restarting Minecraft. F10 toggles the macro after its settings are saved.

## Auto Fish\n\nAuto Fish casts a held fishing rod, watches the bobber for a bite, reels in the catch, and recasts after a configurable delay. The default recast delay is 1,500 ms and can be changed from the main PotatoCore menu. It supports a rod in either hand and automatically disables itself when no fishing rod is held. It pauses while a screen is open or the game is paused. Fishing bite detection uses the bobber's downward movement after its initial splash, so unusual server-side fishing behavior may require tuning.\n\n## Automatic updates

Automatic update checks are enabled by default and can be disabled in the client config at:

    config/potato_core-client.toml

At client startup, PotatoCore checks the latest stable GitHub Release. If a newer release is available, it downloads the attached JAR, verifies its archive signature and GitHub-provided SHA-256 digest when available, and stages the update. The updater launches a small OS-specific installer that waits for Minecraft to close, replaces only the currently loaded PotatoCore JAR, and leaves the new version ready for the next launch. No GitHub token is stored in the mod.

The updater only replaces the JAR when PotatoCore is installed directly in the instance's `mods` folder. Development runs and unusual launcher layouts are detected and skipped rather than modifying unrelated files.

## Releases and builds

Every successful push to `main` builds a versioned JAR and publishes it as a stable GitHub Release. For the current 0.1 line, the patch version increments with each workflow run. A pushed `vX.Y.Z` tag publishes that exact version. Pull requests are build-checked but do not publish releases.

Release downloads are available from:

https://github.com/wtffidy/PotatoCore/releases/latest

The published JAR name is always versioned, for example `PotatoCore-0.1.1.jar`. The workflow does not publish commit-hash-named JAR artifacts.

## Build locally

Install a Java 17 JDK and Gradle 8.1.1, then run:

    gradle -PmodVersion=0.1.1 build --no-daemon

The compiled mod will be written to `build/libs/`.

## Integration status

Pebbles and Sieve currently provide client-input profiles. Sieve profile target detection uses the block registry path and looks for the word sieve; unusual block IDs may need an explicit compatibility mapping. A client-side click macro cannot override server-side fake-player or automated-sieve restrictions. It sends the local player's normal use input rather than creating a fake player.

The macro action/condition settings are the base for expanding into a multi-step visual macro editor.

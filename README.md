# PotatoCore

**A configurable client-side automation and quality-of-life toolkit for Minecraft 1.20.1 / Forge 47.4.28.**

Target environment: Minecraft **1.20.1**, Forge **47.4.28**, Java **17**. The current Project Infinity target is pack version **0.1**.

## Controls

All PotatoCore keybindings are configurable through **Options → Controls → Key Binds**. Search for **PotatoCore**. Bindings are grouped into Automation, Interface, Movement, View, and Utilities categories.

| Default | Action |
| --- | --- |
| F6 | Toggle left-click automation |
| F7 | Toggle right-click automation |
| F8 | Open PotatoCore Macro tab |
| F9 | Cycle right-click profile |
| F10 | Toggle configured macro |
| F12 | Toggle Auto Fish |
| O | Open PotatoCore menu |
| V | Toggle Sprint |
| Hold C | Smooth zoom |
| Home | Toggle status HUD |

## Click automation

Left- and right-click automation have independent enable states and independent timing. They can run at the same time.

Right-click profiles:
- **Right Click**: repeats use input.
- **Pebbles**: holds sneak and repeats right-click.
- **Sieve**: repeats right-click only while the targeted block registry path contains `sieve`.

Each click profile has an independent interval in minutes, seconds, and milliseconds. Automation pauses while a screen is open or the game is paused. Sneak state is shared between Pebbles and macro actions.

Minecraft processes player input on client ticks, so very small configured intervals do not guarantee the same number of server-side interactions per second.

## Macro Workshop

The in-game Macro tab edits a reusable action profile:
- Left click, right click, or sneak + right click.
- Optional exact main-hand item requirement.
- Optional health safety guard and stop threshold.
- Configurable action interval.
- Optional auto-resume after healing.

The **Blood Magic Knife preset** selects right-click, requires the currently held item, enables the health guard, sets the stop threshold to one heart, and enables auto-resume. Hold the Sacrificial Knife before loading the preset, or capture your held item in the tab.

Macro activation is session-only and never silently turns itself on after restarting Minecraft.

## Fishing

Auto Fish casts a held fishing rod, watches the bobber for a bite, reels in, then recasts after a configurable delay. It supports a rod in either hand and stops if no fishing rod is held. It pauses while a screen is open or the game is paused.

Bite detection currently uses the bobber's downward movement after its initial splash. Server-side fishing changes or unusual bobber behavior may require tuning.

## Quality of life

The translucent PotatoCore panel leaves the Minecraft world visible and groups its controls into Clicker, Macros, Fishing, and Utilities tabs.

- **Toggle Sprint**: holds the normal sprint input until toggled off. Vanilla movement restrictions still apply.
- **Smooth Zoom**: hold the assigned key for a smooth 4x zoom effect. Other FOV modifiers remain in effect.
- **Status HUD**: optional coordinates, dimension, and active automation display.
- **Durability alerts**: warns when a held damageable item reaches the configured remaining-durability percentage.
- **Inventory alerts**: warns when all main inventory storage slots are occupied.
- **Copy coordinates**: copies block coordinates and dimension to the clipboard.

## Automatic updates

Automatic update checks are enabled by default and can be disabled in `config/potato_core-client.toml`.

At client startup, PotatoCore checks the latest stable GitHub Release. If a newer release is available, it downloads the attached JAR, verifies the GitHub-provided SHA-256 digest when available, and stages the update. The updater waits for Minecraft to close before replacing the currently loaded PotatoCore JAR.

The updater only replaces the JAR when PotatoCore is installed directly in the instance's `mods` folder. Development runs and unusual launcher layouts are skipped.

## Builds and releases

Every successful push to `main` builds a versioned JAR and publishes it as a GitHub Release. For the current 0.1 line, the patch version increments with each workflow run. A pushed `vX.Y.Z` tag publishes that exact version. Pull requests are build-checked but do not publish releases.

Downloads: https://github.com/wtffidy/PotatoCore/releases/latest

For a local build, install Java 17 and Gradle 8.1.1, then run:

    gradle -PmodVersion=0.1.1 build --no-daemon

# PotatoCore

**A configurable client-side automation and quality-of-life toolkit for Minecraft 1.20.1 / Forge 47.4.28.**

Target environment: Minecraft **1.20.1**, Forge **47.4.28**, Java **17**. The current Project Infinity target is pack version **0.1**.

## Controls

All PotatoCore keybindings are configurable through **Options → Controls → Key Binds**. Search for **PotatoCore**. Bindings are grouped into Automation, Interface, Movement, View, and Utilities categories, with descriptive action names.

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
| B | Toggle Sneak |
| Hold C | Smooth zoom |
| Home | Toggle status HUD |
| K | Copy coordinates and dimension |

## Click automation

Left- and right-click automation have independent enable states and independent timing. They can run at the same time.

Right-click profiles:
- **Right Click**: repeats use input.
- **Pebbles**: holds sneak and repeats right-click.
- **Sieve**: repeats right-click only while the targeted block registry path contains `sieve`.

Each click profile has an independent interval in minutes, seconds, and milliseconds. Automation pauses while a screen is open or the game is paused. Sneak state is shared between Toggle Sneak, Pebbles, and macro actions.

## Macro Workshop

The in-game Macro tab edits a reusable action profile with click type, held-item requirement, health guard, stop threshold, interval, and optional auto-resume. The Blood Magic Knife preset selects right-click, requires the currently held item, enables the health guard, stops at one heart, and enables auto-resume. Hold the Sacrificial Knife before loading the preset.

## Fishing

Auto Fish casts a held fishing rod, watches the bobber for a bite, reels in, then recasts after a configurable delay. It supports a rod in either hand. Bite detection uses bobber movement and may need tuning for unusual server-side fishing behavior.

## Quality of life

The translucent tabbed PotatoCore panel leaves the Minecraft world visible behind it.

- **Toggle Sprint**: toggles normal sprint input.
- **Toggle Sneak**: toggles normal sneak input and shares sneak state safely with Pebbles and macros.
- **Smooth Zoom**: hold the assigned key for a smooth 4x zoom effect.
- **Status HUD**: optional coordinates, dimension, and active automation display.
- **Durability alerts**: warns when a held damageable item reaches the configured remaining-durability percentage.
- **Inventory alerts**: warns when all main inventory storage slots are occupied.
- **Copy coordinates**: copies block coordinates and dimension to the clipboard.

## Local build and CurseForge install

Run **build-and-install.bat** from the repository folder. It builds the mod, locates the CurseForge Minecraft Instances folder, and copies the JAR into:

    CurseForge\minecraft\Instances\Project Infinity 0.1\mods

It checks common CurseForge locations under your Windows profile and common drive roots. If your instances folder is elsewhere, set `CURSEFORGE_INSTANCES_DIR` to the full path of the `Instances` folder before running the script. The Gradle task can also be run directly with `gradle build installToCurseForge --no-daemon`.

The script does not install CurseForge. It stops with a clear error if the exact Project Infinity 0.1 instance cannot be found.

## Automatic updates

Automatic update checks are enabled by default and can be disabled in `config/potato_core-client.toml`. At client startup, PotatoCore checks the latest stable GitHub Release, downloads a newer JAR, verifies the SHA-256 digest when available, and stages the update for replacement after Minecraft closes.

## Builds and releases

Every successful push to `main` builds a versioned JAR and publishes it as a GitHub Release. Pull requests are build-checked but do not publish releases.

Downloads: https://github.com/wtffidy/PotatoCore/releases/latest

## ComputerCraft automation network

PotatoCore includes three separate CC:Tweaked deployment roles, installed with FixAdvancedComputers.Py:

| Hotkey | Role | Install target |
| --- | --- | --- |
| Ctrl+P | Mana Pools | Each Mana Pool transmitter computer |
| Ctrl+M | Monitor | Dedicated 6x6 production monitor computer |
| Ctrl+B | Machines | Each machine-side Block Reader computer |

The Mana Pool transmitter feeds the existing 3x3 Mana Core receiver. The expandable production monitor receives telemetry from the separate machine transmitters over Ender Modems. Machine computers do not need a monitor, and the monitor computer does not need direct Block Reader access.

Guides:
- [Mana Pool network](computercraft/mana-network/README.md)
- [Expandable production monitor](computercraft/monitor/README.md)
- [Machine Block Reader transmitters](computercraft/machines/README.md)

All three installers download their Lua program and matching startup.lua launcher. Each role autostarts after its computer reboots.

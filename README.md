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
| O | Open PotatoCore menu |
| F8 | Open Macro Builder |
| F10 | Toggle the configured macro |

Left- and right-click automation have independent enable states and independent timing. They can run at the same time.

Right-click profiles:

- **Right Click**: repeated use input.
- **Pebbles**: holds sneak and repeats right-click.
- **Sieve**: repeats right-click without sneak.

Every click profile has an independent interval configured in minutes, seconds, and milliseconds. Automation pauses while a screen is open or the game is paused. Sneak state is shared between Pebbles and macro actions so one feature does not release sneak while the other still needs it.

## Macro Builder

The in-game Macro Builder edits a reusable action profile:

- Action: left click, right click, or sneak + right click.
- Optional exact main-hand item requirement.
- Optional health safety guard.
- Configurable stop threshold in hearts (one heart = two health points).
- Configurable action interval in milliseconds.
- Optional auto-resume once health recovers above the threshold.

The **Load Blood Magic Knife preset** selects right-click, requires the item currently held in the main hand, enables the health guard, sets the stop threshold to one heart, and enables auto-resume. Hold the Sacrificial Knife before loading the preset, or use **Use item in main hand** to capture its registry ID.

Macro activation is session-only and never silently turns itself on after restarting Minecraft. F10 toggles the macro after its settings are saved.

## Build

Install a Java 17 JDK and Gradle 8.1.1, then run:

    gradle build --no-daemon

The compiled mod will be written to build/libs/. GitHub Actions runs the same build and uploads the JAR as a workflow artifact.

## Integration status

Pebbles and Sieve currently provide repeat-input profiles. Mod-specific Ex Deorum / Just Dire Things automation and fake-player integrations need testing against the exact installed versions. A client-side click macro cannot override server-side fake-player or automated-sieve restrictions; configure the relevant mod/server settings where required.

The macro action/condition settings are the base for expanding into a multi-step visual macro editor.

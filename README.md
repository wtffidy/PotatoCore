# PotatoCore

**A configurable automation toolkit for Minecraft 1.20.1 / Forge 47.4.28.**

PotatoCore is a client-side utility mod focused on reusable automation profiles and an in-game macro builder.

## Target environment

- Minecraft: **1.20.1**
- Forge: **47.4.28**
- Java: **17**
- Project Infinity pack: **0.1** (manifest version **0.0.52.1** supplied during setup)

## Current features

### Click automation

| Key | Action |
| --- | --- |
| F6 | Toggle click automation |
| F7 | Cycle click mode |
| O | Open PotatoCore menu |
| F8 | Open Macro Builder |

Modes:

- **Left Click**: repeated attack input.
- **Right Click**: repeated use input.
- **Pebbles**: holds sneak while repeating right-click.
- **Sieve**: repeated right-click.

Each mode has its own interval, configured with minutes, seconds, and milliseconds. The clicker pauses while a screen is open or the game is paused. The sneak key is released when the clicker stops or leaves Pebbles mode.

### Macro Builder: Blood Magic Sacrificial Knife

The initial macro profile supports:

- Enable/disable toggle.
- Required main-hand item registry ID.
- Button to read the registry ID from the item currently held.
- Health stop threshold, configured in hearts (one heart is two health points).
- Right-click interval in milliseconds.
- Optional automatic resume after health recovers above the threshold.

The macro checks the player's health **before every click**. At or below the configured threshold it stops issuing right-clicks. It only runs while the configured item is in the main hand.

The registry ID is intentionally not hardcoded until it is verified against the installed Project Infinity mod list. Hold the Sacrificial Knife and press **Use item in main hand** in the Macro Builder to populate the correct ID.

## Build

Install a Java 17 JDK and Gradle 8.1.1, then run:

    gradle build --no-daemon

The compiled mod will be written to build/libs/. GitHub Actions runs the same build and uploads the resulting JAR as a workflow artifact.

## Integration notes

The current Pebbles and Sieve modes provide the input behavior only. Specific Ex Deorum / Just Dire Things block and fake-player integrations still need testing against the installed mod versions. They are not claimed to be complete yet.

The macro framework is being kept modular so more preset types and user-defined action/condition steps can be added without rewriting the clicker engine.

package com.tato.potatocore.client;

import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.util.Util;

public final class ClickerController {
    private static boolean enabled;
    private static boolean controllingSneak;
    private static ClickMode mode = ClickMode.LEFT;
    private static long nextClickAt;

    private ClickerController() {
    }

    public static void toggle() {
        enabled = !enabled;
        nextClickAt = 0L;
        if (!enabled) {
            releaseSneak();
        }
    }

    public static void cycleMode() {
        mode = mode.next();
        nextClickAt = 0L;
        if (!mode.usesSneak()) {
            releaseSneak();
        }
    }

    public static void tick() {
        if (!enabled) {
            releaseSneak();
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null || minecraft.screen != null || minecraft.isPaused()) {
            releaseSneak();
            return;
        }

        if (mode.usesSneak()) {
            minecraft.options.keyShift.setDown(true);
            controllingSneak = true;
        } else {
            releaseSneak();
        }

        long now = Util.getMillis();
        if (now < nextClickAt) {
            return;
        }

        KeyMapping mapping = mode.usesLeftClick() ? minecraft.options.keyAttack : minecraft.options.keyUse;
        KeyMapping.click(mapping.getKey());
        nextClickAt = now + getIntervalMillis(mode);
    }

    private static void releaseSneak() {
        if (!controllingSneak) {
            return;
        }

        Minecraft.getInstance().options.keyShift.setDown(false);
        controllingSneak = false;
    }

    public static boolean isEnabled() {
        return enabled;
    }

    public static ClickMode getMode() {
        return mode;
    }

    public static long getIntervalMillis(ClickMode clickMode) {
        int minutes;
        int seconds;
        int milliseconds;

        switch (clickMode) {
            case LEFT -> {
                minutes = PotatoCoreConfig.LEFT_MINUTES.get();
                seconds = PotatoCoreConfig.LEFT_SECONDS.get();
                milliseconds = PotatoCoreConfig.LEFT_MILLISECONDS.get();
            }
            case RIGHT -> {
                minutes = PotatoCoreConfig.RIGHT_MINUTES.get();
                seconds = PotatoCoreConfig.RIGHT_SECONDS.get();
                milliseconds = PotatoCoreConfig.RIGHT_MILLISECONDS.get();
            }
            case PEBBLES -> {
                minutes = PotatoCoreConfig.PEBBLES_MINUTES.get();
                seconds = PotatoCoreConfig.PEBBLES_SECONDS.get();
                milliseconds = PotatoCoreConfig.PEBBLES_MILLISECONDS.get();
            }
            case SIEVE -> {
                minutes = PotatoCoreConfig.SIEVE_MINUTES.get();
                seconds = PotatoCoreConfig.SIEVE_SECONDS.get();
                milliseconds = PotatoCoreConfig.SIEVE_MILLISECONDS.get();
            }
            default -> throw new IllegalStateException("Unsupported click mode: " + clickMode);
        }

        long interval = (minutes * 60_000L) + (seconds * 1_000L) + milliseconds;
        return Math.max(1L, interval);
    }
}

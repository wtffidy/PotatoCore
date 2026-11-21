package com.tato.potatocore.client;

import net.minecraft.client.Minecraft;

public final class ToggleSneakController {
    private static boolean enabled;

    private ToggleSneakController() {
    }

    public static void toggle() {
        enabled = !enabled;
        SneakKeyController.setToggleSneaking(enabled);
    }

    public static boolean isEnabled() {
        return enabled;
    }

    public static void tick() {
        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null || minecraft.screen != null || minecraft.isPaused()) {
            SneakKeyController.setToggleSneaking(false);
            return;
        }
        SneakKeyController.setToggleSneaking(enabled);
    }
}

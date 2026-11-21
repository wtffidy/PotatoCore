package com.tato.potatocore.client;

import net.minecraft.client.Minecraft;

public final class SneakKeyController {
    private static boolean clickerRequestsSneak;
    private static boolean macroRequestsSneak;
    private static boolean controllingSneak;
    private static boolean sneakWasDown;

    private SneakKeyController() {
    }

    public static void setClickerSneaking(boolean enabled) {
        clickerRequestsSneak = enabled;
        updateSneakState();
    }

    public static void setMacroSneaking(boolean enabled) {
        macroRequestsSneak = enabled;
        updateSneakState();
    }

    public static void releaseAll() {
        clickerRequestsSneak = false;
        macroRequestsSneak = false;
        updateSneakState();
    }

    private static void updateSneakState() {
        Minecraft minecraft = Minecraft.getInstance();
        boolean shouldSneak = clickerRequestsSneak || macroRequestsSneak;

        if (shouldSneak && !controllingSneak) {
            sneakWasDown = minecraft.options.keyShift.isDown();
            minecraft.options.keyShift.setDown(true);
            controllingSneak = true;
        } else if (!shouldSneak && controllingSneak) {
            minecraft.options.keyShift.setDown(sneakWasDown);
            controllingSneak = false;
        }
    }
}

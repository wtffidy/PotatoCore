package com.tato.potatocore.client.macro;

import com.tato.potatocore.client.SneakKeyController;
import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.Util;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.resources.ResourceLocation;
import net.minecraftforge.registries.ForgeRegistries;

public final class MacroController {
    private static boolean enabled;
    private static boolean pausedForHealth;
    private static long nextActionAt;

    private MacroController() {
    }

    public static void toggle() {
        setEnabled(!enabled);
    }

    public static void setEnabled(boolean value) {
        enabled = value;
        pausedForHealth = false;
        nextActionAt = 0L;
        if (!enabled) {
            SneakKeyController.setMacroSneaking(false);
        }
    }

    public static boolean isEnabled() {
        return enabled;
    }

    public static void tick() {
        if (!enabled) {
            SneakKeyController.setMacroSneaking(false);
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null || !minecraft.player.isAlive()) {
            setEnabled(false);
            return;
        }

        if (minecraft.screen != null || minecraft.isPaused()) {
            SneakKeyController.setMacroSneaking(false);
            return;
        }

        if (PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.get() && !isRequiredItemHeld(minecraft)) {
            SneakKeyController.setMacroSneaking(false);
            return;
        }

        if (PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.get()) {
            float stopHealth = PotatoCoreConfig.MACRO_STOP_HEARTS.get() * 2.0F;
            if (minecraft.player.getHealth() <= stopHealth) {
                pausedForHealth = true;
                SneakKeyController.setMacroSneaking(false);
                return;
            }

            if (pausedForHealth && !PotatoCoreConfig.MACRO_AUTO_RESUME.get()) {
                SneakKeyController.setMacroSneaking(false);
                return;
            }
        } else {
            pausedForHealth = false;
        }

        if (pausedForHealth) {
            pausedForHealth = false;
            nextActionAt = 0L;
        }

        MacroAction action = MacroAction.fromConfig(PotatoCoreConfig.MACRO_ACTION.get());
        SneakKeyController.setMacroSneaking(action == MacroAction.SNEAK_RIGHT_CLICK);

        long now = Util.getMillis();
        if (now < nextActionAt) {
            return;
        }

        if (action == MacroAction.LEFT_CLICK) {
            KeyMapping.click(minecraft.options.keyAttack.getKey());
        } else {
            KeyMapping.click(minecraft.options.keyUse.getKey());
        }

        nextActionAt = now + Math.max(1, PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.get());
    }

    private static boolean isRequiredItemHeld(Minecraft minecraft) {
        String itemId = PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.get().trim();
        if (itemId.isEmpty()) {
            return false;
        }

        ResourceLocation configuredItemId = ResourceLocation.tryParse(itemId);
        if (configuredItemId == null) {
            return false;
        }

        ResourceLocation heldItemId = ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem());
        return configuredItemId.equals(heldItemId);
    }

    public static String getStatus() {
        if (!enabled) {
            return "Disabled";
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null) {
            return "Waiting for player";
        }

        if (PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.get() && !isRequiredItemHeld(minecraft)) {
            return "Waiting for required held item";
        }

        if (PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.get()
                && minecraft.player.getHealth() <= PotatoCoreConfig.MACRO_STOP_HEARTS.get() * 2.0F) {
            return "Paused: health threshold reached";
        }

        if (pausedForHealth) {
            return "Paused: auto-resume disabled";
        }

        return "Active";
    }
}

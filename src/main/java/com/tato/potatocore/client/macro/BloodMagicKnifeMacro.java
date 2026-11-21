package com.tato.potatocore.client.macro;

import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.Util;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.resources.ResourceLocation;
import net.minecraftforge.registries.ForgeRegistries;

public final class BloodMagicKnifeMacro {
    private static long nextClickAt;
    private static boolean enabled;
    private static boolean pausedForHealth;

    private BloodMagicKnifeMacro() {
    }

    public static void setEnabled(boolean value) {
        enabled = value;
        nextClickAt = 0L;
        pausedForHealth = false;
    }

    public static boolean isEnabled() {
        return enabled;
    }

    public static void tick() {
        if (!enabled) {
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null) {
            setEnabled(false);
            return;
        }

        if (minecraft.screen != null || minecraft.isPaused()) {
            return;
        }

        String itemId = PotatoCoreConfig.BLOOD_MAGIC_ITEM_ID.get().trim();
        if (itemId.isEmpty()) {
            return;
        }

        ResourceLocation configuredItemId = ResourceLocation.tryParse(itemId);
        if (configuredItemId == null) {
            return;
        }

        ResourceLocation heldItemId = ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem());
        if (!configuredItemId.equals(heldItemId)) {
            return;
        }

        float stopHealth = PotatoCoreConfig.BLOOD_MAGIC_STOP_HEARTS.get() * 2.0F;
        if (minecraft.player.getHealth() <= stopHealth) {
            pausedForHealth = true;
            return;
        }

        if (pausedForHealth && !PotatoCoreConfig.BLOOD_MAGIC_AUTO_RESUME.get()) {
            return;
        }

        if (pausedForHealth) {
            pausedForHealth = false;
            nextClickAt = 0L;
        }

        long now = Util.getMillis();
        if (now < nextClickAt) {
            return;
        }

        KeyMapping.click(minecraft.options.keyUse.getKey());
        nextClickAt = now + PotatoCoreConfig.BLOOD_MAGIC_INTERVAL_MILLISECONDS.get();
    }

    public static String getStatus() {
        if (!enabled) {
            return "Disabled";
        }

        String itemId = PotatoCoreConfig.BLOOD_MAGIC_ITEM_ID.get().trim();
        if (itemId.isEmpty()) {
            return "Set the required held item";
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null) {
            return "Waiting for player";
        }

        ResourceLocation configuredItemId = ResourceLocation.tryParse(itemId);
        ResourceLocation heldItemId = ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem());
        if (configuredItemId == null || !configuredItemId.equals(heldItemId)) {
            return "Waiting for configured item";
        }

        return pausedForHealth ? "Paused: health threshold reached" : "Active";
    }
}

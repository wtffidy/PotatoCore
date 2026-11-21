package com.tato.potatocore.client.macro;

import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.util.Util;
import net.minecraftforge.registries.ForgeRegistries;

public final class BloodMagicKnifeMacro {
    private static long nextClickAt;
    private static boolean pausedForHealth;

    private BloodMagicKnifeMacro() {
    }

    public static void tick() {
        if (!PotatoCoreConfig.BLOOD_MAGIC_ENABLED.get()) {
            resetRuntimeState();
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null || minecraft.screen != null || minecraft.isPaused()) {
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

    private static void resetRuntimeState() {
        nextClickAt = 0L;
        pausedForHealth = false;
    }

    public static boolean isPausedForHealth() {
        return pausedForHealth;
    }

    public static String getStatus() {
        if (!PotatoCoreConfig.BLOOD_MAGIC_ENABLED.get()) {
            return "Disabled";
        }
        if (PotatoCoreConfig.BLOOD_MAGIC_ITEM_ID.get().isBlank()) {
            return "Set the required held item";
        }
        return pausedForHealth ? "Paused: health threshold reached" : "Armed";
    }
}

package com.tato.potatocore.client;

import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.Util;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.world.entity.projectile.FishingHook;
import net.minecraft.world.item.Items;

public final class AutoFishController {
    private static boolean enabled;
    private static boolean reelingIn;
    private static boolean waitingToRecast;
    private static boolean waitingForBobber;
    private static int trackedBobberId = -1;
    private static long bobberSeenAt;
    private static long nextActionAt;

    private AutoFishController() {
    }

    public static void toggle() {
        setEnabled(!enabled);
    }

    public static void setEnabled(boolean value) {
        enabled = value;
        reelingIn = false;
        waitingToRecast = false;
        waitingForBobber = false;
        trackedBobberId = -1;
        bobberSeenAt = 0L;
        nextActionAt = 0L;
    }

    public static boolean isEnabled() {
        return enabled;
    }

    public static void tick() {
        if (!enabled) {
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null || minecraft.screen != null || minecraft.isPaused()) {
            return;
        }

        if (!isHoldingFishingRod(minecraft)) {
            setEnabled(false);
            minecraft.player.displayClientMessage(
                    net.minecraft.network.chat.Component.literal("PotatoCore Auto Fish stopped: no fishing rod held."),
                    true);
            return;
        }

        long now = Util.getMillis();
        FishingHook bobber = minecraft.player.fishing;

        if (bobber != null && bobber.isAlive()) {
            waitingForBobber = false;

            if (reelingIn) {
                return;
            }

            if (trackedBobberId != bobber.getId()) {
                trackedBobberId = bobber.getId();
                bobberSeenAt = now;
            }

            // Ignore the bobber's initial splash and wait for its settled fishing state.
            if (now - bobberSeenAt >= 1500L && bobber.isInWater()
                    && bobber.getDeltaMovement().y < -0.04D) {
                KeyMapping.click(minecraft.options.keyUse.getKey());
                reelingIn = true;
                nextActionAt = now + PotatoCoreConfig.AUTO_FISH_RECAST_DELAY_MS.get();
            }
            return;
        }

        trackedBobberId = -1;
        bobberSeenAt = 0L;

        if (reelingIn) {
            reelingIn = false;
            waitingToRecast = true;
        }

        if (waitingToRecast) {
            if (now < nextActionAt) {
                return;
            }

            KeyMapping.click(minecraft.options.keyUse.getKey());
            waitingToRecast = false;
            waitingForBobber = true;
            nextActionAt = now + 3000L;
            return;
        }

        if (!waitingForBobber || now >= nextActionAt) {
            KeyMapping.click(minecraft.options.keyUse.getKey());
            waitingForBobber = true;
            nextActionAt = now + 3000L;
        }
    }

    private static boolean isHoldingFishingRod(Minecraft minecraft) {
        return minecraft.player.getMainHandItem().is(Items.FISHING_ROD)
                || minecraft.player.getOffhandItem().is(Items.FISHING_ROD);
    }

    public static String getStatus() {
        if (!enabled) {
            return "Disabled";
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null) {
            return "Waiting for player";
        }

        if (!isHoldingFishingRod(minecraft)) {
            return "Waiting for fishing rod";
        }

        if (reelingIn) {
            return "Reeling in catch";
        }

        if (waitingToRecast) {
            return "Waiting to recast";
        }

        return minecraft.player.fishing == null ? "Casting line" : "Waiting for a bite";
    }
}

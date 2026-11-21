package com.tato.potatocore.client;

import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.Util;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraftforge.registries.ForgeRegistries;

public final class ClickerController {
    private static boolean leftEnabled;
    private static boolean rightEnabled;
    private static ClickMode rightMode = ClickMode.RIGHT;
    private static long nextLeftClickAt;
    private static long nextRightClickAt;

    private ClickerController() {
    }

    public static void toggleLeft() {
        leftEnabled = !leftEnabled;
        nextLeftClickAt = 0L;
    }

    public static void toggleRight() {
        rightEnabled = !rightEnabled;
        nextRightClickAt = 0L;
        updateSneakState();
    }

    public static void cycleRightMode() {
        rightMode = rightMode.nextRightMode();
        nextRightClickAt = 0L;
        updateSneakState();
    }

    public static void tick() {
        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null || minecraft.screen != null || minecraft.isPaused()) {
            SneakKeyController.setClickerSneaking(false);
            return;
        }

        updateSneakState();

        long now = Util.getMillis();
        if (leftEnabled && now >= nextLeftClickAt) {
            KeyMapping.click(minecraft.options.keyAttack.getKey());
            nextLeftClickAt = now + getIntervalMillis(ClickMode.LEFT);
        }

        if (rightEnabled && now >= nextRightClickAt && canRunRightProfile(minecraft)) {
            KeyMapping.click(minecraft.options.keyUse.getKey());
            nextRightClickAt = now + getIntervalMillis(rightMode);
        }
    }

    private static boolean canRunRightProfile(Minecraft minecraft) {
        if (rightMode != ClickMode.SIEVE) {
            return true;
        }

        if (!(minecraft.hitResult instanceof BlockHitResult blockHit)) {
            return false;
        }

        ResourceLocation blockId = ForgeRegistries.BLOCKS.getKey(
                minecraft.level.getBlockState(blockHit.getBlockPos()).getBlock());
        return blockId != null && blockId.getPath().contains("sieve");
    }

    private static void updateSneakState() {
        SneakKeyController.setClickerSneaking(rightEnabled && rightMode.usesSneak());
    }

    public static boolean isLeftEnabled() {
        return leftEnabled;
    }

    public static boolean isRightEnabled() {
        return rightEnabled;
    }

    public static ClickMode getRightMode() {
        return rightMode;
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

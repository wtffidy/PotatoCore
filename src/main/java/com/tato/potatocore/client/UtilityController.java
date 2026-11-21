package com.tato.potatocore.client;

import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.client.Minecraft;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraft.world.item.ItemStack;

public final class UtilityController {
    private static boolean mainHandWasLow;
    private static boolean offHandWasLow;
    private static boolean inventoryWasFull;

    private UtilityController() {
    }

    public static void tick() {
        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null) {
            mainHandWasLow = false;
            offHandWasLow = false;
            inventoryWasFull = false;
            return;
        }

        if (PotatoCoreConfig.DURABILITY_WARNING_ENABLED.get()) {
            ItemStack mainHand = minecraft.player.getMainHandItem();
            ItemStack offHand = minecraft.player.getOffhandItem();
            boolean mainHandLow = isLowDurability(mainHand);
            boolean offHandLow = isLowDurability(offHand);

            if ((mainHandLow && !mainHandWasLow) || (offHandLow && !offHandWasLow)) {
                minecraft.player.displayClientMessage(
                        Component.literal("PotatoCore: A held item is running low on durability."), true);
            }

            mainHandWasLow = mainHandLow;
            offHandWasLow = offHandLow;
        } else {
            mainHandWasLow = false;
            offHandWasLow = false;
        }

        if (PotatoCoreConfig.INVENTORY_FULL_WARNING_ENABLED.get()) {
            boolean inventoryFull = hasNoEmptyStorageSlots(minecraft);
            if (inventoryFull && !inventoryWasFull) {
                minecraft.player.displayClientMessage(
                        Component.literal("PotatoCore: Your inventory has no empty storage slots."), true);
            }
            inventoryWasFull = inventoryFull;
        } else {
            inventoryWasFull = false;
        }
    }

    private static boolean isLowDurability(ItemStack stack) {
        if (stack.isEmpty() || !stack.isDamageableItem() || stack.getMaxDamage() <= 0) {
            return false;
        }

        int remainingDurability = stack.getMaxDamage() - stack.getDamageValue();
        int remainingPercent = remainingDurability * 100 / stack.getMaxDamage();
        return remainingPercent <= PotatoCoreConfig.DURABILITY_WARNING_PERCENT.get();
    }

    private static boolean hasNoEmptyStorageSlots(Minecraft minecraft) {
        for (ItemStack stack : minecraft.player.getInventory().items) {
            if (stack.isEmpty()) {
                return false;
            }
        }
        return true;
    }

    public static void copyCoordinates() {
        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null) {
            return;
        }

        BlockPos position = minecraft.player.blockPosition();
        String coordinates = position.getX() + " " + position.getY() + " " + position.getZ()
                + " (" + minecraft.level.dimension().location() + ")";
        minecraft.keyboardHandler.setClipboard(coordinates);
        minecraft.player.displayClientMessage(Component.literal("PotatoCore: Coordinates copied to clipboard."), true);
    }
}

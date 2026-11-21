package com.tato.potatocore.client;

import com.tato.potatocore.PotatoCore;
import com.tato.potatocore.client.gui.PotatoCoreScreen;
import com.tato.potatocore.client.macro.MacroController;
import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.core.BlockPos;
import net.minecraft.network.chat.Component;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.client.event.ComputeFovModifierEvent;
import net.minecraftforge.client.event.RenderGuiEvent;
import net.minecraftforge.event.TickEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

import java.util.ArrayList;
import java.util.List;

@Mod.EventBusSubscriber(modid = PotatoCore.MOD_ID, value = Dist.CLIENT)
public final class ClientForgeEvents {
    private ClientForgeEvents() {
    }

    @SubscribeEvent
    public static void onClientTick(TickEvent.ClientTickEvent event) {
        if (event.phase != TickEvent.Phase.END) {
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player != null) {
            String updateNotice = ClientUpdateChecker.consumeNotice();
            if (updateNotice != null) {
                minecraft.player.displayClientMessage(Component.literal(updateNotice), false);
            }
        }

        while (ClientKeyMappings.TOGGLE_LEFT_CLICK.consumeClick()) {
            ClickerController.toggleLeft();
        }

        while (ClientKeyMappings.TOGGLE_RIGHT_CLICK.consumeClick()) {
            ClickerController.toggleRight();
        }

        while (ClientKeyMappings.NEXT_RIGHT_MODE.consumeClick()) {
            ClickerController.cycleRightMode();
        }

        while (ClientKeyMappings.TOGGLE_MACRO.consumeClick()) {
            MacroController.toggle();
        }

        while (ClientKeyMappings.TOGGLE_AUTO_FISH.consumeClick()) {
            AutoFishController.toggle();
        }

        while (ClientKeyMappings.OPEN_MAIN_MENU.consumeClick()) {
            minecraft.setScreen(new PotatoCoreScreen());
        }

        while (ClientKeyMappings.OPEN_MACRO_BUILDER.consumeClick()) {
            minecraft.setScreen(new PotatoCoreScreen(PotatoCoreScreen.Tab.MACROS));
        }

        while (ClientKeyMappings.TOGGLE_SPRINT.consumeClick()) {
            ToggleSprintController.toggle();
        }

        while (ClientKeyMappings.TOGGLE_STATUS_HUD.consumeClick()) {
            boolean showHud = !PotatoCoreConfig.SHOW_STATUS_HUD.get();
            PotatoCoreConfig.SHOW_STATUS_HUD.set(showHud);
            PotatoCoreConfig.SPEC.save();
            if (minecraft.player != null) {
                minecraft.player.displayClientMessage(
                        Component.literal("PotatoCore Status HUD: " + (showHud ? "ON" : "OFF")), true);
            }
        }

        ClickerController.tick();
        MacroController.tick();
        AutoFishController.tick();
        ToggleSprintController.tick();
        UtilityController.tick();
    }

    @SubscribeEvent
    public static void onComputeFov(ComputeFovModifierEvent event) {
        ZoomController.apply(event);
    }

    @SubscribeEvent
    public static void onHudRender(RenderGuiEvent.Post event) {
        if (!PotatoCoreConfig.SHOW_STATUS_HUD.get()) {
            return;
        }

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null) {
            return;
        }

        List<String> lines = new ArrayList<>();
        lines.add("POTATOCORE");
        BlockPos position = minecraft.player.blockPosition();
        lines.add("XYZ: " + position.getX() + " / " + position.getY() + " / " + position.getZ());
        lines.add("Dimension: " + minecraft.level.dimension().location().getPath());

        if (ClickerController.isLeftEnabled()) {
            lines.add("Left click: ACTIVE");
        }
        if (ClickerController.isRightEnabled()) {
            lines.add("Right click: " + ClickerController.getRightMode().getDisplayName());
        }
        if (MacroController.isEnabled()) {
            lines.add("Macro: " + MacroController.getStatus());
        }
        if (AutoFishController.isEnabled()) {
            lines.add("Auto Fish: " + AutoFishController.getStatus());
        }
        if (ToggleSprintController.isEnabled()) {
            lines.add("Toggle Sprint: ON");
        }

        GuiGraphics graphics = event.getGuiGraphics();
        int panelHeight = 8 + lines.size() * 11;
        graphics.fill(6, 6, 190, panelHeight, 0x99091018);

        int y = 10;
        for (int i = 0; i < lines.size(); i++) {
            int color = i == 0 ? 0xFFF1D5A5 : 0xFFE0E8F0;
            graphics.drawString(minecraft.font, lines.get(i), 12, y, color, true);
            y += 11;
        }
    }
}

package com.tato.potatocore.client;

import com.tato.potatocore.PotatoCore;
import com.tato.potatocore.client.gui.MacroBuilderScreen;
import com.tato.potatocore.client.gui.PotatoCoreScreen;
import com.tato.potatocore.client.macro.MacroController;
import net.minecraft.client.Minecraft;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.event.TickEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

@Mod.EventBusSubscriber(modid = PotatoCore.MOD_ID, value = Dist.CLIENT)
public final class ClientForgeEvents {
    private ClientForgeEvents() {
    }

    @SubscribeEvent
    public static void onClientTick(TickEvent.ClientTickEvent event) {
        if (event.phase != TickEvent.Phase.END) {
            return;
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

        Minecraft minecraft = Minecraft.getInstance();
        while (ClientKeyMappings.OPEN_MAIN_MENU.consumeClick()) {
            minecraft.setScreen(new PotatoCoreScreen());
        }

        while (ClientKeyMappings.OPEN_MACRO_BUILDER.consumeClick()) {
            minecraft.setScreen(new MacroBuilderScreen());
        }

        ClickerController.tick();
        MacroController.tick();
    }
}

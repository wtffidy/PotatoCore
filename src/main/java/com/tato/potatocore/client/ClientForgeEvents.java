package com.tato.potatocore.client;

import com.tato.potatocore.PotatoCore;
import com.tato.potatocore.client.gui.MacroBuilderScreen;
import com.tato.potatocore.client.gui.PotatoCoreScreen;
import com.tato.potatocore.client.macro.BloodMagicKnifeMacro;
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

        while (ClientKeyMappings.TOGGLE_CLICKER.consumeClick()) {
            ClickerController.toggle();
        }
        while (ClientKeyMappings.NEXT_CLICK_MODE.consumeClick()) {
            ClickerController.cycleMode();
        }

        Minecraft minecraft = Minecraft.getInstance();
        while (ClientKeyMappings.OPEN_MAIN_MENU.consumeClick()) {
            minecraft.setScreen(new PotatoCoreScreen());
        }
        while (ClientKeyMappings.OPEN_MACRO_BUILDER.consumeClick()) {
            minecraft.setScreen(new MacroBuilderScreen());
        }

        ClickerController.tick();
        BloodMagicKnifeMacro.tick();
    }
}

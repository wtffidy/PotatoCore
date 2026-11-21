package com.tato.potatocore.client;

import com.tato.potatocore.PotatoCore;
import net.minecraftforge.api.distmarker.Dist;
import net.minecraftforge.client.event.RegisterKeyMappingsEvent;
import net.minecraftforge.eventbus.api.SubscribeEvent;
import net.minecraftforge.fml.common.Mod;

@Mod.EventBusSubscriber(modid = PotatoCore.MOD_ID, value = Dist.CLIENT, bus = Mod.EventBusSubscriber.Bus.MOD)
public final class ClientModEvents {
    private ClientModEvents() {
    }

    @SubscribeEvent
    public static void registerKeyMappings(RegisterKeyMappingsEvent event) {
        event.register(ClientKeyMappings.TOGGLE_LEFT_CLICK);
        event.register(ClientKeyMappings.TOGGLE_RIGHT_CLICK);
        event.register(ClientKeyMappings.OPEN_MACRO_BUILDER);
        event.register(ClientKeyMappings.NEXT_RIGHT_MODE);
        event.register(ClientKeyMappings.TOGGLE_MACRO);
        event.register(ClientKeyMappings.OPEN_MAIN_MENU);
    }
}

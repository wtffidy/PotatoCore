package com.tato.potatocore.client;

import net.minecraft.client.Minecraft;
import net.minecraftforge.client.event.ComputeFovModifierEvent;

public final class ZoomController {
    private static final float ZOOM_MODIFIER = 0.25F;
    private static final float SMOOTHING = 0.35F;
    private static float currentModifier = 1.0F;

    private ZoomController() {
    }

    public static void apply(ComputeFovModifierEvent event) {
        Minecraft minecraft = Minecraft.getInstance();
        boolean zoomHeld = minecraft.player != null
                && event.getPlayer() == minecraft.player
                && minecraft.screen == null
                && ClientKeyMappings.HOLD_TO_ZOOM.isDown();

        float targetModifier = zoomHeld ? ZOOM_MODIFIER : 1.0F;
        currentModifier += (targetModifier - currentModifier) * SMOOTHING;

        if (Math.abs(targetModifier - currentModifier) < 0.005F) {
            currentModifier = targetModifier;
        }

        event.setNewFovModifier(event.getNewFovModifier() * currentModifier);
    }
}

package com.tato.potatocore.client;

import com.mojang.blaze3d.platform.InputConstants;
import net.minecraft.client.Minecraft;
import net.minecraft.client.KeyMapping;
import org.lwjgl.glfw.GLFW;

public final class ToggleSprintController {
    private static boolean enabled;

    private ToggleSprintController() {
    }

    public static void toggle() {
        enabled = !enabled;
    }

    public static boolean isEnabled() {
        return enabled;
    }

    public static void tick() {
        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.level == null || minecraft.screen != null || minecraft.isPaused()) {
            minecraft.options.keySprint.setDown(false);
            return;
        }

        // Preserve the physical sprint key when toggle sprint is disabled.
        boolean physicallyPressed = isSprintKeyPhysicallyPressed(minecraft);
        minecraft.options.keySprint.setDown(enabled || physicallyPressed);
    }

    private static boolean isSprintKeyPhysicallyPressed(Minecraft minecraft) {
        InputConstants.Key sprintKey = minecraft.options.keySprint.getKey();
        long window = minecraft.getWindow().getWindow();

        if (sprintKey.getType() == InputConstants.Type.KEYSYM) {
            return InputConstants.isKeyDown(window, sprintKey.getValue());
        }

        if (sprintKey.getType() == InputConstants.Type.MOUSE) {
            return GLFW.glfwGetMouseButton(window, sprintKey.getValue()) == GLFW.GLFW_PRESS;
        }

        return false;
    }
}

package com.tato.potatocore.client;

import net.minecraft.client.KeyMapping;
import org.lwjgl.glfw.GLFW;

public final class ClientKeyMappings {
    private static final String CATEGORY = "key.categories.potato_core";
    public static final KeyMapping TOGGLE_CLICKER = new KeyMapping("key.potato_core.toggle_clicker", GLFW.GLFW_KEY_F6, CATEGORY);
    public static final KeyMapping NEXT_CLICK_MODE = new KeyMapping("key.potato_core.next_click_mode", GLFW.GLFW_KEY_F7, CATEGORY);
    public static final KeyMapping OPEN_MAIN_MENU = new KeyMapping("key.potato_core.open_main_menu", GLFW.GLFW_KEY_O, CATEGORY);
    public static final KeyMapping OPEN_MACRO_BUILDER = new KeyMapping("key.potato_core.open_macro_builder", GLFW.GLFW_KEY_F8, CATEGORY);

    private ClientKeyMappings() {
    }
}

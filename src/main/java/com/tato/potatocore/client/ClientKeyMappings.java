package com.tato.potatocore.client;

import net.minecraft.client.KeyMapping;
import org.lwjgl.glfw.GLFW;

public final class ClientKeyMappings {
    private static final String CATEGORY = "key.categories.potato_core";

    public static final KeyMapping TOGGLE_LEFT_CLICK = new KeyMapping(
            "key.potato_core.toggle_left_click", GLFW.GLFW_KEY_F6, CATEGORY);
    public static final KeyMapping TOGGLE_RIGHT_CLICK = new KeyMapping(
            "key.potato_core.toggle_right_click", GLFW.GLFW_KEY_F7, CATEGORY);
    public static final KeyMapping OPEN_MACRO_BUILDER = new KeyMapping(
            "key.potato_core.open_macro_builder", GLFW.GLFW_KEY_F8, CATEGORY);
    public static final KeyMapping NEXT_RIGHT_MODE = new KeyMapping(
            "key.potato_core.next_right_mode", GLFW.GLFW_KEY_F9, CATEGORY);
    public static final KeyMapping TOGGLE_MACRO = new KeyMapping(
            "key.potato_core.toggle_macro", GLFW.GLFW_KEY_F10, CATEGORY);
    public static final KeyMapping TOGGLE_AUTO_FISH = new KeyMapping(
            "key.potato_core.toggle_auto_fish", GLFW.GLFW_KEY_F11, CATEGORY);
    public static final KeyMapping OPEN_MAIN_MENU = new KeyMapping(
            "key.potato_core.open_main_menu", GLFW.GLFW_KEY_O, CATEGORY);

    private ClientKeyMappings() {
    }
}

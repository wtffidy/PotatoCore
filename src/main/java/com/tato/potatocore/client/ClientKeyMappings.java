package com.tato.potatocore.client;

import net.minecraft.client.KeyMapping;
import org.lwjgl.glfw.GLFW;

public final class ClientKeyMappings {
    private static final String AUTOMATION_CATEGORY = "key.categories.potato_core.automation";
    private static final String INTERFACE_CATEGORY = "key.categories.potato_core.interface";
    private static final String MOVEMENT_CATEGORY = "key.categories.potato_core.movement";
    private static final String VIEW_CATEGORY = "key.categories.potato_core.view";
    private static final String UTILITY_CATEGORY = "key.categories.potato_core.utilities";

    public static final KeyMapping TOGGLE_LEFT_CLICK = new KeyMapping(
            "key.potato_core.toggle_left_click", GLFW.GLFW_KEY_F6, AUTOMATION_CATEGORY);
    public static final KeyMapping TOGGLE_RIGHT_CLICK = new KeyMapping(
            "key.potato_core.toggle_right_click", GLFW.GLFW_KEY_F7, AUTOMATION_CATEGORY);
    public static final KeyMapping OPEN_MACRO_BUILDER = new KeyMapping(
            "key.potato_core.open_macro_builder", GLFW.GLFW_KEY_F8, INTERFACE_CATEGORY);
    public static final KeyMapping NEXT_RIGHT_MODE = new KeyMapping(
            "key.potato_core.next_right_mode", GLFW.GLFW_KEY_F9, AUTOMATION_CATEGORY);
    public static final KeyMapping TOGGLE_MACRO = new KeyMapping(
            "key.potato_core.toggle_macro", GLFW.GLFW_KEY_F10, AUTOMATION_CATEGORY);
    public static final KeyMapping TOGGLE_AUTO_FISH = new KeyMapping(
            "key.potato_core.toggle_auto_fish", GLFW.GLFW_KEY_F12, AUTOMATION_CATEGORY);
    public static final KeyMapping OPEN_MAIN_MENU = new KeyMapping(
            "key.potato_core.open_main_menu", GLFW.GLFW_KEY_O, INTERFACE_CATEGORY);
    public static final KeyMapping TOGGLE_SPRINT = new KeyMapping(
            "key.potato_core.toggle_sprint", GLFW.GLFW_KEY_V, MOVEMENT_CATEGORY);
    public static final KeyMapping HOLD_TO_ZOOM = new KeyMapping(
            "key.potato_core.hold_to_zoom", GLFW.GLFW_KEY_C, VIEW_CATEGORY);
    public static final KeyMapping TOGGLE_STATUS_HUD = new KeyMapping(
            "key.potato_core.toggle_status_hud", GLFW.GLFW_KEY_HOME, UTILITY_CATEGORY);

    private ClientKeyMappings() {
    }
}

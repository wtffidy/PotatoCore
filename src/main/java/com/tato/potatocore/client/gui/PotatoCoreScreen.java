package com.tato.potatocore.client.gui;

import com.tato.potatocore.client.AutoFishController;
import com.tato.potatocore.client.ClickMode;
import com.tato.potatocore.client.ClickerController;
import com.tato.potatocore.client.UtilityController;
import com.tato.potatocore.client.macro.MacroAction;
import com.tato.potatocore.client.macro.MacroController;
import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.AbstractWidget;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.ResourceLocation;
import net.minecraftforge.registries.ForgeRegistries;

import java.util.ArrayList;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;

public final class PotatoCoreScreen extends Screen {
    public enum Tab {
        CLICKER,
        MACROS,
        FISHING,
        UTILITIES
    }

    private static final int PANEL_WIDTH = 470;
    private static final int PANEL_HEIGHT = 370;

    private final Map<Tab, List<AbstractWidget>> tabWidgets = new EnumMap<>(Tab.class);
    private final Button[] tabButtons = new Button[Tab.values().length];

    private Tab activeTab;
    private boolean editingLeftInterval = true;
    private ClickMode displayedRightMode = ClickMode.RIGHT;

    private Button leftToggleButton;
    private Button rightToggleButton;
    private Button rightModeButton;
    private Button intervalTargetButton;
    private Button autoFishButton;
    private Button macroToggleButton;
    private Button macroActionButton;
    private Button requireItemButton;
    private Button healthGuardButton;
    private Button resumeButton;
    private Button hudButton;
    private Button durabilityButton;
    private Button inventoryButton;

    private EditBox minutesInput;
    private EditBox secondsInput;
    private EditBox millisecondsInput;
    private EditBox fishDelayInput;
    private EditBox itemIdInput;
    private EditBox stopHeartsInput;
    private EditBox macroIntervalInput;
    private EditBox durabilityThresholdInput;

    public PotatoCoreScreen() {
        this(Tab.CLICKER);
    }

    public PotatoCoreScreen(Tab initialTab) {
        super(Component.literal("PotatoCore"));
        activeTab = initialTab;
    }

    @Override
    protected void init() {
        for (Tab tab : Tab.values()) {
            tabWidgets.put(tab, new ArrayList<>());
        }

        int left = width / 2 - PANEL_WIDTH / 2;
        int top = Math.max(8, height / 2 - PANEL_HEIGHT / 2);

        for (Tab tab : Tab.values()) {
            int index = tab.ordinal();
            int tabWidth = 105;
            int x = left + 12 + index * 110;
            tabButtons[index] = addRenderableWidget(Button.builder(tabText(tab), button -> selectTab(tab))
                    .bounds(x, top + 32, tabWidth, 20).build());
        }

        addRenderableWidget(Button.builder(Component.literal("X"), button -> onClose())
                .bounds(left + PANEL_WIDTH - 31, top + 7, 20, 18).build());

        buildClickerTab(left, top);
        buildMacroTab(left, top);
        buildFishingTab(left, top);
        buildUtilitiesTab(left, top);
        updateTabVisibility();
        updateTabLabels();
    }

    private void buildClickerTab(int left, int top) {
        leftToggleButton = addTabWidget(Tab.CLICKER, Button.builder(leftToggleText(), button -> {
            ClickerController.toggleLeft();
            button.setMessage(leftToggleText());
        }).bounds(left + 18, top + 82, 210, 20).build());

        rightToggleButton = addTabWidget(Tab.CLICKER, Button.builder(rightToggleText(), button -> {
            ClickerController.toggleRight();
            button.setMessage(rightToggleText());
        }).bounds(left + 242, top + 82, 210, 20).build());

        displayedRightMode = ClickerController.getRightMode();
        rightModeButton = addTabWidget(Tab.CLICKER, Button.builder(rightModeText(), button -> {
            ClickerController.cycleRightMode();
            displayedRightMode = ClickerController.getRightMode();
            button.setMessage(rightModeText());
            intervalTargetButton.setMessage(intervalTargetText());
            if (!editingLeftInterval) {
                loadIntervalFields();
            }
        }).bounds(left + 18, top + 109, 434, 20).build());

        intervalTargetButton = addTabWidget(Tab.CLICKER, Button.builder(intervalTargetText(), button -> {
            editingLeftInterval = !editingLeftInterval;
            button.setMessage(intervalTargetText());
            loadIntervalFields();
        }).bounds(left + 18, top + 136, 434, 20).build());

        minutesInput = new EditBox(font, left + 18, top + 178, 125, 20, Component.literal("Minutes"));
        secondsInput = new EditBox(font, left + 173, top + 178, 125, 20, Component.literal("Seconds"));
        millisecondsInput = new EditBox(font, left + 328, top + 178, 124, 20, Component.literal("Milliseconds"));
        minutesInput.setMaxLength(3);
        secondsInput.setMaxLength(2);
        millisecondsInput.setMaxLength(3);
        addTabWidget(Tab.CLICKER, minutesInput);
        addTabWidget(Tab.CLICKER, secondsInput);
        addTabWidget(Tab.CLICKER, millisecondsInput);

        addTabWidget(Tab.CLICKER, Button.builder(Component.literal("Save click interval"), button -> saveClickInterval())
                .bounds(left + 18, top + 207, 434, 20).build());

        loadIntervalFields();
    }

    private void buildMacroTab(int left, int top) {
        macroToggleButton = addTabWidget(Tab.MACROS, Button.builder(macroToggleText(), button -> {
            MacroController.toggle();
            button.setMessage(macroToggleText());
        }).bounds(left + 18, top + 78, 434, 20).build());

        macroActionButton = addTabWidget(Tab.MACROS, Button.builder(macroActionText(), button -> {
            PotatoCoreConfig.MACRO_ACTION.set(getMacroAction().next().name());
            PotatoCoreConfig.SPEC.save();
            button.setMessage(macroActionText());
        }).bounds(left + 18, top + 105, 434, 20).build());

        addTabWidget(Tab.MACROS, Button.builder(Component.literal("Load Blood Magic Knife preset"), button -> loadBloodMagicPreset())
                .bounds(left + 18, top + 132, 434, 20).build());

        requireItemButton = addTabWidget(Tab.MACROS, Button.builder(requireItemText(), button -> {
            PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.set(!PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.get());
            PotatoCoreConfig.SPEC.save();
            button.setMessage(requireItemText());
        }).bounds(left + 18, top + 159, 434, 20).build());

        itemIdInput = new EditBox(font, left + 18, top + 186, 300, 20, Component.literal("Required item registry ID"));
        itemIdInput.setMaxLength(128);
        itemIdInput.setValue(PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.get());
        addTabWidget(Tab.MACROS, itemIdInput);

        addTabWidget(Tab.MACROS, Button.builder(Component.literal("Capture held item"), button -> captureHeldItem())
                .bounds(left + 326, top + 186, 126, 20).build());

        healthGuardButton = addTabWidget(Tab.MACROS, Button.builder(healthGuardText(), button -> {
            PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.set(!PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.get());
            PotatoCoreConfig.SPEC.save();
            button.setMessage(healthGuardText());
        }).bounds(left + 18, top + 213, 210, 20).build());

        resumeButton = addTabWidget(Tab.MACROS, Button.builder(resumeText(), button -> {
            PotatoCoreConfig.MACRO_AUTO_RESUME.set(!PotatoCoreConfig.MACRO_AUTO_RESUME.get());
            PotatoCoreConfig.SPEC.save();
            button.setMessage(resumeText());
        }).bounds(left + 242, top + 213, 210, 20).build());

        stopHeartsInput = new EditBox(font, left + 18, top + 254, 210, 20, Component.literal("Stop at hearts"));
        stopHeartsInput.setMaxLength(2);
        stopHeartsInput.setValue(Integer.toString(PotatoCoreConfig.MACRO_STOP_HEARTS.get()));
        addTabWidget(Tab.MACROS, stopHeartsInput);

        macroIntervalInput = new EditBox(font, left + 242, top + 254, 210, 20, Component.literal("Interval ms"));
        macroIntervalInput.setMaxLength(5);
        macroIntervalInput.setValue(Integer.toString(PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.get()));
        addTabWidget(Tab.MACROS, macroIntervalInput);

        addTabWidget(Tab.MACROS, Button.builder(Component.literal("Save macro settings"), button -> saveMacroSettings())
                .bounds(left + 18, top + 281, 434, 20).build());
    }

    private void buildFishingTab(int left, int top) {
        autoFishButton = addTabWidget(Tab.FISHING, Button.builder(autoFishText(), button -> {
            AutoFishController.toggle();
            button.setMessage(autoFishText());
        }).bounds(left + 18, top + 90, 434, 20).build());

        fishDelayInput = new EditBox(font, left + 18, top + 147, 210, 20, Component.literal("Recast delay (ms)"));
        fishDelayInput.setMaxLength(5);
        fishDelayInput.setValue(Integer.toString(PotatoCoreConfig.AUTO_FISH_RECAST_DELAY_MS.get()));
        addTabWidget(Tab.FISHING, fishDelayInput);

        addTabWidget(Tab.FISHING, Button.builder(Component.literal("Save fishing settings"), button -> saveFishSettings())
                .bounds(left + 242, top + 147, 210, 20).build());
    }

    private void buildUtilitiesTab(int left, int top) {
        hudButton = addTabWidget(Tab.UTILITIES, Button.builder(hudText(), button -> {
            PotatoCoreConfig.SHOW_STATUS_HUD.set(!PotatoCoreConfig.SHOW_STATUS_HUD.get());
            PotatoCoreConfig.SPEC.save();
            button.setMessage(hudText());
        }).bounds(left + 18, top + 82, 434, 20).build());

        durabilityButton = addTabWidget(Tab.UTILITIES, Button.builder(durabilityText(), button -> {
            PotatoCoreConfig.DURABILITY_WARNING_ENABLED.set(!PotatoCoreConfig.DURABILITY_WARNING_ENABLED.get());
            PotatoCoreConfig.SPEC.save();
            button.setMessage(durabilityText());
        }).bounds(left + 18, top + 109, 434, 20).build());

        inventoryButton = addTabWidget(Tab.UTILITIES, Button.builder(inventoryText(), button -> {
            PotatoCoreConfig.INVENTORY_FULL_WARNING_ENABLED.set(!PotatoCoreConfig.INVENTORY_FULL_WARNING_ENABLED.get());
            PotatoCoreConfig.SPEC.save();
            button.setMessage(inventoryText());
        }).bounds(left + 18, top + 136, 434, 20).build());

        durabilityThresholdInput = new EditBox(font, left + 18, top + 190, 100, 20,
                Component.literal("Durability %"));
        durabilityThresholdInput.setMaxLength(3);
        durabilityThresholdInput.setValue(Integer.toString(PotatoCoreConfig.DURABILITY_WARNING_PERCENT.get()));
        addTabWidget(Tab.UTILITIES, durabilityThresholdInput);

        addTabWidget(Tab.UTILITIES, Button.builder(Component.literal("Save warning threshold"), button -> saveUtilitySettings())
                .bounds(left + 128, top + 190, 210, 20).build());

        addTabWidget(Tab.UTILITIES, Button.builder(Component.literal("Copy coordinates"), button -> UtilityController.copyCoordinates())
                .bounds(left + 18, top + 220, 434, 20).build());
    }

    private <T extends AbstractWidget> T addTabWidget(Tab tab, T widget) {
        addRenderableWidget(widget);
        tabWidgets.get(tab).add(widget);
        widget.visible = tab == activeTab;
        return widget;
    }

    private void selectTab(Tab tab) {
        if (activeTab == tab) {
            return;
        }

        activeTab = tab;
        updateTabVisibility();
        updateTabLabels();
    }

    private void updateTabVisibility() {
        for (Map.Entry<Tab, List<AbstractWidget>> entry : tabWidgets.entrySet()) {
            for (AbstractWidget widget : entry.getValue()) {
                widget.visible = entry.getKey() == activeTab;
            }
        }
    }

    private void updateTabLabels() {
        for (Tab tab : Tab.values()) {
            tabButtons[tab.ordinal()].setMessage(tabText(tab));
        }
    }

    private Component tabText(Tab tab) {
        String name = switch (tab) {
            case CLICKER -> "Clicker";
            case MACROS -> "Macros";
            case FISHING -> "Fishing";
            case UTILITIES -> "Utilities";
        };
        return Component.literal(activeTab == tab ? "• " + name : name);
    }

    private Component leftToggleText() {
        return Component.literal("Left Click: " + (ClickerController.isLeftEnabled() ? "ON (F6)" : "OFF (F6)"));
    }

    private Component rightToggleText() {
        return Component.literal("Right Click: " + (ClickerController.isRightEnabled() ? "ON (F7)" : "OFF (F7)"));
    }

    private Component rightModeText() {
        return Component.literal("Right Profile: " + ClickerController.getRightMode().getDisplayName() + " (F9)");
    }

    private Component intervalTargetText() {
        return Component.literal("Editing interval: " + (editingLeftInterval
                ? "Left Click"
                : ClickerController.getRightMode().getDisplayName()));
    }

    private Component autoFishText() {
        return Component.literal("Auto Fish: " + (AutoFishController.isEnabled() ? "ON (F12)" : "OFF (F12)"));
    }

    private Component macroToggleText() {
        return Component.literal("Macro: " + (MacroController.isEnabled() ? "ON (F10)" : "OFF (F10)"));
    }

    private Component macroActionText() {
        return Component.literal("Action: " + getMacroAction().getDisplayName());
    }

    private Component requireItemText() {
        return Component.literal("Require exact held item: " +
                (PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.get() ? "ON" : "OFF"));
    }

    private Component healthGuardText() {
        return Component.literal("Health safety guard: " +
                (PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.get() ? "ON" : "OFF"));
    }

    private Component resumeText() {
        return Component.literal("Auto-resume after healing: " +
                (PotatoCoreConfig.MACRO_AUTO_RESUME.get() ? "ON" : "OFF"));
    }

    private Component hudText() {
        return Component.literal("Status HUD: " + (PotatoCoreConfig.SHOW_STATUS_HUD.get() ? "ON" : "OFF"));
    }

    private Component durabilityText() {
        return Component.literal("Low durability alerts: " +
                (PotatoCoreConfig.DURABILITY_WARNING_ENABLED.get() ? "ON" : "OFF"));
    }

    private Component inventoryText() {
        return Component.literal("No empty inventory slot alerts: " +
                (PotatoCoreConfig.INVENTORY_FULL_WARNING_ENABLED.get() ? "ON" : "OFF"));
    }

    private ClickMode getEditingMode() {
        return editingLeftInterval ? ClickMode.LEFT : ClickerController.getRightMode();
    }

    private MacroAction getMacroAction() {
        return MacroAction.fromConfig(PotatoCoreConfig.MACRO_ACTION.get());
    }

    private void loadIntervalFields() {
        ClickMode mode = getEditingMode();
        int minutes;
        int seconds;
        int milliseconds;

        switch (mode) {
            case LEFT -> {
                minutes = PotatoCoreConfig.LEFT_MINUTES.get();
                seconds = PotatoCoreConfig.LEFT_SECONDS.get();
                milliseconds = PotatoCoreConfig.LEFT_MILLISECONDS.get();
            }
            case RIGHT -> {
                minutes = PotatoCoreConfig.RIGHT_MINUTES.get();
                seconds = PotatoCoreConfig.RIGHT_SECONDS.get();
                milliseconds = PotatoCoreConfig.RIGHT_MILLISECONDS.get();
            }
            case PEBBLES -> {
                minutes = PotatoCoreConfig.PEBBLES_MINUTES.get();
                seconds = PotatoCoreConfig.PEBBLES_SECONDS.get();
                milliseconds = PotatoCoreConfig.PEBBLES_MILLISECONDS.get();
            }
            case SIEVE -> {
                minutes = PotatoCoreConfig.SIEVE_MINUTES.get();
                seconds = PotatoCoreConfig.SIEVE_SECONDS.get();
                milliseconds = PotatoCoreConfig.SIEVE_MILLISECONDS.get();
            }
            default -> throw new IllegalStateException("Unsupported click mode: " + mode);
        }

        minutesInput.setValue(Integer.toString(minutes));
        secondsInput.setValue(Integer.toString(seconds));
        millisecondsInput.setValue(Integer.toString(milliseconds));
    }

    private void saveClickInterval() {
        int minutes = parse(minutesInput.getValue(), 0, 999);
        int seconds = parse(secondsInput.getValue(), 0, 59);
        int milliseconds = parse(millisecondsInput.getValue(), 0, 999);

        switch (getEditingMode()) {
            case LEFT -> {
                PotatoCoreConfig.LEFT_MINUTES.set(minutes);
                PotatoCoreConfig.LEFT_SECONDS.set(seconds);
                PotatoCoreConfig.LEFT_MILLISECONDS.set(milliseconds);
            }
            case RIGHT -> {
                PotatoCoreConfig.RIGHT_MINUTES.set(minutes);
                PotatoCoreConfig.RIGHT_SECONDS.set(seconds);
                PotatoCoreConfig.RIGHT_MILLISECONDS.set(milliseconds);
            }
            case PEBBLES -> {
                PotatoCoreConfig.PEBBLES_MINUTES.set(minutes);
                PotatoCoreConfig.PEBBLES_SECONDS.set(seconds);
                PotatoCoreConfig.PEBBLES_MILLISECONDS.set(milliseconds);
            }
            case SIEVE -> {
                PotatoCoreConfig.SIEVE_MINUTES.set(minutes);
                PotatoCoreConfig.SIEVE_SECONDS.set(seconds);
                PotatoCoreConfig.SIEVE_MILLISECONDS.set(milliseconds);
            }
        }
        PotatoCoreConfig.SPEC.save();
    }

    private void saveMacroSettings() {
        PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.set(itemIdInput.getValue().trim());
        PotatoCoreConfig.MACRO_STOP_HEARTS.set(parse(stopHeartsInput.getValue(), 1, 10));
        PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.set(parse(macroIntervalInput.getValue(), 1, 60000));
        PotatoCoreConfig.SPEC.save();
    }

    private void saveFishSettings() {
        PotatoCoreConfig.AUTO_FISH_RECAST_DELAY_MS.set(parse(fishDelayInput.getValue(), 250, 10000));
        fishDelayInput.setValue(Integer.toString(PotatoCoreConfig.AUTO_FISH_RECAST_DELAY_MS.get()));
        PotatoCoreConfig.SPEC.save();
    }

    private void saveUtilitySettings() {
        PotatoCoreConfig.DURABILITY_WARNING_PERCENT.set(parse(durabilityThresholdInput.getValue(), 1, 100));
        durabilityThresholdInput.setValue(Integer.toString(PotatoCoreConfig.DURABILITY_WARNING_PERCENT.get()));
        PotatoCoreConfig.SPEC.save();
    }

    private void captureHeldItem() {
        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player == null || minecraft.player.getMainHandItem().isEmpty()) {
            return;
        }

        ResourceLocation itemId = ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem());
        if (itemId == null) {
            return;
        }

        itemIdInput.setValue(itemId.toString());
        PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.set(itemId.toString());
        PotatoCoreConfig.SPEC.save();
    }

    private void loadBloodMagicPreset() {
        PotatoCoreConfig.MACRO_ACTION.set(MacroAction.RIGHT_CLICK.name());
        PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.set(true);
        PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.set(true);
        PotatoCoreConfig.MACRO_STOP_HEARTS.set(1);
        PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.set(250);
        PotatoCoreConfig.MACRO_AUTO_RESUME.set(true);

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player != null && !minecraft.player.getMainHandItem().isEmpty()) {
            ResourceLocation itemId = ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem());
            if (itemId != null) {
                PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.set(itemId.toString());
            }
        }

        PotatoCoreConfig.SPEC.save();
        itemIdInput.setValue(PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.get());
        stopHeartsInput.setValue("1");
        macroIntervalInput.setValue("250");
        macroActionButton.setMessage(macroActionText());
        requireItemButton.setMessage(requireItemText());
        healthGuardButton.setMessage(healthGuardText());
        resumeButton.setMessage(resumeText());
    }

    private static int parse(String value, int minimum, int maximum) {
        try {
            return Math.max(minimum, Math.min(maximum, Integer.parseInt(value)));
        } catch (NumberFormatException exception) {
            return minimum;
        }
    }

    @Override
    public void render(GuiGraphics graphics, int mouseX, int mouseY, float partialTick) {
        ClickMode rightMode = ClickerController.getRightMode();
        if (rightMode != displayedRightMode) {
            displayedRightMode = rightMode;
            rightModeButton.setMessage(rightModeText());
            intervalTargetButton.setMessage(intervalTargetText());
            if (!editingLeftInterval) {
                loadIntervalFields();
            }
        }

        leftToggleButton.setMessage(leftToggleText());
        rightToggleButton.setMessage(rightToggleText());
        autoFishButton.setMessage(autoFishText());
        macroToggleButton.setMessage(macroToggleText());
        hudButton.setMessage(hudText());
        durabilityButton.setMessage(durabilityText());
        inventoryButton.setMessage(inventoryText());

        int left = width / 2 - PANEL_WIDTH / 2;
        int top = Math.max(8, height / 2 - PANEL_HEIGHT / 2);

        // Keep the world visible; only the control panel itself receives a translucent backdrop.
        graphics.fill(left, top, left + PANEL_WIDTH, top + PANEL_HEIGHT, 0xC9101827);
        graphics.fill(left, top, left + PANEL_WIDTH, top + 3, 0xFFB77B36);
        graphics.fill(left + 12, top + 60, left + PANEL_WIDTH - 12, top + 61, 0x88566A80);

        super.render(graphics, mouseX, mouseY, partialTick);

        graphics.drawCenteredString(font, Component.literal("POTATOCORE").withStyle(style -> style.withBold(true)),
                width / 2, top + 12, 0xFFF1D5A5);

        switch (activeTab) {
            case CLICKER -> {
                graphics.drawString(font, "CLICK AUTOMATION", left + 18, top + 68, 0xFF9CB5D0);
                graphics.drawString(font, "MINUTES", left + 18, top + 166, 0xFFB9C7D6);
                graphics.drawString(font, "SECONDS", left + 173, top + 166, 0xFFB9C7D6);
                graphics.drawString(font, "MILLISECONDS", left + 328, top + 166, 0xFFB9C7D6);
                graphics.drawCenteredString(font, "Both clickers can run independently.", width / 2, top + 245, 0xFFB9C7D6);
            }
            case MACROS -> {
                graphics.drawString(font, "MACRO WORKSHOP", left + 18, top + 65, 0xFF9CB5D0);
                graphics.drawString(font, "Required held item", left + 18, top + 176, 0xFFB9C7D6);
                graphics.drawString(font, "Stop at hearts", left + 18, top + 242, 0xFFB9C7D6);
                graphics.drawString(font, "Interval (ms)", left + 242, top + 242, 0xFFB9C7D6);
                graphics.drawCenteredString(font, "Status: " + MacroController.getStatus(), width / 2, top + 315, 0xFFB9C7D6);
            }
            case FISHING -> {
                graphics.drawString(font, "FISHING ASSISTANT", left + 18, top + 75, 0xFF9CB5D0);
                graphics.drawString(font, "Recast delay (milliseconds)", left + 18, top + 133, 0xFFB9C7D6);
                graphics.drawCenteredString(font, "Status: " + AutoFishController.getStatus(), width / 2, top + 210, 0xFFB9C7D6);
                graphics.drawCenteredString(font, "Hold a fishing rod, cast once, then let Auto Fish handle the cycle.",
                        width / 2, top + 235, 0xFF9CAFC4);
            }
            case UTILITIES -> {
                graphics.drawString(font, "QUALITY OF LIFE", left + 18, top + 68, 0xFF9CB5D0);
                graphics.drawString(font, "Warn when remaining durability reaches this percentage:", left + 18, top + 174,
                        0xFFB9C7D6);
                graphics.drawCenteredString(font, "HUD includes coordinates and enabled automation status.",
                        width / 2, top + 270, 0xFF9CAFC4);
            }
        }

        graphics.drawCenteredString(font, "O: open menu   F6: left   F7: right   F8: macros   F9: profile   F10: macro   F12: fish",
                width / 2, top + PANEL_HEIGHT - 14, 0xFF899BAF);
    }

    @Override
    public boolean isPauseScreen() {
        return false;
    }
}

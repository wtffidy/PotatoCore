package com.tato.potatocore.client.gui;

import com.tato.potatocore.client.macro.MacroAction;
import com.tato.potatocore.client.macro.MacroController;
import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraftforge.registries.ForgeRegistries;

public final class MacroBuilderScreen extends Screen {
    private EditBox itemIdInput;
    private EditBox stopHeartsInput;
    private EditBox intervalInput;
    private Button actionButton;
    private Button requireItemButton;
    private Button healthGuardButton;
    private Button resumeButton;
    private Button enabledButton;

    public MacroBuilderScreen() {
        super(Component.literal("PotatoCore | Macro Builder"));
    }

    @Override
    protected void init() {
        int centerX = width / 2;
        int top = height / 2 - 142;

        enabledButton = addRenderableWidget(Button.builder(enabledText(), button -> {
            MacroController.toggle();
            button.setMessage(enabledText());
        }).bounds(centerX - 150, top, 300, 20).build());

        actionButton = addRenderableWidget(Button.builder(actionText(), button -> {
            MacroAction action = getAction().next();
            PotatoCoreConfig.MACRO_ACTION.set(action.name());
            button.setMessage(actionText());
            PotatoCoreConfig.SPEC.save();
        }).bounds(centerX - 150, top + 27, 300, 20).build());

        addRenderableWidget(Button.builder(Component.literal("Load Blood Magic Knife preset"), button -> loadBloodMagicPreset())
                .bounds(centerX - 150, top + 54, 300, 20).build());

        requireItemButton = addRenderableWidget(Button.builder(requireItemText(), button -> {
            PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.set(!PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.get());
            button.setMessage(requireItemText());
            PotatoCoreConfig.SPEC.save();
        }).bounds(centerX - 150, top + 81, 300, 20).build());

        itemIdInput = new EditBox(font, centerX - 150, top + 132, 300, 20,
                Component.literal("Required item registry ID"));
        itemIdInput.setMaxLength(128);
        itemIdInput.setValue(PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.get());
        addRenderableWidget(itemIdInput);

        addRenderableWidget(Button.builder(Component.literal("Use item in main hand"), button -> {
            Minecraft minecraft = Minecraft.getInstance();
            if (minecraft.player == null || minecraft.player.getMainHandItem().isEmpty()) {
                return;
            }

            itemIdInput.setValue(ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem()).toString());
        }).bounds(centerX - 150, top + 158, 300, 20).build());

        healthGuardButton = addRenderableWidget(Button.builder(healthGuardText(), button -> {
            PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.set(!PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.get());
            button.setMessage(healthGuardText());
            PotatoCoreConfig.SPEC.save();
        }).bounds(centerX - 150, top + 188, 300, 20).build());

        stopHeartsInput = new EditBox(font, centerX - 150, top + 230, 140, 20, Component.literal("Stop at hearts"));
        stopHeartsInput.setMaxLength(2);
        stopHeartsInput.setValue(Integer.toString(PotatoCoreConfig.MACRO_STOP_HEARTS.get()));
        addRenderableWidget(stopHeartsInput);

        intervalInput = new EditBox(font, centerX + 10, top + 230, 140, 20, Component.literal("Interval ms"));
        intervalInput.setMaxLength(5);
        intervalInput.setValue(Integer.toString(PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.get()));
        addRenderableWidget(intervalInput);

        resumeButton = addRenderableWidget(Button.builder(resumeText(), button -> {
            PotatoCoreConfig.MACRO_AUTO_RESUME.set(!PotatoCoreConfig.MACRO_AUTO_RESUME.get());
            button.setMessage(resumeText());
            PotatoCoreConfig.SPEC.save();
        }).bounds(centerX - 150, top + 260, 300, 20).build());

        addRenderableWidget(Button.builder(Component.literal("Save settings"), button -> save())
                .bounds(centerX - 150, top + 290, 145, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Back"), button ->
                Minecraft.getInstance().setScreen(new PotatoCoreScreen()))
                .bounds(centerX + 5, top + 290, 145, 20).build());
    }

    private MacroAction getAction() {
        return MacroAction.fromConfig(PotatoCoreConfig.MACRO_ACTION.get());
    }

    private Component enabledText() {
        return Component.literal("Macro: " + (MacroController.isEnabled() ? "ON (F10)" : "OFF (F10)"));
    }

    private Component actionText() {
        return Component.literal("Action: " + getAction().getDisplayName());
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

    private void loadBloodMagicPreset() {
        PotatoCoreConfig.MACRO_ACTION.set(MacroAction.RIGHT_CLICK.name());
        PotatoCoreConfig.MACRO_REQUIRE_HELD_ITEM.set(true);
        PotatoCoreConfig.MACRO_HEALTH_GUARD_ENABLED.set(true);
        PotatoCoreConfig.MACRO_STOP_HEARTS.set(1);
        PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.set(250);
        PotatoCoreConfig.MACRO_AUTO_RESUME.set(true);

        Minecraft minecraft = Minecraft.getInstance();
        if (minecraft.player != null && !minecraft.player.getMainHandItem().isEmpty()) {
            PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.set(
                    ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem()).toString());
        }

        PotatoCoreConfig.SPEC.save();
        refreshFields();
    }

    private void refreshFields() {
        actionButton.setMessage(actionText());
        requireItemButton.setMessage(requireItemText());
        healthGuardButton.setMessage(healthGuardText());
        resumeButton.setMessage(resumeText());
        itemIdInput.setValue(PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.get());
        stopHeartsInput.setValue(Integer.toString(PotatoCoreConfig.MACRO_STOP_HEARTS.get()));
        intervalInput.setValue(Integer.toString(PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.get()));
    }

    private void save() {
        PotatoCoreConfig.MACRO_REQUIRED_ITEM_ID.set(itemIdInput.getValue().trim());
        PotatoCoreConfig.MACRO_STOP_HEARTS.set(parse(stopHeartsInput.getValue(), 1, 10));
        PotatoCoreConfig.MACRO_INTERVAL_MILLISECONDS.set(parse(intervalInput.getValue(), 1, 60000));
        PotatoCoreConfig.SPEC.save();
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
        renderBackground(graphics);
        super.render(graphics, mouseX, mouseY, partialTick);
        int centerX = width / 2;
        int top = height / 2 - 142;
        graphics.drawCenteredString(font, title, centerX, top - 22, 0xFFFFFF);
        graphics.drawString(font, "Only runs while the selected main-hand condition is met:", centerX - 150, top + 118, 0xA0A0A0);
        graphics.drawString(font, "Stop at hearts", centerX - 150, top + 217, 0xA0A0A0);
        graphics.drawString(font, "Interval (ms)", centerX + 10, top + 217, 0xA0A0A0);
        graphics.drawCenteredString(font, "Status: " + MacroController.getStatus(), centerX, top + 322, 0xA0A0A0);
        graphics.drawCenteredString(font, "F8: open builder | F10: toggle macro | one heart = 2 HP", centerX, top + 336, 0xA0A0A0);
    }

    @Override
    public boolean isPauseScreen() {
        return false;
    }
}

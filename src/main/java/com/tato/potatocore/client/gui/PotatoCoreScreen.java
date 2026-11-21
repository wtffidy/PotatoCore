package com.tato.potatocore.client.gui;

import com.tato.potatocore.client.AutoFishController;
import com.tato.potatocore.client.ClickMode;
import com.tato.potatocore.client.ClickerController;
import com.tato.potatocore.client.macro.MacroController;
import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;

public final class PotatoCoreScreen extends Screen {
    private EditBox minutesInput;
    private EditBox secondsInput;
    private EditBox millisecondsInput;
    private EditBox fishDelayInput;
    private boolean editingLeftInterval = true;
    private ClickMode displayedRightMode = ClickMode.RIGHT;
    private Button leftToggleButton;
    private Button rightToggleButton;
    private Button rightModeButton;
    private Button intervalTargetButton;
    private Button autoFishButton;

    public PotatoCoreScreen() {
        super(Component.literal("PotatoCore"));
    }

    @Override
    protected void init() {
        int centerX = width / 2;
        int left = centerX - 210;
        int top = Math.max(12, (height - 326) / 2);
        displayedRightMode = ClickerController.getRightMode();

        leftToggleButton = addRenderableWidget(Button.builder(leftToggleText(), button -> {
            ClickerController.toggleLeft();
            button.setMessage(leftToggleText());
        }).bounds(left, top + 34, 205, 20).build());

        rightToggleButton = addRenderableWidget(Button.builder(rightToggleText(), button -> {
            ClickerController.toggleRight();
            button.setMessage(rightToggleText());
        }).bounds(left + 215, top + 34, 205, 20).build());

        rightModeButton = addRenderableWidget(Button.builder(rightModeText(), button -> {
            ClickerController.cycleRightMode();
            displayedRightMode = ClickerController.getRightMode();
            button.setMessage(rightModeText());
            intervalTargetButton.setMessage(intervalTargetText());
            if (!editingLeftInterval) {
                loadIntervalFields();
            }
        }).bounds(left, top + 61, 420, 20).build());

        intervalTargetButton = addRenderableWidget(Button.builder(intervalTargetText(), button -> {
            editingLeftInterval = !editingLeftInterval;
            button.setMessage(intervalTargetText());
            loadIntervalFields();
        }).bounds(left, top + 88, 420, 20).build());

        minutesInput = new EditBox(font, left + 50, top + 128, 90, 20, Component.literal("Minutes"));
        secondsInput = new EditBox(font, left + 160, top + 128, 90, 20, Component.literal("Seconds"));
        millisecondsInput = new EditBox(font, left + 270, top + 128, 100, 20, Component.literal("Milliseconds"));
        minutesInput.setMaxLength(3);
        secondsInput.setMaxLength(2);
        millisecondsInput.setMaxLength(3);
        addRenderableWidget(minutesInput);
        addRenderableWidget(secondsInput);
        addRenderableWidget(millisecondsInput);

        addRenderableWidget(Button.builder(Component.literal("Save click interval"), button -> saveSettings())
                .bounds(left, top + 155, 205, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Open Macro Builder"), button ->
                Minecraft.getInstance().setScreen(new MacroBuilderScreen()))
                .bounds(left + 215, top + 155, 205, 20).build());

        autoFishButton = addRenderableWidget(Button.builder(autoFishText(), button -> {
            AutoFishController.toggle();
            button.setMessage(autoFishText());
        }).bounds(left, top + 188, 270, 20).build());

        fishDelayInput = new EditBox(font, left + 280, top + 188, 140, 20, Component.literal("Recast delay ms"));
        fishDelayInput.setMaxLength(5);
        fishDelayInput.setValue(Integer.toString(PotatoCoreConfig.AUTO_FISH_RECAST_DELAY_MS.get()));
        addRenderableWidget(fishDelayInput);

        addRenderableWidget(Button.builder(Component.literal("Save fish delay"), button -> saveFishDelay())
                .bounds(left, top + 215, 205, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Done"), button -> onClose())
                .bounds(left + 215, top + 215, 205, 20).build());

        loadIntervalFields();
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
        return Component.literal("Auto Fish: " + (AutoFishController.isEnabled() ? "ON (F11)" : "OFF (F11)"));
    }

    private ClickMode getEditingMode() {
        return editingLeftInterval ? ClickMode.LEFT : ClickerController.getRightMode();
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

    private void saveSettings() {
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

    private void saveFishDelay() {
        PotatoCoreConfig.AUTO_FISH_RECAST_DELAY_MS.set(parse(fishDelayInput.getValue(), 250, 10000));
        fishDelayInput.setValue(Integer.toString(PotatoCoreConfig.AUTO_FISH_RECAST_DELAY_MS.get()));
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

        graphics.fillGradient(0, 0, width, height, 0xFF101827, 0xFF080B12);
        int left = width / 2 - 220;
        int top = Math.max(12, (height - 326) / 2);
        graphics.fill(left, top, left + 440, top + 252, 0xF0182232);
        graphics.fill(left, top, left + 440, top + 3, 0xFFB77B36);
        graphics.fill(left + 12, top + 27, left + 428, top + 28, 0xFF35465C);

        super.render(graphics, mouseX, mouseY, partialTick);

        graphics.drawCenteredString(font, Component.literal("POTATOCORE").withStyle(style -> style.withBold(true)),
                width / 2, top + 9, 0xFFF1D5A5);
        graphics.drawString(font, "CLICK AUTOMATION", left + 2, top + 24, 0xFF8DA8C7);
        graphics.drawString(font, "MINUTES", left + 58, top + 119, 0xFF9CAFC4);
        graphics.drawString(font, "SECONDS", left + 168, top + 119, 0xFF9CAFC4);
        graphics.drawString(font, "MILLISECONDS", left + 278, top + 119, 0xFF9CAFC4);
        graphics.drawString(font, "FISHING UTILITY", left + 2, top + 178, 0xFF8DA8C7);
        graphics.drawString(font, "Recast delay (ms)", left + 280, top + 178, 0xFF9CAFC4);
        graphics.drawCenteredString(font,
                "Macro: " + MacroController.getStatus() + "   |   Auto Fish: " + AutoFishController.getStatus(),
                width / 2, top + 242, 0xFFB7C7D8);
        graphics.drawCenteredString(font, "O: menu   F6: left   F7: right   F8: macros   F9: profile   F10: macro   F11: fish",
                width / 2, top + 265, 0xFF8496AA);
    }

    @Override
    public boolean isPauseScreen() {
        return false;
    }
}

package com.tato.potatocore.client.gui;

import com.tato.potatocore.client.ClickMode;
import com.tato.potatocore.client.ClickerController;
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
    private boolean editingLeftInterval = true;

    public PotatoCoreScreen() {
        super(Component.literal("PotatoCore"));
    }

    @Override
    protected void init() {
        int centerX = width / 2;
        int top = height / 2 - 118;

        addRenderableWidget(Button.builder(leftToggleText(), button -> {
            ClickerController.toggleLeft();
            button.setMessage(leftToggleText());
        }).bounds(centerX - 145, top, 140, 20).build());

        addRenderableWidget(Button.builder(rightToggleText(), button -> {
            ClickerController.toggleRight();
            button.setMessage(rightToggleText());
        }).bounds(centerX + 5, top, 140, 20).build());

        addRenderableWidget(Button.builder(rightModeText(), button -> {
            ClickerController.cycleRightMode();
            button.setMessage(rightModeText());
            if (!editingLeftInterval) {
                loadIntervalFields();
            }
        }).bounds(centerX - 145, top + 28, 290, 20).build());

        addRenderableWidget(Button.builder(intervalTargetText(), button -> {
            editingLeftInterval = !editingLeftInterval;
            button.setMessage(intervalTargetText());
            loadIntervalFields();
        }).bounds(centerX - 145, top + 59, 290, 20).build());

        minutesInput = new EditBox(font, centerX - 145, top + 105, 80, 20, Component.literal("Minutes"));
        secondsInput = new EditBox(font, centerX - 45, top + 105, 80, 20, Component.literal("Seconds"));
        millisecondsInput = new EditBox(font, centerX + 55, top + 105, 90, 20, Component.literal("Milliseconds"));
        minutesInput.setMaxLength(3);
        secondsInput.setMaxLength(2);
        millisecondsInput.setMaxLength(3);
        addRenderableWidget(minutesInput);
        addRenderableWidget(secondsInput);
        addRenderableWidget(millisecondsInput);

        addRenderableWidget(Button.builder(Component.literal("Save interval"), button -> saveInterval())
                .bounds(centerX - 145, top + 135, 140, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Macro Builder (F8)"), button ->
                Minecraft.getInstance().setScreen(new MacroBuilderScreen()))
                .bounds(centerX + 5, top + 135, 140, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Done"), button -> onClose())
                .bounds(centerX - 145, top + 165, 290, 20).build());

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

    private void saveInterval() {
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
        int top = height / 2 - 118;
        graphics.drawCenteredString(font, title, centerX, top - 23, 0xFFFFFF);
        graphics.drawString(font, "Separate toggles, separate intervals. Both can run together.", centerX - 145, top + 86, 0xA0A0A0);
        graphics.drawCenteredString(font, "O: menu | F6: left | F7: right | F9: right profile | F10: macro", centerX, top + 201, 0xA0A0A0);
    }

    @Override
    public boolean isPauseScreen() {
        return false;
    }
}

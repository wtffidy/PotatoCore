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

    public PotatoCoreScreen() {
        super(Component.literal("PotatoCore"));
    }

    @Override
    protected void init() {
        int centerX = width / 2;
        int top = height / 2 - 90;
        addRenderableWidget(Button.builder(toggleText(), button -> {
            ClickerController.toggle();
            button.setMessage(toggleText());
        }).bounds(centerX - 100, top, 200, 20).build());
        addRenderableWidget(Button.builder(modeText(), button -> {
            ClickerController.cycleMode();
            button.setMessage(modeText());
            loadIntervalFields();
        }).bounds(centerX - 100, top + 27, 200, 20).build());

        minutesInput = new EditBox(font, centerX - 100, top + 76, 58, 20, Component.literal("Minutes"));
        secondsInput = new EditBox(font, centerX - 29, top + 76, 58, 20, Component.literal("Seconds"));
        millisecondsInput = new EditBox(font, centerX + 42, top + 76, 58, 20, Component.literal("Milliseconds"));
        minutesInput.setMaxLength(3);
        secondsInput.setMaxLength(2);
        millisecondsInput.setMaxLength(3);
        addRenderableWidget(minutesInput);
        addRenderableWidget(secondsInput);
        addRenderableWidget(millisecondsInput);

        addRenderableWidget(Button.builder(Component.literal("Save interval"), button -> saveInterval())
                .bounds(centerX - 100, top + 106, 200, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Macro Builder"), button ->
                Minecraft.getInstance().setScreen(new MacroBuilderScreen()))
                .bounds(centerX - 100, top + 136, 200, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Done"), button -> onClose())
                .bounds(centerX - 100, top + 166, 200, 20).build());
        loadIntervalFields();
    }

    private Component toggleText() {
        return Component.literal(ClickerController.isEnabled() ? "Stop clicker (F6)" : "Start clicker (F6)");
    }

    private Component modeText() {
        return Component.literal("Mode: " + ClickerController.getMode().getDisplayName() + " (F7)");
    }

    private void loadIntervalFields() {
        ClickMode mode = ClickerController.getMode();
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
        switch (ClickerController.getMode()) {
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
        int top = height / 2 - 90;
        graphics.drawCenteredString(font, title, centerX, top - 23, 0xFFFFFF);
        graphics.drawCenteredString(font, "Interval: minutes / seconds / milliseconds", centerX, top + 59, 0xA0A0A0);
        graphics.drawCenteredString(font, "O: menu  |  F6: toggle  |  F7: mode  |  F8: macros", centerX, top + 203, 0xA0A0A0);
    }

    @Override
    public boolean isPauseScreen() {
        return false;
    }
}

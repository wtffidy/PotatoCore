package com.tato.potatocore.client.gui;

import com.tato.potatocore.client.macro.BloodMagicKnifeMacro;
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

    public MacroBuilderScreen() {
        super(Component.literal("PotatoCore | Macro Builder"));
    }

    @Override
    protected void init() {
        int centerX = width / 2;
        int top = height / 2 - 112;
        addRenderableWidget(Button.builder(enabledText(), button -> {
            PotatoCoreConfig.BLOOD_MAGIC_ENABLED.set(!PotatoCoreConfig.BLOOD_MAGIC_ENABLED.get());
            button.setMessage(enabledText());
            PotatoCoreConfig.SPEC.save();
        }).bounds(centerX - 145, top, 290, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Preset: Blood Magic Sacrificial Knife"), button -> {})
                .bounds(centerX - 145, top + 28, 290, 20).build());

        itemIdInput = new EditBox(font, centerX - 145, top + 79, 290, 20,
                Component.literal("Required held item registry ID"));
        itemIdInput.setMaxLength(128);
        itemIdInput.setValue(PotatoCoreConfig.BLOOD_MAGIC_ITEM_ID.get());
        addRenderableWidget(itemIdInput);
        addRenderableWidget(Button.builder(Component.literal("Use item in main hand"), button -> {
            Minecraft minecraft = Minecraft.getInstance();
            if (minecraft.player == null || minecraft.player.getMainHandItem().isEmpty()) {
                return;
            }
            itemIdInput.setValue(ForgeRegistries.ITEMS.getKey(minecraft.player.getMainHandItem().getItem()).toString());
        }).bounds(centerX - 145, top + 105, 290, 20).build());

        stopHeartsInput = new EditBox(font, centerX - 145, top + 150, 135, 20, Component.literal("Stop at hearts"));
        stopHeartsInput.setMaxLength(2);
        stopHeartsInput.setValue(Integer.toString(PotatoCoreConfig.BLOOD_MAGIC_STOP_HEARTS.get()));
        addRenderableWidget(stopHeartsInput);
        intervalInput = new EditBox(font, centerX + 10, top + 150, 135, 20, Component.literal("Interval ms"));
        intervalInput.setMaxLength(5);
        intervalInput.setValue(Integer.toString(PotatoCoreConfig.BLOOD_MAGIC_INTERVAL_MILLISECONDS.get()));
        addRenderableWidget(intervalInput);

        addRenderableWidget(Button.builder(resumeText(), button -> {
            PotatoCoreConfig.BLOOD_MAGIC_AUTO_RESUME.set(!PotatoCoreConfig.BLOOD_MAGIC_AUTO_RESUME.get());
            button.setMessage(resumeText());
            PotatoCoreConfig.SPEC.save();
        }).bounds(centerX - 145, top + 183, 290, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Save macro settings"), button -> save())
                .bounds(centerX - 145, top + 213, 140, 20).build());
        addRenderableWidget(Button.builder(Component.literal("Back"), button ->
                Minecraft.getInstance().setScreen(new PotatoCoreScreen()))
                .bounds(centerX + 5, top + 213, 140, 20).build());
    }

    private Component enabledText() {
        return Component.literal("Blood Magic macro: " +
                (PotatoCoreConfig.BLOOD_MAGIC_ENABLED.get() ? "Enabled" : "Disabled"));
    }

    private Component resumeText() {
        return Component.literal("Auto-resume after healing: " +
                (PotatoCoreConfig.BLOOD_MAGIC_AUTO_RESUME.get() ? "On" : "Off"));
    }

    private void save() {
        PotatoCoreConfig.BLOOD_MAGIC_ITEM_ID.set(itemIdInput.getValue().trim());
        PotatoCoreConfig.BLOOD_MAGIC_STOP_HEARTS.set(parse(stopHeartsInput.getValue(), 1, 10));
        PotatoCoreConfig.BLOOD_MAGIC_INTERVAL_MILLISECONDS.set(parse(intervalInput.getValue(), 1, 60000));
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
        int top = height / 2 - 112;
        graphics.drawCenteredString(font, title, centerX, top - 23, 0xFFFFFF);
        graphics.drawString(font, "Only right-clicks while this exact item is held:", centerX - 145, top + 65, 0xA0A0A0);
        graphics.drawString(font, "Stop at hearts", centerX - 145, top + 137, 0xA0A0A0);
        graphics.drawString(font, "Click interval (ms)", centerX + 10, top + 137, 0xA0A0A0);
        graphics.drawCenteredString(font, "Status: " + BloodMagicKnifeMacro.getStatus(), centerX, top + 246, 0xA0A0A0);
        graphics.drawCenteredString(font, "Stops at or below the health threshold. One heart = 2 HP.", centerX, top + 260, 0xA0A0A0);
    }

    @Override
    public boolean isPauseScreen() {
        return false;
    }
}

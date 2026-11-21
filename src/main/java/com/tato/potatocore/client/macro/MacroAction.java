package com.tato.potatocore.client.macro;

public enum MacroAction {
    LEFT_CLICK("Left Click"),
    RIGHT_CLICK("Right Click"),
    SNEAK_RIGHT_CLICK("Sneak + Right Click");

    private final String displayName;

    MacroAction(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public MacroAction next() {
        MacroAction[] actions = values();
        return actions[(ordinal() + 1) % actions.length];
    }

    public static MacroAction fromConfig(String value) {
        try {
            return valueOf(value);
        } catch (IllegalArgumentException | NullPointerException exception) {
            return RIGHT_CLICK;
        }
    }
}

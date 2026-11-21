package com.tato.potatocore.client;

public enum ClickMode {
    LEFT("Left Click"),
    RIGHT("Right Click"),
    PEBBLES("Pebbles (Sneak + Right Click)"),
    SIEVE("Sieve (Right Click)");

    private final String displayName;

    ClickMode(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    public ClickMode next() {
        ClickMode[] modes = values();
        return modes[(ordinal() + 1) % modes.length];
    }

    public boolean usesLeftClick() {
        return this == LEFT;
    }

    public boolean usesSneak() {
        return this == PEBBLES;
    }
}

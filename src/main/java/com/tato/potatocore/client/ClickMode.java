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

    public ClickMode nextRightMode() {
        return switch (this) {
            case RIGHT -> PEBBLES;
            case PEBBLES -> SIEVE;
            case SIEVE, LEFT -> RIGHT;
        };
    }

    public boolean usesLeftClick() {
        return this == LEFT;
    }

    public boolean usesSneak() {
        return this == PEBBLES;
    }
}

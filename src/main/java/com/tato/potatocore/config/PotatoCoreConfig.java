package com.tato.potatocore.config;

import net.minecraftforge.common.ForgeConfigSpec;

public final class PotatoCoreConfig {
    public static final ForgeConfigSpec SPEC;

    public static final ForgeConfigSpec.IntValue LEFT_MINUTES;
    public static final ForgeConfigSpec.IntValue LEFT_SECONDS;
    public static final ForgeConfigSpec.IntValue LEFT_MILLISECONDS;
    public static final ForgeConfigSpec.IntValue RIGHT_MINUTES;
    public static final ForgeConfigSpec.IntValue RIGHT_SECONDS;
    public static final ForgeConfigSpec.IntValue RIGHT_MILLISECONDS;
    public static final ForgeConfigSpec.IntValue PEBBLES_MINUTES;
    public static final ForgeConfigSpec.IntValue PEBBLES_SECONDS;
    public static final ForgeConfigSpec.IntValue PEBBLES_MILLISECONDS;
    public static final ForgeConfigSpec.IntValue SIEVE_MINUTES;
    public static final ForgeConfigSpec.IntValue SIEVE_SECONDS;
    public static final ForgeConfigSpec.IntValue SIEVE_MILLISECONDS;

    public static final ForgeConfigSpec.ConfigValue<String> MACRO_ACTION;
    public static final ForgeConfigSpec.BooleanValue MACRO_REQUIRE_HELD_ITEM;
    public static final ForgeConfigSpec.ConfigValue<String> MACRO_REQUIRED_ITEM_ID;
    public static final ForgeConfigSpec.BooleanValue MACRO_HEALTH_GUARD_ENABLED;
    public static final ForgeConfigSpec.IntValue MACRO_STOP_HEARTS;
    public static final ForgeConfigSpec.IntValue MACRO_INTERVAL_MILLISECONDS;
    public static final ForgeConfigSpec.BooleanValue MACRO_AUTO_RESUME;
    public static final ForgeConfigSpec.BooleanValue AUTO_UPDATE_ENABLED;

    static {
        ForgeConfigSpec.Builder builder = new ForgeConfigSpec.Builder();

        builder.push("clicker");
        LEFT_MINUTES = builder.defineInRange("leftMinutes", 0, 0, 999);
        LEFT_SECONDS = builder.defineInRange("leftSeconds", 0, 0, 59);
        LEFT_MILLISECONDS = builder.defineInRange("leftMilliseconds", 100, 0, 999);
        RIGHT_MINUTES = builder.defineInRange("rightMinutes", 0, 0, 999);
        RIGHT_SECONDS = builder.defineInRange("rightSeconds", 0, 0, 59);
        RIGHT_MILLISECONDS = builder.defineInRange("rightMilliseconds", 250, 0, 999);
        PEBBLES_MINUTES = builder.defineInRange("pebblesMinutes", 0, 0, 999);
        PEBBLES_SECONDS = builder.defineInRange("pebblesSeconds", 0, 0, 59);
        PEBBLES_MILLISECONDS = builder.defineInRange("pebblesMilliseconds", 250, 0, 999);
        SIEVE_MINUTES = builder.defineInRange("sieveMinutes", 0, 0, 999);
        SIEVE_SECONDS = builder.defineInRange("sieveSeconds", 0, 0, 59);
        SIEVE_MILLISECONDS = builder.defineInRange("sieveMilliseconds", 250, 0, 999);
        builder.pop();

        builder.push("macroBuilder");
        MACRO_ACTION = builder.define("action", "RIGHT_CLICK");
        MACRO_REQUIRE_HELD_ITEM = builder.define("requireHeldItem", true);
        MACRO_REQUIRED_ITEM_ID = builder.define("requiredItemId", "");
        MACRO_HEALTH_GUARD_ENABLED = builder.define("healthGuardEnabled", true);
        MACRO_STOP_HEARTS = builder.defineInRange("stopAtHearts", 1, 1, 10);
        MACRO_INTERVAL_MILLISECONDS = builder.defineInRange("intervalMilliseconds", 250, 1, 60000);
        MACRO_AUTO_RESUME = builder.define("autoResumeAfterHealing", true);
        builder.pop();

        builder.push("updates");
        AUTO_UPDATE_ENABLED = builder.define("automaticUpdates", true);
        builder.pop();

        SPEC = builder.build();
    }

    private PotatoCoreConfig() {
    }
}

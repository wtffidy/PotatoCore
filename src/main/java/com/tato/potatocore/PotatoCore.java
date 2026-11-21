package com.tato.potatocore;

import com.mojang.logging.LogUtils;
import com.tato.potatocore.config.PotatoCoreConfig;
import net.minecraftforge.fml.ModLoadingContext;
import net.minecraftforge.fml.common.Mod;
import net.minecraftforge.fml.config.ModConfig;
import org.slf4j.Logger;

@Mod(PotatoCore.MOD_ID)
public final class PotatoCore {
    public static final String MOD_ID = "potato_core";
    public static final Logger LOGGER = LogUtils.getLogger();

    public PotatoCore() {
        ModLoadingContext.get().registerConfig(ModConfig.Type.CLIENT, PotatoCoreConfig.SPEC);
    }
}

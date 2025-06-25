-- config.lua

HybridConfig = {}

-- 🚗 Vehicle Definitions
HybridConfig.Vehicles = {
    [GetHashKey("slick20fpiu")] = {
        electric = "voltic",
        engine = "ecoboostv6"
    },
    -- Add more vehicles as needed
}

-- 🔋 Battery Settings
HybridConfig.Battery = {
    drainRate = 0.15,        -- While hybrid is on
    chargeRate = 0.1,        -- While driving normally
    thresholdOff = 25,       -- Force hybrid off if below
    thresholdOn = 75         -- Allow hybrid on if above
}

-- 🚦 Speed Thresholds (km/h)
HybridConfig.Speed = {
    switchToGas = 60,        -- Disable hybrid if above
    allowHybrid = 45         -- Allow hybrid if below
}

-- 🖥️ UI Settings
HybridConfig.UI = {
    toggleKey = "F7",        -- Key to toggle UI
    autoShow = true,         -- Automatically show HUD when entering hybrid
    scale = 1.0              -- Default UI scale
}

-- 🛠 Debug Mode
HybridConfig.Debug = {
    printLogs = true         -- Prints console info for debugging
}

-- 📢 Message Texts
HybridConfig.Messages = {
    hybridEnabled = "Hybrid mode ENABLED",
    hybridDisabled = "Hybrid mode DISABLED",
    uiShown = "Hybrid UI SHOWN",
    uiHidden = "Hybrid UI HIDDEN",
    mustBeDriver = "You must be the driver to do that.",
    notHybridVehicle = "This is not a hybrid vehicle.",
    creepOn = "Creep mode ENABLED",
    creepOff = "Creep mode DISABLED"
}

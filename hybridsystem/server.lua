RegisterNetEvent("hybrid:syncMode")
AddEventHandler("hybrid:syncMode", function(vehicleNetId, enable)
    TriggerClientEvent("hybrid:updateMode", -1, vehicleNetId, enable)
end)

local isUpToDate = true -- default to true
local currentVersion = "1.0.0"
local latestVersion = currentVersion -- default in case HTTP fails

local function checkVersion()
    local versionUrl = "https://raw.githubusercontent.com/Bigbrainplaz/FivemHybrid/refs/heads/main/version.txt"
    local resourceName = GetCurrentResourceName()

    PerformHttpRequest(versionUrl, function(err, text, headers)
        if not text or err ~= 200 then
            print("^1[" .. resourceName .. "] Version check failed!^0")
            isUpToDate = true -- fail open
            return
        end

        text = text:gsub("%s+", "")
        latestVersion = text

        if currentVersion ~= latestVersion then
            isUpToDate = false
            print("^3[" .. resourceName .. "] A new version is available!^0")
            print("^3[" .. resourceName .. "] Current: " .. currentVersion .. " | Latest: " .. latestVersion .. "^0")
            print("^3[" .. resourceName .. "] Get the latest version at: https://github.com/Bigbrainplaz/FivemHybrid/tree/main")
            print("^3[" .. resourceName .. "] Join this discord for support: https://discord.gg/gSmX6XEvge")

            -- Notify all players
            for _, playerId in ipairs(GetPlayers()) do
                TriggerClientEvent("hybrid:versionWarning", playerId)
            end
        else
            isUpToDate = true
            print("^2[" .. resourceName .. "] You are running the latest version.^0")
        end
    end, "GET")
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        checkVersion()
    end
end)

-- When a player joins, notify if outdated
AddEventHandler("playerConnecting", function(name, setKickReason, deferrals)
    if not isUpToDate then
        local player = source
        Wait(5000) -- give time to load

        -- Send version warning to the player
        TriggerClientEvent("hybrid:versionWarning", player)

        -- Send global chat messages to all players
        TriggerClientEvent("chat:addMessage", -1, {
            color = {255, 150, 0},
            args = {
                "[HybridSystem]",
                "⚠️ This server is running an outdated version of ^1Hybrid System^0!"
            }
        })

        TriggerClientEvent("chat:addMessage", -1, {
            color = {0, 255, 0},
            args = {
                "[HybridSystem]",
                "📦 Current Version: ^1" .. currentVersion .. "^0 | 🔄 Latest: ^2" .. latestVersion .. "^0"
            }
        })

        TriggerClientEvent("chat:addMessage", -1, {
            color = {0, 153, 255},
            args = {
                "[HybridSystem]",
                "🔗 Update: https://github.com/Bigbrainplaz/FivemHybrid/tree/main"
            }
        })

        TriggerClientEvent("chat:addMessage", -1, {
            color = {255, 102, 255},
            args = {
                "[HybridSystem]",
                "🛠️ Support: https://discord.gg/gSmX6XEvge"
            }
        })
    end
end)

-- Version request from client
RegisterNetEvent("hybrid:checkVersion")
AddEventHandler("hybrid:checkVersion", function()
    TriggerClientEvent("hybrid:versionStatus", source, isUpToDate)
end)

-- Return current version to client
RegisterNetEvent("hybrid:getVersion")
AddEventHandler("hybrid:getVersion", function()
    TriggerClientEvent("hybrid:returnVersion", source, currentVersion)
end)

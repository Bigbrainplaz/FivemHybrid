RegisterNetEvent("hybrid:syncMode")
AddEventHandler("hybrid:syncMode", function(vehicleNetId, enable)
    TriggerClientEvent("hybrid:updateMode", -1, vehicleNetId, enable)
end)

-- Version checker
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local resourceName = GetCurrentResourceName()
        local currentVersion = "1.0.0"
        local versionUrl = "https://raw.githubusercontent.com/Bigbrainplaz/FivemHybrid/refs/heads/main/version.txt" -- <- Replace this with your real link

        CreateThread(function()
            PerformHttpRequest(versionUrl, function(err, text, headers)
                if not text or err ~= 200 then
                    print("^1[" .. resourceName .. "] Version check failed!^0")
                    return
                end

                text = text:gsub("%s+", "") -- Remove any newlines/spaces

                if currentVersion ~= text then
                    print("^3[" .. resourceName .. "] A new version is available!^0")
                    print("^3[" .. resourceName .. "] Join this discord for support https://discord.gg/S6K44m7k")
                    print("^3[" .. resourceName .. "] Current: " .. currentVersion .. " | Latest: " .. text .. "^0")
                    print("^3[" .. resourceName .. "] Get the latest version at: https://github.com/Bigbrainplaz/FivemHybrid/tree/main")
                else
                    print("^2[" .. resourceName .. "] You are running the latest version.^0")
                end
            end, "GET")
        end)
    end
end)

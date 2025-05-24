RegisterNetEvent("hybrid:syncMode")
AddEventHandler("hybrid:syncMode", function(vehicleNetId, enable)
    TriggerClientEvent("hybrid:updateMode", -1, vehicleNetId, enable)
end)

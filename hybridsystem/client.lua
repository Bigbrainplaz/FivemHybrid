local hybridVehicles = {
    [`slick20fpiu`] = { electric = "voltic", engine = "ecoboostv6" }
}

local lastSound = {} 
local inHybridMode = {}
local creepMode = {}
local stoppedTimers = {}

-- Notify only the driver
local function notifyIfDriver(msg)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
        TriggerEvent('chat:addMessage', {
            color = { 0, 255, 255 },
            multiline = true,
            args = { "HybridSystem", msg }
        })
    end
end

local function stopVehicleSounds(vehicle)
    SetVehRadioStation(vehicle, "OFF")
    ForceUseAudioGameObject(vehicle, "")
end

local function applySound(vehicle, sound)
    if lastSound[vehicle] ~= sound then
        stopVehicleSounds(vehicle)
        if sound ~= "" then
            ForceUseAudioGameObject(vehicle, sound)
        end
        lastSound[vehicle] = sound
    end
end

local function setHybrid(vehicle, enable, reason, silent)
    if not DoesEntityExist(vehicle) then return end
    if inHybridMode[vehicle] == enable then return end

    inHybridMode[vehicle] = enable

    local data = hybridVehicles[GetEntityModel(vehicle)]
    if not data then return end

    if enable then
        applySound(vehicle, data.electric)
        if not silent then notifyIfDriver("Hybrid mode ENABLED (" .. reason .. ")") end
    else
        applySound(vehicle, data.engine)
        if not silent then notifyIfDriver("Hybrid mode DISABLED (" .. reason .. ")") end
    end

    if not silent then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent("hybrid:syncMode", netId, enable)
    end
end

RegisterNetEvent("hybrid:updateMode")
AddEventHandler("hybrid:updateMode", function(vehicleNetId, enable)
    local vehicle = NetToVeh(vehicleNetId)
    if vehicle then
        setHybrid(vehicle, enable, "Synced from server", true)
    end
end)

RegisterCommand("creep", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        creepMode[veh] = not creepMode[veh]
        if creepMode[veh] then
            notifyIfDriver("Creep mode ENABLED (manual toggle)")
            setHybrid(veh, true, "Creep mode enabled")
        else
            notifyIfDriver("Creep mode DISABLED (manual toggle)")
        end
    else
        notifyIfDriver("You must be in a vehicle to toggle creep mode.")
    end
end)

local lastVehicle = nil

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if lastVehicle and veh ~= lastVehicle then
            -- Player exited vehicle
            stoppedTimers[lastVehicle] = nil
            inHybridMode[lastVehicle] = nil
            creepMode[lastVehicle] = nil
            lastVehicle = nil
        end

        if veh ~= 0 and hybridVehicles[GetEntityModel(veh)] then
            local driverPed = GetPedInVehicleSeat(veh, -1)
            if driverPed == ped then
                if veh ~= lastVehicle then
                    -- Entered driver seat
                    stoppedTimers[veh] = nil
                    creepMode[veh] = false
                    lastVehicle = veh
                    -- Start immediately in hybrid mode
                    setHybrid(veh, true, "Driver entry")
                end

                local speed = GetEntitySpeed(veh) * 3.6

                if creepMode[veh] then
                    if speed >= 70 then
                        setHybrid(veh, false, "Speed over 70 km/h in creep mode")
                    elseif speed > 45 then
                        if not stoppedTimers[veh] then
                            stoppedTimers[veh] = GetGameTimer()
                        elseif GetGameTimer() - stoppedTimers[veh] > 2000 then
                            setHybrid(veh, false, "Speed over 45 km/h for 2 seconds in creep mode")
                            stoppedTimers[veh] = nil
                        end
                    else
                        stoppedTimers[veh] = nil
                        if not inHybridMode[veh] then
                            setHybrid(veh, true, "Under 45 km/h in creep mode")
                        end
                    end
                else
                    if speed >= 60 then
                        setHybrid(veh, false, "Speed over 60 km/h")
                        stoppedTimers[veh] = nil
                    elseif speed < 45 then
                        if not stoppedTimers[veh] then
                            stoppedTimers[veh] = GetGameTimer()
                        elseif GetGameTimer() - stoppedTimers[veh] > 105000 then
                            if not inHybridMode[veh] then
                                setHybrid(veh, true, "Stopped under 45 km/h for 1m45s")
                            end
                        end
                    else
                        stoppedTimers[veh] = nil
                        if speed > 30 and inHybridMode[veh] then
                            setHybrid(veh, false, "Speed over 30 km/h")
                        end
                    end
                end
            end
        else
            lastVehicle = nil
        end

        Wait(500)
    end
end)

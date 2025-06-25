local hybridVehicles = HybridConfig.Vehicles

-- Load saved settings from client storage
local storedAutoShow = GetResourceKvpString("hybrid_autoShow")
local storedScale = GetResourceKvpFloat("hybrid_scale")

HybridConfig.UI.autoShow = storedAutoShow == "true"
HybridConfig.UI.scale = storedScale > 0 and storedScale or 1.0

local lastSound = {}
local inHybridMode = {}
local creepMode = {}
local stoppedTimers = {}
local batteryLevel = {}
local uiVisible = {}
local lastUIState = {}


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
    -- implement if needed
end

local function isSirenActive(vehicle)
    local state = Entity and Entity(vehicle) and Entity(vehicle).state
    return state and state.sirenMode and state.sirenMode > 0
end

local function applySound(vehicle, sound)
    if isSirenActive(vehicle) then return end
    if lastSound[vehicle] ~= sound then
        if sound ~= "" then
            ForceUseAudioGameObject(vehicle, sound)
        end
        lastSound[vehicle] = sound
    end
end

local function updateUI(vehicle)
    if uiVisible[vehicle] then
        local batteryValue = batteryLevel[vehicle] or 100
        SendNUIMessage({
            type = "updateBattery",
            level = math.floor(batteryValue),
            hybrid = inHybridMode[vehicle] or false,
            scale = HybridConfig.UI.scale
        })
    end
end

local function showUI(vehicle, save)
    uiVisible[vehicle] = true

    -- Pull saved position
    local posX = GetResourceKvpFloat("hybrid_ui_x") or 0.85
    local posY = GetResourceKvpFloat("hybrid_ui_y") or 0.85

    SendNUIMessage({
        type = "showUI",
        level = math.floor(batteryLevel[vehicle] or 100),
        hybrid = inHybridMode[vehicle] or false,
        scale = HybridConfig.UI.scale,
        position = { x = posX, y = posY }
    })

    if save then
        SetResourceKvp("hybrid_lastUI", "true")
    end
end



local function hideUI(vehicle, save)
    uiVisible[vehicle] = false
    SendNUIMessage({ type = "hideUI" })

    if save then
        SetResourceKvp("hybrid_lastUI", "false")
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
    if not silent then notifyIfDriver(HybridConfig.Messages.hybridEnabled .. " (" .. reason .. ")") end
else
    applySound(vehicle, data.engine)
    if not silent then notifyIfDriver(HybridConfig.Messages.hybridDisabled .. " (" .. reason .. ")") end
end

    updateUI(vehicle)

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
            notifyIfDriver(HybridConfig.Messages.creepOn .. " (manual toggle)")
            setHybrid(veh, true, "Creep mode enabled")
        else
            notifyIfDriver(HybridConfig.Messages.creepOff .. " (manual toggle)")
        end
    else
        notifyIfDriver(HybridConfig.Messages.mustBeDriver)
    end
end)

RegisterCommand("togglehybridui", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and hybridVehicles[GetEntityModel(veh)] then
        if uiVisible[veh] then
            hideUI(veh, true)
            notifyIfDriver(HybridConfig.Messages.uiHidden)
        else
            showUI(veh, true)
            notifyIfDriver(HybridConfig.Messages.uiShown)
        end
    else
        notifyIfDriver(HybridConfig.Messages.notHybridVehicle)
    end
end, false)

RegisterCommand("focus", function()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "enterFocus" })
end)

RegisterCommand("unfocus", function()
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "exitFocus" })
end)

RegisterNUICallback("setNuiFocus", function(data, cb)
    SetNuiFocus(data.focus, data.focus)
    cb("ok")
end)

RegisterNUICallback("escapePressed", function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "exitFocus" })
    cb("ok")
end)




local function flashHeadlights(vehicle, flashes, delay)
    CreateThread(function()
        if not DoesEntityExist(vehicle) then return end

        NetworkRequestControlOfEntity(vehicle)
        local timeout = GetGameTimer() + 2000 -- 2 second timeout
        while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < timeout do
            Wait(0)
        end

        if not NetworkHasControlOfEntity(vehicle) then
            print("[HybridSystem] Failed to gain network control for flashing headlights")
            return
        end

        for i = 1, flashes do
            print("[HybridSystem] Flashing headlights, cycle " .. i)
            SetVehicleLights(vehicle, 2)        -- Low beams ON
            SetVehicleFullbeam(vehicle, true)  -- High beams ON
            Wait(delay)
            SetVehicleFullbeam(vehicle, false) -- High beams OFF
            SetVehicleLights(vehicle, 0)       -- Lights OFF
            Wait(delay)
        end

        print("[HybridSystem] Turning all headlights off after flashing")
        SetVehicleFullbeam(vehicle, false)
        SetVehicleLights(vehicle, 0)
    end)
end

RegisterKeyMapping('togglehybridui', 'Toggle Hybrid UI', 'keyboard', HybridConfig.UI.toggleKey)


RegisterCommand("testflash", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        flashHeadlights(veh, 3, 250)
    else
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            args = { "System", "You must be in a vehicle to use this command." }
        })
    end
end)

local lastVehicle = nil

CreateThread(function()
    local speedThresholdOff = HybridConfig.Speed.switchToGas
    local speedThresholdOn = HybridConfig.Speed.allowHybrid
    local batteryThresholdOff = HybridConfig.Battery.thresholdOff
    local batteryThresholdOn = HybridConfig.Battery.thresholdOn

    while true do
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        -- If vehicle changes, clean up previous
        if lastVehicle and veh ~= lastVehicle then
            lastUIState[lastVehicle] = uiVisible[lastVehicle] or false
            stoppedTimers[lastVehicle] = nil
            inHybridMode[lastVehicle] = nil
            creepMode[lastVehicle] = nil
            batteryLevel[lastVehicle] = nil
            hideUI(lastVehicle)
            lastVehicle = nil
        end

        if veh ~= 0 and hybridVehicles[GetEntityModel(veh)] then
            local driverPed = GetPedInVehicleSeat(veh, -1)
            if driverPed == ped then
                SetVehicleEngineOn(veh, true, true, true)

                if veh ~= lastVehicle then
                stoppedTimers[veh] = nil
                creepMode[veh] = false
                lastVehicle = veh
                batteryLevel[veh] = batteryLevel[veh] or 100

    -- 🔥 Restore saved UI state from disk
            local storedHUD = GetResourceKvpString("hybrid_lastUI")
                lastUIState[veh] = (storedHUD == "true")

            if lastUIState[veh] then
                showUI(veh)
            else
                hideUI(veh)
        end

                setHybrid(veh, true, "Driver entry")
    end
                

                local speed = GetEntitySpeed(veh) * 3.6 -- km/h

                -- Battery logic
                if inHybridMode[veh] then
                    batteryLevel[veh] = math.max(0, batteryLevel[veh] - HybridConfig.Battery.drainRate)
                elseif speed > 5 then
                    batteryLevel[veh] = math.min(100, batteryLevel[veh] + HybridConfig.Battery.chargeRate)
                end

                -- Hybrid control logic
                if batteryLevel[veh] <= batteryThresholdOff then
                    if inHybridMode[veh] then
                        setHybrid(veh, false, "Battery below threshold")
                    end
                    stoppedTimers[veh] = nil

                elseif speed >= speedThresholdOff then
                    if inHybridMode[veh] then
                        setHybrid(veh, false, "Speed above threshold")
                        TriggerServerEvent("syncHybridState", VehToNet(veh), false) -- Sync off state
                    end
                    stoppedTimers[veh] = nil

                elseif speed < speedThresholdOn then
                    if not stoppedTimers[veh] then
                        stoppedTimers[veh] = GetGameTimer()
                    elseif GetGameTimer() - stoppedTimers[veh] > 105000 then -- 1m45s
                        if not inHybridMode[veh] and batteryLevel[veh] >= batteryThresholdOn then
                            setHybrid(veh, true, "Stopped for 1m45s with good battery")
                            TriggerServerEvent("syncHybridState", VehToNet(veh), true) -- Sync on state
                        end
                    end
                else
                    stoppedTimers[veh] = nil
                end

                updateUI(veh)
            end

        else
            if lastVehicle then
                print("[HybridSystem] Checking exit conditions for lastVehicle")

                if not DoesEntityExist(lastVehicle) then
                    print("[HybridSystem] lastVehicle does not exist anymore")
                else
                    local occupant = GetPedInVehicleSeat(lastVehicle, -1) -- Using occupant here
                    local playerPed = PlayerPedId()

                    if occupant ~= playerPed then
                        print("[HybridSystem] Player is NOT driving the vehicle - running exit logic")

                        if not NetworkHasControlOfEntity(lastVehicle) then
                            NetworkRequestControlOfEntity(lastVehicle)
                            local timeout = GetGameTimer() + 1000
                            while not NetworkHasControlOfEntity(lastVehicle) and GetGameTimer() < timeout do
                                Wait(0)
                            end
                        end

                        if NetworkHasControlOfEntity(lastVehicle) then
                            SetVehicleEngineOn(lastVehicle, true, true, true)
                            SetVehicleIsConsideredByPlayer(lastVehicle, true)
                            SetVehicleNeedsToBeHotwired(lastVehicle, false)
                            SetVehicleUndriveable(lastVehicle, false)
                            SetVehicleHasBeenOwnedByPlayer(lastVehicle, true)
                            SetEntityAsMissionEntity(lastVehicle, true, true)
                            SetVehicleAutoRepairDisabled(lastVehicle, true)

                            setHybrid(lastVehicle, true, "Driver exited")
                            TriggerServerEvent("syncHybridState", VehToNet(lastVehicle), true)

                            Wait(500)

                            flashHeadlights(lastVehicle, 3, 250) -- Flash headlights

                            local reinforceVeh = lastVehicle
                            local playerPed = PlayerPedId()
                            CreateThread(function()
                                while DoesEntityExist(reinforceVeh) do
                                    local occupant = GetPedInVehicleSeat(reinforceVeh, -1) -- Check occupant here too
                                    local px, py, pz = table.unpack(GetEntityCoords(playerPed))
                                    local vx, vy, vz = table.unpack(GetEntityCoords(reinforceVeh))
                                    local dist = #(vector3(px, py, pz) - vector3(vx, vy, vz))

                                    if occupant ~= 0 and occupant ~= -1 and occupant ~= playerPed then
                                        break
                                    end

                                    if dist > 30.0 then
                                        break
                                    end

                                    SetVehicleEngineOn(reinforceVeh, true, true, true)
                                    setHybrid(reinforceVeh, true, "Reinforce after exit", true)
                                    TriggerServerEvent("syncHybridState", VehToNet(reinforceVeh), true)
                                    Wait(1000)
                                end
                            end)
                        end

                        hideUI(lastVehicle)
                        lastVehicle = nil
                    end
                end
            end
        end

        Wait(500)
    end
end)

-- New thread to clear lastVehicle every 30 minutes to avoid stale references
CreateThread(function()
    while true do
        Wait(1800000) -- 30 minutes in ms
        if lastVehicle then
            print("[HybridSystem] Clearing lastVehicle after 30 minutes timeout")
            lastVehicle = nil
        end
    end
end)

-- Client Event Handler
RegisterNetEvent("client:syncHybridState", function(netVeh, state)
    local veh = NetToVeh(netVeh)
    if DoesEntityExist(veh) then
        setHybrid(veh, state, "Synced from server", true)
    end
end)

AddStateBagChangeHandler('sirenMode', '', function(bagName, _, value)
    local vehicle = NetToVeh(tonumber(bagName:gsub('entity:', ''), 10))
    if not vehicle then return end

    if value == 0 or value == nil then
        local data = hybridVehicles[GetEntityModel(vehicle)]
        if not data then return end
        if inHybridMode[vehicle] then
            applySound(vehicle, data.electric)
        else
            applySound(vehicle, data.engine)
        end
    end
end)


RegisterNUICallback("saveSettings", function(data, cb)
    SetResourceKvp("hybrid_autoShow", tostring(data.autoShow))
    SetResourceKvpFloat("hybrid_ui_x", data.position.x)
    SetResourceKvpFloat("hybrid_ui_y", data.position.y)
    SetResourceKvpFloat("hybrid_scale", data.scale)

    HybridConfig.UI.autoShow = data.autoShow
    HybridConfig.UI.scale = data.scale

    cb("ok")
end)

RegisterNUICallback("savePosition", function(data, cb)
    if data and data.x and data.y then
        SetResourceKvpFloat("hybrid_ui_x", data.x)
        SetResourceKvpFloat("hybrid_ui_y", data.y)
        print(string.format("[HybridSystem] Saved HUD Position: x=%.2f, y=%.2f", data.x, data.y))
    end
    cb("ok")
end)

RegisterNUICallback("savePosition", function(data, cb)
    SetResourceKvpFloat("hybrid_ui_x", data.x)
    SetResourceKvpFloat("hybrid_ui_y", data.y)
    cb("ok")
end)

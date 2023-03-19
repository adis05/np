local cornerselling = false
local hasTarget = false
local startLocation = nil
local lastPed = {}
local stealingPed = nil
local stealData = {}
local availableDrugs = {}

local policeMessage = {
    "Подозрителна ситуация на ",
    "Възможни продажби на наркотици в ",
}

local CurrentCadets = 0
local CurrentCops = 0

RegisterNetEvent('nocore-police:SetCopCount')
AddEventHandler('nocore-police:SetCopCount', function(Cadets, Cops)
	CurrentCadets = Cadets
	CurrentCops = Cops
end)

RegisterCommand('corner',function()
TriggerEvent('nocore-illegal:client:toggle:corner:selling')
end)

RegisterNetEvent('nocore-illegal:client:toggle:corner:selling', function(data)
    Framework.Functions.TriggerCallback('nocore-drugs:server:cornerselling:getAvailableDrugs', function(result)
        if not delayed then
            if result ~= nil then
                availableDrugs = result
                if not cornerselling then
                    cornerselling = true
                    Framework.Functions.Notify('Хората ще дойдат при вас да си закупят наркотици.', 'success', 8000)
                    startLocation = GetEntityCoords(PlayerPedId())
                else
                    Framework.Functions.Notify('Съобщихте че се махате от локацията!')
                    endsell()
                end
            else
                Framework.Functions.Notify('Нямате наркотици във вас..', 'error')
                cornerselling = false
            end
        else
            Framework.Functions.Notify('Много бързаш..', 'error')
        end
    end)
end)

RegisterNetEvent('nocore-drugs:client:refreshAvailableDrugs', function(items)
    availableDrugs = items
    if #availableDrugs <= 0 then
        Framework.Functions.Notify('Нямате наркотици във вас..', 'error')
        cornerselling = false
        LocalPlayer.state:set("inv_busy", false, true)
    end
end)

local function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function loadAnimDict(dict)
    RequestAnimDict(dict)

    while not HasAnimDictLoaded(dict) do
        Wait(0)
    end
end



function callPolice(coords)
    local msg = policeMessage[math.random(1, #policeMessage)]
    local SendData = {
        dispatchCode = "10-31D",
        dispatchMessage = "Продажба на наркотици",
        firstStreet = GetStreetAndZone(),
        heading = getCardinalDirectionFromHeading(),
        gender = 1, -- 1 malle, 2 female
        --model = 'Car Model', -- String Car model
        -- plate = vehplate, -- String Car plate
        --firstColor = 'Red', -- String Car firstColor
       -- secondColor = 'Blue', -- String Car secondColor
       -- automaticGunfire = true, -- automaticGunfire bool
        --name = PlayerData.charinfo.firstname .. ' ' .. PlayerData.charinfo.lastname,
        --number = PlayerData.charinfo.phone,
       -- information = 'Тука седи по дългата информация за сигнала, Тука седи по дългата информация за сигнала, Тука седи по дългата информация за сигнала', -- <
        priority = 1, -- Priority
        time = 'February 18, 2022 03:24:00',
        origin = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        randomizeBlipLocation = true, -- Randomize Blip Location
        job = {"police", "swat"},
        BlipData = {
            sprite = 140,
            color = 5,
            scale = 1,
            shortrange = false,
            time = 60,
        },
        ZoneData = {
            color = 5,
            time = 60,
            radius = 150,
        }
    }
    TriggerServerEvent("erp-dispatch:sendAlert", SendData)
    hasTarget = false
    Citizen.Wait(5000)
end


function getCardinalDirectionFromHeading()
    local heading = GetEntityHeading(PlayerPedId())
    if heading >= 315 or heading < 45 then
        return "North Bound"
    elseif heading >= 45 and heading < 135 then
        return "West Bound"
    elseif heading >= 135 and heading < 225 then
        return "South Bound"
    elseif heading >= 225 and heading < 315 then
        return "East Bound"
    end
  end

function GetStreetAndZone()
    local plyPos = GetEntityCoords(PlayerPedId(),  true)
    local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
    local street1 = GetStreetNameFromHashKey(s1)
    local street2 = GetStreetNameFromHashKey(s2)
    zone = tostring(GetNameOfZone(plyPos.x, plyPos.y, plyPos.z))
    local playerStreetsLocation = GetLabelText(zone)
    local street = street1 .. ", " .. playerStreetsLocation
    return street
end

local function SellToPed(ped)
    hasTarget = true
    for i = 1, #lastPed, 1 do
        if lastPed[i] == ped then
            hasTarget = false
            return
        end
    end

    local succesChance = math.random(1, 125)

    local scamChance = math.random(1, 10)

    local getRobbed = math.random(1, 20)

    if succesChance <= 7 then
        hasTarget = false
        return
    elseif succesChance >= 115 then
        callPolice(GetEntityCoords(ped))
        return
    end

    local drugType = math.random(1, #availableDrugs)
    local bagAmount = math.random(2, 8)

    if bagAmount > 15 then
        bagAmount = math.random(2, 8)
    end
    currentOfferDrug = availableDrugs[drugType]

    local ddata = Config.DrugsPrice[currentOfferDrug.item]
    local randomPrice = math.random(ddata.min, ddata.max) * bagAmount
    if scamChance == 5 then
       randomPrice = math.random(2, 8) * bagAmount
    end

    SetEntityAsNoLongerNeeded(ped)
    ClearPedTasks(ped)

    local coords = GetEntityCoords(PlayerPedId(), true)
    local pedCoords = GetEntityCoords(ped)
    local pedDist = #(coords - pedCoords)

    if getRobbed == 18 or getRobbed == 9 then
        TaskGoStraightToCoord(ped, coords, 15.0, -1, 0.0, 0.0)
    else
        TaskGoStraightToCoord(ped, coords, 1.2, -1, 0.0, 0.0)
    end

    while pedDist > 1.5 do
        coords = GetEntityCoords(PlayerPedId(), true)
        pedCoords = GetEntityCoords(ped)
        if getRobbed == 18 or getRobbed == 9 then
            TaskGoStraightToCoord(ped, coords, 15.0, -1, 0.0, 0.0)
        else
            TaskGoStraightToCoord(ped, coords, 1.2, -1, 0.0, 0.0)
        end
        TaskGoStraightToCoord(ped, coords, 1.2, -1, 0.0, 0.0)
        pedDist = #(coords - pedCoords)

        Wait(100)
    end

    TaskLookAtEntity(ped, PlayerPedId(), 5500.0, 2048, 3)
    TaskTurnPedToFaceEntity(ped, PlayerPedId(), 5500)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT", 0, false)

    if hasTarget then
        while pedDist < 2.5 do
            coords = GetEntityCoords(PlayerPedId(), true)
            pedCoords = GetEntityCoords(ped)
            pedDist = #(coords - pedCoords)
            if getRobbed == 18 or getRobbed == 9 then
                TriggerServerEvent('nocore-drugs:server:robCornerDrugs', availableDrugs[drugType].item, bagAmount)
                Framework.Functions.Notify('Вие бяхте ограбен за '..bagAmount..' Пакет(\'s) '..availableDrugs[drugType].label, 'error')
                stealingPed = ped
                stealData = {
                    item = availableDrugs[drugType].item,
                    amount = bagAmount,
                }
                hasTarget = false
                local rand = (math.random(6,9) / 100) + 0.3
                local rand2 = (math.random(6,9) / 100) + 0.3
                if math.random(10) > 5 then
                    rand = 0.0 - rand
                end
                if math.random(10) > 5 then
                    rand2 = 0.0 - rand2
                end
                local moveto = GetEntityCoords(PlayerPedId())
                local movetoCoords = {x = moveto.x + math.random(100, 500), y = moveto.y + math.random(100, 500), z = moveto.z, }
                ClearPedTasksImmediately(ped)
                TaskGoStraightToCoord(ped, movetoCoords.x, movetoCoords.y, movetoCoords.z, 15.0, -1, 0.0, 0.0)
                lastPed[#lastPed+1] = ped
                break
            else
                if pedDist < 2.5 and cornerselling then
                    bags = bagAmount
                    drugLabel = currentOfferDrug.label
                    randomPrice = randomPrice
                    Framework.Functions.DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z, '~g~E~w~ '..bagAmount..'x '..currentOfferDrug.label..' за $'..randomPrice..'? / ~g~G~w~ Отхвърлете офертата')
                    if IsControlJustPressed(0, 38) then
                        Framework.Functions.Notify('Офертата е приета!', 'success')
                        TriggerServerEvent('nocore-drugs:server:sellCornerDrugs', availableDrugs[drugType].item, bagAmount, randomPrice)
                        hasTarget = false

                        loadAnimDict("gestures@f@standing@casual")
                        TaskPlayAnim(PlayerPedId(), "gestures@f@standing@casual", "gesture_point", 3.0, 3.0, -1, 49, 0, 0, 0, 0)
                        Wait(650)
                        ClearPedTasks(PlayerPedId())

                        SetPedKeepTask(ped, false)
                        SetEntityAsNoLongerNeeded(ped)
                        ClearPedTasksImmediately(ped)
                        lastPed[#lastPed+1] = ped
                        break
                    end

                    if IsControlJustPressed(0, 47) then
                        Framework.Functions.Notify("Отказано", 'error')
                        hasTarget = false
                        SetPedKeepTask(ped, false)
                        SetEntityAsNoLongerNeeded(ped)
                        ClearPedTasksImmediately(ped)
                        lastPed[#lastPed+1] = ped
                        break
                    end
                else
                    hasTarget = false
                    pedDist = 5
                    SetPedKeepTask(ped, false)
                    SetEntityAsNoLongerNeeded(ped)
                    ClearPedTasksImmediately(ped)
                    lastPed[#lastPed+1] = ped
                    cornerselling = false
                end
            end
            Wait(3)
        end
        Wait(math.random(500, 1000))
    end
end

CreateThread(function()
    while true do
        sleep = 1000
        if stealingPed ~= nil and stealData ~= nil then
            sleep = 0
            if IsEntityDead(stealingPed) then
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local pedpos = GetEntityCoords(stealingPed)
                if #(pos - pedpos) < 1.5 then
                    DrawText3D(pedpos.x, pedpos.y, pedpos.z, "Натисни Е")
                    if IsControlJustReleased(0, 38) then
                        RequestAnimDict("pickup_object")
                        while not HasAnimDictLoaded("pickup_object") do
                            Wait(0)
                        end
                        TaskPlayAnim(ped, "pickup_object" ,"pickup_low" ,8.0, -8.0, -1, 1, 0, false, false, false )
                        Wait(2000)
                        ClearPedTasks(ped)
                        Framework.Functions.TriggerCallback('nocore-heists:vangelico:rewardItem', function(given)
                        end, stealData.item, stealData.amount)
                        stealingPed = nil
                        stealData = {}
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        sleep = 1000
        if cornerselling then
            sleep = 0
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            if not hasTarget then
                local PlayerPeds = {}
                if next(PlayerPeds) == nil then
                    for _, player in ipairs(GetActivePlayers()) do
                        local ped = GetPlayerPed(player)
                        PlayerPeds[#PlayerPeds+1] = ped
                    end
                end
                local closestPed, closestDistance = Framework.Functions.GetClosestPed(coords, PlayerPeds)
                if closestDistance < 25.0 and closestPed ~= 0 and not IsPedInAnyVehicle(closestPed) and not IsEntityDead(closestPed) and GetPedType(closestPed) ~= 28 then
                    SellToPed(closestPed)
                end
            end
            if startLocation then
                if #(vector3(startLocation.x, startLocation.y, startLocation.z) - GetEntityCoords(PlayerPedId())) > 20.0 then
                    cornerselling = false
                    Framework.Functions.Notify('Тичахте прекалено много ...!', 'error')
                    endsell()
                end
            end
        end
        Wait(sleep)
    end
end)

function endsell()
    cornerselling = false
    hasTarget = false
    startLocation = nil
    availableDrugs = {}
    delayed = true
    Wait(60000)
    delayed = false
end
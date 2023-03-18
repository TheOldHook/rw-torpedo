local QBCore = exports['qb-core']:GetCoreObject()

local fightJob = false
local coolDown = false
local scenarioStarted = false
local blip = nil
local timerStarted = false


RegisterNUICallback("timerFinished", function(data, cb)
    timerStarted = false
    -- Handle the timer finished event
    -- This could include stopping any relevant tasks or resetting any relevant variables
    TriggerEvent("rw:client:missionFailed")
    cb("ok")
end)


-- This function triggers the NUI event to display the timer
function DisplayTimer(duration)
    timerStarted = true
    SendNUIMessage({
        type = "startTimer",
        duration = duration
    })
end

-- This function triggers the NUI event to hide the timer
function HideTimer()
    timerStarted = false
    SendNUIMessage({
        type = "hideTimer"
    })
end


RegisterCommand('stoptorpedo', function()
    fightJob = false
    coolDown = false
    RemoveBlip(blip)
    QBCore.Functions.Notify('Du har avbrutt torpedo oppdraget', 'error')
end)



RegisterNetEvent('rw:client:Calling')
AddEventHandler('rw:client:Calling', function()
    if not coolDown then
        coolDown = true
        local Player = QBCore.Functions.GetPlayerData()
        PhonePlayCall(true)
        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 4.0, "nokiaring", 0.50)
        Citizen.Wait(7000)
        TriggerEvent('rw:client:Called')
        deletePhone()
        PhonePlayOut()
    else
        exports['okokNotify']:Alert('Ny melding', 'Du må gjøre ferdig oppdraget eller vente litt før du kan ta en ny torpedo jobb..', 5000, error)
    end
end)




RegisterNetEvent('rw:client:Called')
AddEventHandler('rw:client:Called', function(data)
    local src = source
    local Player = GetPlayerPed()

    if coolDown then
        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 4.0, "nokiasms", 0.20)
        TriggerEvent("rw:client:getLocation")
        --TriggerServerEvent('qb-phone:server:sendNewMail', {
        --    sender = 'Trygve Øverdal',
        --    subject = "Torpedo arbeid",
        --    message = 'Trykk ✔ for lokasjon hvor det trengs litt vold, han skylder noe jævlig med penger..',
        --    button = {
        --        enabled = true,
        --        buttonEvent = 'rw:client:getLocation',
        --    }
        --})
        PhonePlayAnim('text')
        exports['okokNotify']:Alert('Ny melding', 'Du har fått en ny torpedo jobb! Sjekk din gps!', 5000, success)
        deletePhone()
    end
end)

RegisterNetEvent('rw:client:getLocation', function(data, source)
    Citizen.CreateThread(function()
        fightJob = true
        local source = source
        local model = Config.model[math.random(#Config.model)]
        local coords2 = Config.Coords[math.random(#Config.Coords)]
        local entityWep = Config.Weapons[math.random(#Config.Weapons)]
        local randomWep = math.random(1, 100)
        local playerId = source
        


        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end

        entity = CreatePed(0, model, coords2, true, false)
        SetModelAsNoLongerNeeded(model)
        SetPedCombatAttributes(entity, 46, true)
        SetPedCombatMovement(entity, 3)
        SetPedCombatRange(entity, 2)
        SetPedCombatAbility(entity, 100)
        SetNewWaypoint(coords2)
        SetPedMaxHealth(entity, 800)
        SetPedArmour(entity, 200)
        NetworkGetNetworkIdFromEntity(entity)
        SetPedAccuracy(entity, 100)

        -- Blip
        blip = AddBlipForCoord(coords2)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 1)


        if randomWep >= 35 then
            GiveWeaponToPed(entity, entityWep, 1, false, true)
            if GetWeapontypeGroup(entityWep) == GetWeapontypeGroup("weapon_pistol") or GetWeapontypeGroup(entityWep) == GetWeapontypeGroup("weapon_pumpshotgun") then
                -- Give some ammo to the pistol
                SetPedAmmo(entity, entityWep, 100)
                SetPedAccuracy(entity, 100)
                SetPedMaxHealth(entity, 600)
                SetPedArmour(entity, 200)
                local data = exports['ps-dispatch']:Torpedo('Voldsmøte rapportert', coords2)
            end
        end

        local randomtime = math.random(50, 250)
        if not timerStarted then
            DisplayTimer(randomtime)
        end


        -- New thread for handling combat scenarios
        Citizen.CreateThread(function()
            while true do
                local sleep = 5
                local player = PlayerPedId()
                local playerCoords = GetEntityCoords(player)
                local entityCoords = GetEntityCoords(entity)
                local distance = #(playerCoords - entityCoords)

                if distance <= 10 then
                    if not scenarioStarted then
                        DrawText3Ds(entityCoords.x, entityCoords.y, entityCoords.z, "~g~E~w~ - for å kreve inn penger")
                        if IsControlJustPressed(0, 38) then -- 'E' key
                            TaskCombatPed(entity, player, 0, 16)
                            scenarioStarted = true
                        end
                    else
                        local entityDead = IsEntityDead(entity)
                        if entityDead then
                            TriggerEvent('rw:client:missionComplete')
                        end
                    end
                else 
                    scenarioStarted = false
                    TaskWanderStandard(entity, 1.0, 1)
                end
                Citizen.Wait(sleep)
            end
        end)
    end)
end)




RegisterNetEvent('rw:client:missionFailed')
AddEventHandler('rw:client:missionFailed', function()
    -- Do whatever you need to do when the mission has failed
    -- This could include removing the entity, blip, and resetting any relevant variables
    HideTimer()
    exports['okokNotify']:Alert('Jobb ferdig', 'Du ble nok for sen denne gangen, prøv på nytt!', 5000, error)

    fightJob = false
    coolDown = false
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    
    if blip ~= nil then
        RemoveBlip(blip)
        blip = nil
    end
end)




function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local pX, pY, pZ = table.unpack(GetGameplayCamCoords())
    local scale = 0.35

    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)

        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 100)
    end
end



CreateThread(function()
    while true do 
        sleep = 100
        if fightJob then
            local player = PlayerPedId()

            if IsEntityDead(player) then
                fightJob = false
                TaskWanderStandard(entity, 10.0, 10)
                exports['okokNotify']:Alert('Fikk juling', 'Du fikk juling, kanskje du skal være mer forsiktig..', 5000, error)
                HideTimer()
                Citizen.Wait(20000) -- Cooldown på 3 minutter
                DeleteEntity(entity)
                coolDown = false
                fightJob = false
                SendNUIMessage({type = 'stopTimer'})
                if blip ~= nil then
                    RemoveBlip(blip)
                    blip = nil
                end
                break -- Exit the loop if the player is dead
            end

            local playerCoords = GetEntityCoords(player)
            local entityCoords = GetEntityCoords(entity)
            local distance = #(playerCoords - entityCoords)

            local entityDead = IsEntityDead(entity)
            local entityHealth = GetEntityHealth(entity)

            -- Rest of the code here
        end
        Citizen.Wait(sleep)
    end
end)


RegisterNetEvent('rw:client:missionComplete')
AddEventHandler('rw:client:missionComplete', function()
    HideTimer()
    if fightJob then
        fightJob = false
        coolDown = false
        exports['okokNotify']:Alert('Jobb ferdig', 'Du banket personen lett! Kanskje du kan ta en ny torpedo jobb? Ring meg!', 5000, success)
        Wait(5000)
        TriggerServerEvent('rw:server:reward')
        DeleteEntity(entity)
        -- remove the blip if it was added
        if blip ~= nil then
            RemoveBlip(blip)
            blip = nil
        end
    end
end)


-- CreateThread(function() --Brukes til å sjekke om false eller true
--     while true do
--         print('FightJob: ' .. tostring(fightJob))
--         print('CoolDown: ' .. tostring(coolDown))
--         print('Scenario): ' .. tostring(scenarioStarted))
--         Wait(1000)
--     end
-- end)
local QBCore = exports['qb-core']:GetCoreObject()

local fightJob = false
local coolDown = false


RegisterCommand('stoptorpedo', function()
    if fightJob == 1 then
        fightJob = false
        coolDown = false
        QBCore.Functions.Notify('Du har avbrutt torpedo oppdraget', 'error')
    end
end)

-- CreateThread(function() Brukes til å sjekke om false eller true
--     while true do
--         print('FightJob: ' .. tostring(fightJob))
--         print('CoolDown: ' .. tostring(coolDown))
--         Wait(1000)
--     end
-- end)

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
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender = 'Trygve Øverdal',
            subject = "Torpedo arbeid",
            message = 'Trykk ✔ for lokasjon hvor det trengs litt vold, han skylder noe jævlig med penger..',
            button = {
                enabled = true,
                buttonEvent = 'rw:client:getLocation',
            }
        })
        PhonePlayAnim('text')
        exports['okokNotify']:Alert('Ny melding', 'Sjekk din epost, ser ut som det er en ny torpedo jobb..', 5000, success)
        deletePhone()
    end
end)

RegisterNetEvent('rw:client:getLocation', function(data, whatDo)
    local src = source
    local model = Config.model[math.random(#Config.model)]
    local coords2 = Config.Coords[math.random(#Config.Coords)]
    local entityWep = Config.Weapons[math.random(#Config.Weapons)]
    local randomWep = math.random(1, 100)
    fightJob = true
    Wait(1000)
    RequestModel(model)
    while not HasModelLoaded(model) do
    Wait(1)
    end
    entity = CreatePed(0, model, coords2, true, false)
    SetModelAsNoLongerNeeded(model)
    --SetPedRelationshipGroupHash(model, `HATES_PLAYER`)
    SetPedCombatAttributes(entity, 46, true)
    SetPedCombatMovement(entity, 3)
    SetPedCombatRange(entity, 2)
    SetPedCombatAbility(entity, 100)
    SetNewWaypoint(coords2)
    SetPedMaxHealth(entity, 400)
    SetPedArmour(entity, 100)
    SetPedAccuracy(entity, 100)
    if randomWep >= 70 then
        GiveWeaponToPed(entity, entityWep, 1, false, true)
    end
end)

RegisterNetEvent('rw:client:missionComplete')
AddEventHandler('rw:client:missionComplete', function()
    if fightJob then
        fightJob = false
        coolDown = false
        exports['okokNotify']:Alert('Jobb ferdig', 'Du klarte å ta ned han, kanskje du kan ta en ny torpedo jobb..', 5000, success)
        Wait(5000)
        TriggerServerEvent('rw:server:reward')
        DeleteEntity(entity)
    end
end)



CreateThread(function()
    while true do 
        sleep = 1000
        if fightJob then
            sleep = 0
            local player = PlayerPedId()

            local playerCoords = GetEntityCoords(player)
            local entityCoords = GetEntityCoords(entity)
            local distance = #(playerCoords - entityCoords)

            local entityDead = IsEntityDead(entity)
            local playerDead = IsEntityDead(player)
            local entityHealth = GetEntityHealth(entity)

            if playerDead then 
                fightJob = false
                TaskWanderStandard(entity, 10.0, 10)
                exports['okokNotify']:Alert('Fikk juling', 'Du fikk juling, kanskje du skal være mer forsiktig (15 MIN CD)..', 5000, error)
                Citizen.Wait(900000) -- 15 min
                DeleteEntity(entity)
                coolDown = false
            end
        end
        Citizen.Wait(sleep)
    end
end)


CreateThread(function()
    while true do 
        sleep = 1000
        if fightJob then 
            sleep = 0
            local player = PlayerPedId()
            local playerCoords = GetEntityCoords(player)
            local entityCoords = GetEntityCoords(entity)
            local distance = #(playerCoords - entityCoords)
            if distance <= 10 then
                TaskCombatPed(entity, player, 0, 16)
            end
        end
        Citizen.Wait(sleep)
    end
end)

CreateThread(function()
    while true do 
        sleep = 1000
        if fightJob then 
            local player = PlayerPedId()

            local playerCoords = GetEntityCoords(player)
            local entityCoords = GetEntityCoords(entity)
            local distance = #(playerCoords - entityCoords)

            local entityDead = IsEntityDead(entity)
            local playerDead = IsEntityDead(player)
            local entityHealth = GetEntityHealth(entity)

            if entityDead then
                if distance <= 15 then
                    TriggerEvent('rw:client:missionComplete')
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)



-- local function doCooldown()
--     if not fightJob then
--         fightJob = 1
--         coolDown = 1
--         local cdTimer = 10
--         CreateThread(function()
--             while onCooldown do
--                 Wait(10000)
--                 cdTimer = cdTimer - 10000
--                 if cdTimer <= 0 then
--                     fightJob = 0
--                     coolDown = 0
--                 end
--             end
--         end)
--     end
-- end

local QBCore = exports['qb-core']:GetCoreObject()


---- KUN FOR UTVIKLING
-- RegisterCommand("torpedo", function(source, args, rawCommand)
--     local src = source
--     local Player = QBCore.Functions.GetPlayer(src)
--     if source > 0 then
--         print("Torpedo")
--         TriggerClientEvent('phonenumber:client:Called', src)
--     else
--         print("Torpedo")
--     end
-- end)



QBCore.Functions.CreateUseableItem("burnertelefon", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
	if Player.Functions.GetItemBySlot(item.slot) ~= nil then
        TriggerClientEvent("rw:client:Calling", source)
    end
end)



RegisterNetEvent('rw:server:reward')
AddEventHandler('rw:server:reward', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local reward = math.random(300, 1000)
    Player.Functions.AddItem('svartepenger', reward)
    TriggerClientEvent('inventory:client:ItemBox', src, 'svartepenger', 'add', reward)
    TriggerClientEvent('XNL_NET:AddPlayerXP', source, 100)
    TriggerClientEvent('okokNotify:Alert', src, 'Torpedo Oppdrag Fullført', 'Du fikk betaling for jobben', 1000, 'success')
end)


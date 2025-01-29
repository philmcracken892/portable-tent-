local RSGCore = exports['rsg-core']:GetCoreObject()

-- Tent item setup
RSGCore.Functions.CreateUseableItem("tent", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    TriggerClientEvent('rsg-tents:client:openTentMenu', source)
    -- RemoveItem should be triggered after successful tent placement
end)

-- Return tent to inventory
RegisterNetEvent('rsg-tents:server:returnTent', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    Player.Functions.AddItem("tent", 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items["tent"], "add")
end)

RegisterNetEvent('rsg-tents:server:placeTent', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    Player.Functions.RemoveItem("tent", 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items["tent"], "remove")
end)








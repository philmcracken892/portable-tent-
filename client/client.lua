local RSGCore = exports['rsg-core']:GetCoreObject()

local CHECK_RADIUS = 2.0
local TENT_PROPS = {
    {
        label = "Small Tent",
        model = `p_amb_tent03x`,
        offset = vector3(0.0, 0.0, 0.0),
        description = "A compact tent perfect for solo camping"
    },
    {
        label = "Medium wooden shelter",
        model = `p_tentmexican01x`,
        offset = vector3(0.0, 0.0, 0.0),
        description = "A sturdy wooden tent with good protection"
    },
    {
        label = "Large Wilderness Tent",
        model = `s_tentcaravan01x`,
        offset = vector3(0.0, 0.0, 0.0),
        description = "A spacious tent for comfortable camping"
    },
    {
        label = "Military Tent",
        model = `s_tentdoctor01x`,
        offset = vector3(0.0, 0.0, 0.0),
        description = "A durable military-style tent"
    }
}

-- Variables
local deployedTent = nil
local deployedOwner = nil
local currentTentData = nil
local isResting = false

local function ShowTentMenu()
    local tentOptions = {}
    
    for i, tent in ipairs(TENT_PROPS) do
        table.insert(tentOptions, {
            title = tent.label,
            description = tent.description,
            icon = 'fas fa-campground',
            onSelect = function()
                TriggerEvent('rsg-tents:client:placeTent', i)
            end
        })
    end

    lib.registerContext({
        id = 'tent_selection_menu',
        title = 'Select Tent Style',
        options = tentOptions
    })
    
    lib.showContext('tent_selection_menu')
end

local function RegisterTentTargeting()
    local models = {}
    for _, tent in ipairs(TENT_PROPS) do
        table.insert(models, tent.model)
    end

    exports['ox_target']:addModel(models, {
        {
            name = 'pickup_tent',
            event = 'rsg-tents:client:pickupTent',
            icon = "fas fa-hand",
            label = "Pack Up Tent",
            distance = 2.0,
            canInteract = function(entity)
                return not isResting
            end
        },
        {
            name = 'rest_at_tent',
            event = 'rsg-tents:client:restAtTent',
            icon = "fas fa-bed",
            label = "Rest",
            distance = 2.0,
            canInteract = function(entity)
                return not isResting
            end
        }
    })
end

RegisterNetEvent('rsg-tents:client:placeTent', function(tentIndex)
    if deployedTent then
        lib.notify({
            title = "Tent Already Placed",
            description = "You already have a tent placed.",
            type = 'error'
        })
        return
    end

    local tentData = TENT_PROPS[tentIndex]
    if not tentData then return end

    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    local forward = GetEntityForwardVector(PlayerPedId())
    
    local offsetDistance = 2.0
    local x = coords.x + forward.x * offsetDistance
    local y = coords.y + forward.y * offsetDistance
    local z = coords.z

    RequestModel(tentData.model)
    while not HasModelLoaded(tentData.model) do
        Wait(100)
    end

    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
    Wait(2000)
    
    local tentObject = CreateObject(tentData.model, x, y, z, true, false, false)
    PlaceObjectOnGroundProperly(tentObject)
    SetEntityHeading(tentObject, heading)
    FreezeEntityPosition(tentObject, true)
    
    deployedTent = tentObject
    currentTentData = tentData
    deployedOwner = GetPlayerServerId(PlayerId())
    
    TriggerServerEvent('rsg-tents:server:placeTent')
    
    Wait(500)
    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent('rsg-tents:client:pickupTent', function()
    if not deployedTent then
        lib.notify({
            title = "No Tent!",
            description = "There's no tent to pack up.",
            type = 'error'
        })
        return
    end

    if isResting then
        lib.notify({
            title = "Cannot Pack Up",
            description = "You can't pack up the tent while resting.",
            type = 'error'
        })
        return
    end

    local ped = PlayerPedId()
    
    LocalPlayer.state:set('inv_busy', true, true)
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
    Wait(2000)

    if deployedTent then
        DeleteObject(deployedTent)
        deployedTent = nil
        currentTentData = nil
        TriggerServerEvent('rsg-tents:server:returnTent')
        deployedOwner = nil
    end

    ClearPedTasks(ped)
    LocalPlayer.state:set('inv_busy', false, true)

    lib.notify({
        title = 'Tent Packed',
        description = 'You have packed up your tent.',
        type = 'success'
    })
end)

RegisterNetEvent('rsg-tents:client:restAtTent', function()
    if isResting then return end
    
    isResting = true
    LocalPlayer.state:set('inv_busy', true, true)
    
    TaskStartScenarioInPlace(PlayerPedId(), GetHashKey('WORLD_HUMAN_SLEEP_GROUND_ARM'), -1, true, false, false, false)
    Wait(10000) -- Rest duration
    
    ClearPedTasks(PlayerPedId())
    isResting = false
    LocalPlayer.state:set('inv_busy', false, true)
    
    -- Trigger stress relief directly
    TriggerServerEvent('hud:server:RelieveStress', 20) -- Relieve 20 stress points
    
    lib.notify({
        title = 'Well Rested',
        description = 'You feel refreshed from resting',
        type = 'success'
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if deployedTent then
        DeleteObject(deployedTent)
    end
end)

CreateThread(function()
    RegisterTentTargeting()
end)

RegisterNetEvent('rsg-tents:client:openTentMenu', function()
    ShowTentMenu()
end)
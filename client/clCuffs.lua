--[[ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)]]--
ESX = exports["base"]:getSharedObject()

function KeyboardInput(textEntry, exampleText, maxStringLength)
    AddTextEntry('FMMC_KEY_TIP1', textEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", exampleText, "", "", "", maxStringLength)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Citizen.Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        return GetOnscreenKeyboardResult()
    else
        return nil
    end
end

local function isJobAuthorized()
    local playerJob = ESX.GetPlayerData().job.name
    for _, job in pairs(Config.AuthorizedJobs) do
        if playerJob == job then
            return true
        end
    end
    return false
end

if Config.Marker then
    Citizen.CreateThread(function()
        while true do
            local wait = 1000
            for k in pairs(Config.Position) do
                
                local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
                local pos = Config.Position
                local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, pos[k].x, pos[k].y, pos[k].z)
                if dist <= 1.0 then
                    wait = 0
                        ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour intéragir")
                        if IsControlJustPressed(1,51) then
                            OpenHandMenu()
                        end
                    end
                end
            Citizen.Wait(wait)
        end
    end)
end

RegisterNetEvent('applyCuffs')
AddEventHandler('applyCuffs', function(position, time)
    isCuffed = true
    local animDict, animName

    if position == "back" then
        animDict = 'mp_arresting'
        animName = 'idle'
    elseif position == "front" then
        animDict = 'anim@heists@ornate_bank@hostages@cashier_b@'
        animName = 'flinch_loop_underfire'
    end

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)

    if time and time > 0 then
        Citizen.Wait(time * 60000)
        TriggerServerEvent('uncuffPlayer', GetPlayerServerId(PlayerId()))
    end
end)

RegisterNetEvent('uncuff')
AddEventHandler('uncuff', function()
    isCuffed = false
    ClearPedTasksImmediately(PlayerPedId())
    ESX.ShowNotification("~g~Vous avez été libéré.")
    cuffTimer = 0
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isCuffed then
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 288, true)
            DisableControlAction(0, 289, true)
            DisableControlAction(0, 170, true)
            DisableControlAction(0, 167, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(27, 75, true)
        end
    end
end)

if not Config.Marker then
    RegisterCommand("handcuffs", function()
        if isJobAuthorized() then
            OpenHandMenu()
        end
    end, false)
end

local isCuffed = false
local cuffTimer = 0

OpenHandMenu = function()
    local maincuff = RageUI.CreateMenu("Menottes", "Interaction") 
    local cuffTimerMenu = RageUI.CreateSubMenu(maincuff, "Menottes", "Définir le temps")
    
    RageUI.Visible(maincuff, true)
    
    Citizen.CreateThread(function()
        while RageUI.Visible(maincuff) do 
            Wait(0)
            RageUI.IsVisible(maincuff, function()
                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                RageUI.Button("Mettre les menottes (Dos)", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('cuffPlayer', GetPlayerServerId(closestPlayer), "back")
                    end
                })

                RageUI.Button("Mettre les menottes (Devant)", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('cuffPlayer', GetPlayerServerId(closestPlayer), "front")
                    end
                })

                RageUI.Button("Retirer les menottes", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent('uncuffPlayer', GetPlayerServerId(closestPlayer))
                    end
                })
                RageUI.Separator()
                RageUI.Button("Menottes avec Temps", nil, {RightLabel = '→→'}, true, {}, cuffTimerMenu)
            else
                RageUI.Button("Aucun joueur à proximité", nil, {}, false, {})
            end
            end)
            
            RageUI.IsVisible(cuffTimerMenu, function()
                RageUI.Button("1 Minute", nil, {}, true, {
                    onSelected = function()
                        cuffTimer = 1
                        TriggerServerEvent('cuffPlayer', GetPlayerServerId(closestPlayer), "back", cuffTimer)
                    end
                })

                RageUI.Button("5 Minutes", nil, {}, true, {
                    onSelected = function()
                        cuffTimer = 5
                        TriggerServerEvent('cuffPlayer', GetPlayerServerId(closestPlayer), "back", cuffTimer)
                    end
                })

                RageUI.Button("10 Minutes", nil, {}, true, {
                    onSelected = function()
                        cuffTimer = 10
                        TriggerServerEvent('cuffPlayer', GetPlayerServerId(closestPlayer), "back", cuffTimer)
                    end
                })

                RageUI.Button("15 Minutes", nil, {}, true, {
                    onSelected = function()
                        cuffTimer = 15
                        TriggerServerEvent('cuffPlayer', GetPlayerServerId(closestPlayer), "back", cuffTimer)
                    end
                })
            end)

            if not RageUI.Visible(maincuff) and not RageUI.Visible(cuffTimerMenu) then
                maincuff = RMenu:DeleteType('maincuff')
            end
        end
    end)
end

AddEventHandler('playerSpawned', function()
    TriggerServerEvent('checkCuffedStatus')
end)

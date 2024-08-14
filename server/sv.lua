--ESX = nil
--TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX = exports["base"]:getSharedObject()

local function isJobAuthorized(xPlayer)
    local playerJob = xPlayer.getJob().name
    for _, job in pairs(Config.AuthorizedJobs) do
        if playerJob == job then
            return true
        end
    end
    return false
end

RegisterServerEvent('cuffPlayer')
AddEventHandler('cuffPlayer', function(targetId, position, time)
    local xPlayer = ESX.GetPlayerFromId(source)
    if isJobAuthorized(xPlayer) then
        local xTarget = ESX.GetPlayerFromId(targetId)
        if xTarget then
            local cuffEndTime = os.time() + (time * 60)

            MySQL.Async.execute('INSERT INTO user_cuffs (identifier, position, cuff_end_time) VALUES (@identifier, @position, @cuff_end_time) ON DUPLICATE KEY UPDATE position = @position, cuff_end_time = @cuff_end_time', {
                ['@identifier'] = xTarget.identifier,
                ['@position'] = position,
                ['@cuff_end_time'] = cuffEndTime
            })
            TriggerClientEvent('applyCuffs', xTarget.source, position, time)
        end
    else
        DropPlayer(source, "Trigger")
    end
end)

RegisterServerEvent('uncuffPlayer')
AddEventHandler('uncuffPlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if isJobAuthorized(xPlayer) then
        local xTarget = ESX.GetPlayerFromId(targetId)
        if xTarget then
            MySQL.Async.execute('DELETE FROM user_cuffs WHERE identifier = @identifier', {
                ['@identifier'] = xTarget.identifier
            })
            TriggerClientEvent('uncuff', xTarget.source)
        end
    else
        DropPlayer(source, "Trigger")
    end
end)

RegisterServerEvent('checkCuffedStatus')
AddEventHandler('checkCuffedStatus', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT position, cuff_end_time FROM user_cuffs WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] then
            local position = result[1].position
            local cuffEndTime = tonumber(result[1].cuff_end_time)
            local currentTime = os.time()

            if cuffEndTime > currentTime then
                local remainingTime = math.ceil((cuffEndTime - currentTime) / 60)
                TriggerClientEvent('applyCuffs', xPlayer.source, position, remainingTime)
            else
                MySQL.Async.execute('DELETE FROM user_cuffs WHERE identifier = @identifier', {
                    ['@identifier'] = xPlayer.identifier
                })
                TriggerClientEvent('uncuff', xPlayer.source)
            end
        end
    end)
end)

function GetPlayerFromSource(source)
    if Config.Framework == "QBCore" then
        return QBCore.Functions.GetPlayer(source)
    end
    return nil
end

function AddMoney(player, amount, moneyType)
    if Config.Framework == "QBCore" then
        if moneyType == "cash" then
            player.Functions.AddMoney("cash", amount, "train-job-payment")
        elseif moneyType == "bank" then
            player.Functions.AddMoney("bank", amount, "train-job-payment")
        end
    end
end

function NotifyPlayer(source, message, type)
    if Config.Framework == "QBCore" then
        TriggerClientEvent('QBCore:Notify', source, message, type or "primary")
    end
end

function IsTrainDriver(source)
    if Config.Framework == "QBCore" then
        local player = GetPlayerFromSource(source)
        if player then
            return player.PlayerData.job.name == Config.Job.name
        end
    end
    return false
end

function IsOnDuty(source)
    if Config.Framework == "QBCore" then
        local player = GetPlayerFromSource(source)
        if player then
            return player.PlayerData.job.onduty
        end
    end
    return true
end

function Log(message, level)
    level = level or "info"
    print(string.format("[qbx_trainjob] [%s] %s", level:upper(), message))
end
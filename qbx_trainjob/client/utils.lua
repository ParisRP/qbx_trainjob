QBCore = nil
local PlayerData = {}

if Config.Framework == "QBCore" then
    QBCore = exports["qb-core"]:GetCoreObject()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    PlayerData.job = jobInfo
end)

function IsTrainDriver()
    return PlayerData.job and PlayerData.job.name == Config.Job.name
end

function IsOnDuty()
    return PlayerData.job and PlayerData.job.onduty
end

function showHelpNotification(text)
    if Config.Framework == "QBCore" then
        QBCore.Functions.Notify(text, "primary", 3000)
    end
end

function hideHelpNotification()
end

function startProgress(duration, text)
    if Config.Framework == "QBCore" then
        QBCore.Functions.Progressbar("train_wait", text, duration * 1000, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
        end)
    else
        showProgress(text, duration)
    end
end

function notify(text, type)
    if Config.Framework == "QBCore" then
        QBCore.Functions.Notify(text, type)
    end
end

function addTarget(entity, name, mode)
    if Config.TargetSystem then
        exports['ox_target']:AddTargetEntity(entity, {
            options = {
                {
                    type = "client",
                    event = "qbx_trainjob:client:startJob",
                    icon = "fas fa-train",
                    label = "Start " .. mode:upper() .. " Job",
                    job = Config.Job.name,
                    mode = mode
                }
            },
            distance = 2.5
        })
    end
end

function removeTarget(entity, name)
    if Config.TargetSystem then
        exports['ox_target']:RemoveTargetEntity(entity, name)
    end
end

function DrawMissionText(msg, time)
    ClearPrints()
    BeginTextCommandPrint('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandPrint(time, true)
end

function showProgress(text, duration)
    if not text or not duration then return end

    Citizen.CreateThread(function()
        for i = 0, duration do
            Citizen.Wait(1000)
            DrawMissionText(text .. " ~r~(" .. (duration - i) .. "s)~s~", 1000)
        end
    end)
end

function setTrainCollision(train, enabled)
    if not DoesEntityExist(train) then return end
    
    -- Désactiver les collisions pour le train et tous ses wagons
    SetEntityCollision(train, enabled, enabled)
    
    for i = 1, 10 do -- Vérifier jusqu'à 10 wagons
        local carriage = GetTrainCarriage(train, i)
        if carriage and DoesEntityExist(carriage) then
            SetEntityCollision(carriage, enabled, enabled)
        else
            break
        end
    end
end

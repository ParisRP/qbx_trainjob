local WEBHOOK_URL = ""
local activeJobs = {}

local function CheckJobAuthorization(source)
    if not IsTrainDriver(source) then
        NotifyPlayer(source, Config.Language.not_train_driver, "error")
        return false
    end
    
    if not IsOnDuty(source) then
        NotifyPlayer(source, Config.Language.on_duty_only, "error")
        return false
    end
    
    return true
end

local function SendWebhook(title, description, color)
    if WEBHOOK_URL == "" or WEBHOOK_URL == nil then return end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = color or 3066993,
            ["footer"] = {
                ["text"] = "QBX TrainJob",
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }
    
    PerformHttpRequest(WEBHOOK_URL, function(err, text, headers) end, 'POST', json.encode({
        username = "QBX TrainJob",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent("qbx_trainjob:server:initiateJob", function()
    local source = source
    if not CheckJobAuthorization(source) then return end
end)

RegisterNetEvent("qbx_trainjob:server:createTrain", function(trainNetworkIds)
    local source = source
    if not CheckJobAuthorization(source) then return end
end)

RegisterNetEvent("qbx_trainjob:server:completeStation", function(mode)
    local source = source
    if not CheckJobAuthorization(source) then return end
    
    local player = GetPlayerFromSource(source)
    if not player then return end

    if not activeJobs[source] then
        activeJobs[source] = {
            mode = mode,
            stationsCompleted = 0,
            startTime = os.time()
        }
    end
    
    activeJobs[source].stationsCompleted = activeJobs[source].stationsCompleted + 1
    
    local rewardConfig = Config.Rewards[mode]
    if rewardConfig then
        local stationReward = math.random(rewardConfig.min, rewardConfig.max)
        AddMoney(player, stationReward, "cash")
        NotifyPlayer(source, string.format(Config.Language.station_complete, stationReward), "success")
    end
end)

RegisterNetEvent("qbx_trainjob:server:completeLine", function(mode, completed)
    local source = source
    if not CheckJobAuthorization(source) then return end
    
    local player = GetPlayerFromSource(source)
    if not player then return end

    local jobData = activeJobs[source]
    
    if not jobData then
        jobData = {
            mode = mode,
            stationsCompleted = 0,
            startTime = os.time()
        }
    end
    
    local rewardConfig = Config.Rewards[mode]
    
    if completed then
        local bonusAmount = 0
        if rewardConfig and jobData.stationsCompleted > 0 then
            bonusAmount = rewardConfig.bonus * jobData.stationsCompleted
        end
        
        if bonusAmount > 0 then
            AddMoney(player, bonusAmount, "cash")
            NotifyPlayer(source, string.format(Config.Language.job_complete_bonus, bonusAmount), "success")
        else
            NotifyPlayer(source, Config.Language.job_ended, "success")
        end
        
        local totalTime = os.time() - jobData.startTime
        local minutes = math.floor(totalTime / 60)
        local seconds = totalTime % 60
        
        if WEBHOOK_URL ~= "" and WEBHOOK_URL ~= nil then
            local Player = QBCore.Functions.GetPlayer(source)
            SendWebhook(
                "Train Line Completed",
                string.format(
                    "**Driver:** %s %s\n**Employee ID:** %s\n**Line:** %s\n**Stations:** %d\n**Duration:** %dm %ds\n**Bonus:** $%d",
                    Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname,
                    Player.PlayerData.citizenid, mode, jobData.stationsCompleted, minutes, seconds, bonusAmount
                ),
                3066993
            )
        end
    else
        NotifyPlayer(source, "Job cancelled", "info")
    end
    
    activeJobs[source] = nil
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    if activeJobs[source] then
        activeJobs[source] = nil
    end
end)

RegisterCommand("resettrainjob", function(source, args, rawCommand)
    local player = GetPlayerFromSource(source)
    if not player then return end
    
    local isAdmin = false
    if Config.Framework == "QBCore" then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            isAdmin = QBCore.Functions.HasPermission(source, "admin")
        end
    end
    
    if isAdmin then
        if args[1] then
            local targetSource = tonumber(args[1])
            if activeJobs[targetSource] then
                activeJobs[targetSource] = nil
                NotifyPlayer(source, string.format("Player %s's train job reset", targetSource), "success")
                NotifyPlayer(targetSource, "Your train job was reset by admin", "info")
            else
                NotifyPlayer(source, "No active train job for this player", "error")
            end
        else
            if activeJobs[source] then
                activeJobs[source] = nil
                NotifyPlayer(source, "Your train job has been reset", "success")
            end
        end
    else
        NotifyPlayer(source, "Insufficient permissions", "error")
    end
end, false)

RegisterCommand("trainjobstatus", function(source, args, rawCommand)
    local source = source
    local jobData = activeJobs[source]
    
    if jobData then
        local timeElapsed = os.time() - jobData.startTime
        local minutes = math.floor(timeElapsed / 60)
        local seconds = timeElapsed % 60
        
        NotifyPlayer(source, string.format(
            "Active Job: %s | Stations: %d | Time: %dm %ds",
            jobData.mode, jobData.stationsCompleted, minutes, seconds
        ), "info")
    else
        NotifyPlayer(source, "No active train job", "info")
    end
end, false)

exports('GetPlayerJobData', function(source)
    return activeJobs[source]
end)

exports('ResetPlayerJob', function(source)
    if activeJobs[source] then
        activeJobs[source] = nil
        return true
    end
    return false
end)

print("^2[qbx_trainjob]^0 Server script loaded successfully")
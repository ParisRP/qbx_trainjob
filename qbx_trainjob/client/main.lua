local spawnedNPCs = {}
local currentTrainJob = nil
local helpNotificationShown = {}
local lastJobStartTime = 0
local PlayerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(jobInfo)
    PlayerData.job = jobInfo
end)

local function preloadTrainModels()
    local trainModels = {
        "freight",
        "metrotrain",
        "freightcont1",
        "freightcar",
        "freightcar2",
        "freightcont2",
        "tankercar",
        "freightgrain"
    }
    
    for _, modelName in ipairs(trainModels) do
        local modelHash = GetHashKey(modelName)
        RequestModel(modelHash)
        
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(500)
        end
    end
end

preloadTrainModels()

local function manageNPC(mode, distance)
    if distance < 200.0 then
        if spawnedNPCs[mode] then return end
        
        local npcConfig = Config.Positions[mode].NPC
        local npcCoords = npcConfig.coords
        local npcHeading = npcConfig.heading
        local npcModel = GetHashKey(npcConfig.model)
        
        RequestModel(npcModel)
        while not HasModelLoaded(npcModel) do
            Citizen.Wait(500)
        end
        
        spawnedNPCs[mode] = CreatePed(4, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1.0, npcHeading, false, false)
        
        SetEntityInvincible(spawnedNPCs[mode], true)
        SetEntityAsMissionEntity(spawnedNPCs[mode], true, true)
        FreezeEntityPosition(spawnedNPCs[mode], true)
        SetBlockingOfNonTemporaryEvents(spawnedNPCs[mode], true)
        SetPedFleeAttributes(spawnedNPCs[mode], 0, 0)
        
        if Config.TargetSystem then
            addTarget(spawnedNPCs[mode], "qbx_trainjob_" .. mode, mode)
        end
    else
        if not spawnedNPCs[mode] then return end
        
        if spawnedNPCs[mode] then
            if Config.TargetSystem then
                removeTarget(spawnedNPCs[mode], "qbx_trainjob_" .. mode)
            end
            SetEntityAsMissionEntity(spawnedNPCs[mode], false, false)
            DeleteEntity(spawnedNPCs[mode])
            spawnedNPCs[mode] = nil
        end
    end
end

Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(500)
    end
    SetTrainsForceDoorsOpen(false)
end)

Citizen.CreateThread(function()
    for mode, position in pairs(Config.Positions) do
        local blip = AddBlipForCoord(position.NPC.coords)
        
        SetBlipSprite(blip, Config.Blips[mode] and Config.Blips[mode].sprite or 795)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips[mode] and Config.Blips[mode].scale or 0.8)
        SetBlipColour(blip, Config.Blips[mode] and Config.Blips[mode].color or 5)
        SetBlipAsShortRange(blip, true)
        
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.Blips[mode] and Config.Blips[mode].name or "Train Depot")
        EndTextCommandSetBlipName(blip)
    end
end)

local function createTrainJob(mode)
    local jobData = {}
    
    jobData.startTime = GetCloudTimeAsInt()
    jobData.mode = mode
    jobData.startPos = Config.Positions[mode].coords
    jobData.railPos = Config.Positions[mode].railPos
    
    local trainVariations = Config.Trains[mode].variations
    local randomVariation = trainVariations[math.random(1, #trainVariations)]
    jobData.trainVariation = randomVariation
    
    jobData.train = CreateMissionTrain(
        jobData.trainVariation,
        jobData.railPos.x,
        jobData.railPos.y,
        jobData.railPos.z,
        Config.Positions[mode].direction,
        true,
        true
    )
    
    SetTrainSpeed(jobData.train, 0)
    SetTrainCruiseSpeed(jobData.train, 0)
    SetEntityAsMissionEntity(jobData.train, true, false)
    SetTrainState(jobData.train, 0)
    SetVehicleFuelLevel(jobData.train, 100.0)
    DecorSetFloat(jobData.train, "_FUEL_LEVEL", GetVehicleFuelLevel(jobData.train))
    
    Citizen.SetTimeout(2000, function()
        if DoesEntityExist(jobData.train) then
            setTrainCollision(jobData.train, true)
        end
    end)

    local trainNetworkIds = {}
    for i = 1, 6 do
        local carriage = GetTrainCarriage(jobData.train, i)
        if carriage and DoesEntityExist(carriage) then
            NetworkRegisterEntityAsNetworked(carriage)
            pcall(function()
                SetNetworkVehicleAsGhost(carriage, true)
            end)
            Wait(0)
            if DoesEntityExist(carriage) then
                local networkId = NetworkGetNetworkIdFromEntity(carriage)
                if networkId and networkId ~= 0 then
                    table.insert(trainNetworkIds, networkId)
                end
            end
        end
    end
    
    if DoesEntityExist(jobData.train) then
        Wait(0)
        if DoesEntityExist(jobData.train) then
            local trainNetworkId = NetworkGetNetworkIdFromEntity(jobData.train)
            if trainNetworkId and trainNetworkId ~= 0 then
                table.insert(trainNetworkIds, trainNetworkId)
            end
        end
    end
    
    TriggerServerEvent("qbx_trainjob:server:createTrain", trainNetworkIds)
    TriggerEvent('vehiclekeys:client:SetOwner', jobData.train)
    
    jobData.maxSpeed = math.floor(Config.Trains[mode].maxSpeed / 3.6)
    jobData.emergencyBrake = false
    jobData.isInsideTrain = false
    jobData.isDoorOpen = false
    jobData.speed = 0
    jobData.currentStation = 1
    jobData.isStopping = false
    jobData.cam = nil
    
    function jobData.enterTrain()
        local playerPed = PlayerPedId()
        TaskWarpPedIntoVehicle(playerPed, jobData.train, -1)
        jobData.isInsideTrain = true
        notify(Config.Language.job_started, "primary")
    end
    
    function jobData.toggleCamera()
        if jobData.cam then
            DestroyAllCams(true)
            RenderScriptCams(false, false, 0, true, true)
            SetFollowPedCamViewMode(1)
            jobData.cam = nil
        else
            jobData.cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            SetCamActive(jobData.cam, true)
            RenderScriptCams(true, false, 0, true, true)
        end
    end
    
    function jobData.setMaxSpeed(newMaxSpeed)
        if newMaxSpeed then
            jobData.maxSpeed = math.floor(newMaxSpeed / 3.6)
            if jobData.speed > jobData.maxSpeed then
                jobData.speed = jobData.maxSpeed
                SetTrainCruiseSpeed(jobData.train, jobData.speed)
            end
        else
            jobData.maxSpeed = math.floor(Config.Trains[mode].maxSpeed / 3.6)
        end
    end
    
    function jobData.increaseSpeed()
        if jobData.isDoorOpen or jobData.emergencyBrake or jobData.isStopping then return end
        
        local speedRatio = jobData.speed / jobData.maxSpeed
        local acceleration = 0.2 * (1 - speedRatio)
        jobData.speed = jobData.speed + acceleration
        
        if jobData.speed > jobData.maxSpeed then
            jobData.speed = jobData.maxSpeed
        end
        
        SetTrainCruiseSpeed(jobData.train, jobData.speed)
    end
    
    function jobData.decreaseSpeed()
        if jobData.isDoorOpen or jobData.emergencyBrake or jobData.isStopping then return end
        
        local speedRatio = jobData.speed / jobData.maxSpeed
        local deceleration = 0.04 + (speedRatio * 0.1)
        jobData.speed = jobData.speed - deceleration
        
        if jobData.speed < 0 then
            jobData.speed = 0
        end
        
        SetTrainCruiseSpeed(jobData.train, jobData.speed)
    end
    
    function jobData.toggleEmergencyBrake()
        if jobData.isDoorOpen or jobData.isStopping then return end
        
        jobData.emergencyBrake = not jobData.emergencyBrake
        
        if jobData.emergencyBrake then
            SetTrainCruiseSpeed(jobData.train, 0)
            PlaySound(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
        else
            SetTrainCruiseSpeed(jobData.train, jobData.speed)
            PlaySound(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
        end
    end
    
    jobData.isDoorInMotion = false
    function jobData.toggleDoors()
        if jobData.isStopping or jobData.isDoorInMotion then return end
        
        local trainSpeed = GetEntitySpeed(jobData.train)
        if trainSpeed > 0.1 then return end
        
        if jobData.isDoorOpen then
            SetTrainState(jobData.train, 4)
            Wait(5000)
            PlaySound(-1, "TIMER_STOP", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
            jobData.isDoorOpen = false
            jobData.isDoorInMotion = false
        else
            jobData.isDoorInMotion = true
            jobData.isDoorOpen = true
            SetTrainState(jobData.train, 2)
            Wait(2000)
            jobData.isDoorInMotion = false
            TriggerEvent("qbx_trainjob:client:doorsOpened")
        end
    end
    
    return jobData
end

Citizen.CreateThread(function()
    SetGhostedEntityAlpha(254)
    
    while not NetworkIsSessionStarted() do
        Wait(500)
    end
    
    Wait(2000)
    local playerCoords = GetEntityCoords(PlayerPedId())
    for mode, position in pairs(Config.Positions) do
        local distance = #(playerCoords - position.NPC.coords)
        if distance < 200.0 then
            manageNPC(mode, distance)
        end
    end
    
    while true do
        local waitTime = 5000
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for mode, position in pairs(Config.Positions) do
            local distance = #(playerCoords - position.NPC.coords)
            
            if distance < 200.0 then
                manageNPC(mode, distance)
            end
            
            if distance < 50.0 then waitTime = 1000 end
            if distance < 10.0 then waitTime = 0 end
            
            if not Config.TargetSystem then
                if distance < 2.0 then
                    if IsTrainDriver() and IsOnDuty() then
                        if not helpNotificationShown[mode] then
                            helpNotificationShown[mode] = true
                            showHelpNotification(Config.Language.npc_help_notification)
                        end
                        
                        if IsControlJustPressed(0, 38) then
                            local currentTime = GetGameTimer()
                            if lastJobStartTime + 3000 < currentTime then
                                StartTrainJob(mode, position.NPC.coords)
                                lastJobStartTime = currentTime
                            end
                        end
                    else
                        if not helpNotificationShown[mode] then
                            helpNotificationShown[mode] = true
                            if not IsTrainDriver() then
                                showHelpNotification(Config.Language.not_train_driver)
                            else
                                showHelpNotification(Config.Language.on_duty_only)
                            end
                        end
                    end
                else
                    if helpNotificationShown[mode] then
                        helpNotificationShown[mode] = false
                        hideHelpNotification()
                    end
                end
            end
        end
        
        Wait(waitTime)
    end
end)

function EndTrainJob(completed)
    if currentTrainJob then
        TriggerServerEvent("qbx_trainjob:server:completeLine", currentTrainJob.mode, completed)
        if DoesEntityExist(currentTrainJob.train) then
            setTrainCollision(currentTrainJob.train, false)
        end
        
        SetLocalPlayerAsGhost(false)
        DestroyAllCams(true)
        RenderScriptCams(false, false, 0, true, true)
        SetFollowPedCamViewMode(1)
        
        SetEntityAsMissionEntity(currentTrainJob.train, false, false)
        DeleteMissionTrain(currentTrainJob.train)
        
        SetEntityCoords(PlayerPedId(), Config.Positions[currentTrainJob.mode].endPos)
        
        currentTrainJob = nil
        
        notify(Config.Language.job_ended, "primary")
    end
end

RegisterNetEvent("qbx_trainjob:client:startJob", function(data)
    if data and data.mode then
        StartTrainJob(data.mode)
    end
end)

function StartTrainJob(mode, npcCoords)
    if not IsTrainDriver() then
        notify(Config.Language.not_train_driver, "error")
        return
    end
    
    if not IsOnDuty() then
        notify(Config.Language.on_duty_only, "error")
        return
    end
    
    if currentTrainJob then
        EndTrainJob(false)
        return
    end
    
    TriggerServerEvent("qbx_trainjob:server:initiateJob")
    
    DoScreenFadeOut(800)
    Wait(1000)
    
    currentTrainJob = createTrainJob(mode)
    
    if not currentTrainJob then
        DoScreenFadeIn(800)
        return
    end
    
    currentTrainJob.enterTrain()
    Wait(800)
    DoScreenFadeIn(800)
    
    local stations = Config.Stations[mode]
    
    currentTrainJob.setMaxSpeed(stations[currentTrainJob.currentStation].newMaxSpeed)
    
    SetLocalPlayerAsGhost(true)
    
    local missedStationCheck = false
    local frameCount = 0
    local stationArrivalTimes = {}
    local idleTime = 0
    
    Citizen.CreateThread(function()
        while currentTrainJob do
            if currentTrainJob.currentStation > #stations then break end
            
            Wait(0)
            
            if not currentTrainJob then return end
            
            frameCount = frameCount + 1
            
            local stationPos = stations[currentTrainJob.currentStation].pos
            local trainFrontPos = GetOffsetFromEntityInWorldCoords(currentTrainJob.train, 0.0, -30.0, 0.0)
            local trainCoords = GetEntityCoords(currentTrainJob.train)
            local distanceToStation = #(trainCoords - stationPos)
            local frontDistanceToStation = #(trainFrontPos - stationPos)
            
            if distanceToStation <= 10.0 then
                local currentStationData = Config.Stations[mode][currentTrainJob.currentStation]
                if currentStationData.isEnd then
                    EndTrainJob(true)
                    return
                end
            end
            
            if distanceToStation <= 10.0 then
                local currentStationData = Config.Stations[mode][currentTrainJob.currentStation]
                if currentStationData.isSkipping then
                    currentTrainJob.currentStation = currentTrainJob.currentStation + 1
                    local nextStationData = Config.Stations[mode][currentTrainJob.currentStation]
                    currentTrainJob.setMaxSpeed(currentStationData.newMaxSpeed)
                end
            end
            
            if distanceToStation <= 10.0 then
                if not stationArrivalTimes[currentTrainJob.currentStation] then
                    stationArrivalTimes[currentTrainJob.currentStation] = GetCloudTimeAsInt()
                end
            end
            
            if stationArrivalTimes[currentTrainJob.currentStation] then
                local arrivalTime = stationArrivalTimes[currentTrainJob.currentStation]
                if arrivalTime + 10 < GetCloudTimeAsInt() then
                    if not missedStationCheck then
                        local currentStationData = Config.Stations[mode][currentTrainJob.currentStation]
                        if not currentStationData.isSkipping then
                            missedStationCheck = true
                            SetTimeout(2000, function()
                                if not currentTrainJob then return end
                                
                                if not currentTrainJob.isStopping then
                                    local trainCurrentPos = GetEntityCoords(currentTrainJob.train)
                                    local distanceFromStation = #(trainCurrentPos - stationPos)
                                    
                                    if distanceFromStation >= 50.0 then
                                        local stationData = Config.Stations[currentTrainJob.mode][currentTrainJob.currentStation]
                                        if not stationData.isSkipping then
                                            currentTrainJob.currentStation = currentTrainJob.currentStation + 1
                                            local nextStationData = Config.Stations[currentTrainJob.mode][currentTrainJob.currentStation]
                                            
                                            if not nextStationData then
                                                currentTrainJob.currentStation = currentTrainJob.currentStation - 1
                                                return
                                            end
                                            
                                            currentTrainJob.setMaxSpeed(stationData.newMaxSpeed)
                                            notify(Config.Language.missed_station, "primary")
                                            missedStationCheck = false
                                        end
                                    else
                                        missedStationCheck = false
                                    end
                                else
                                    missedStationCheck = false
                                end
                            end)
                        end
                    end
                end
            end
            
            local currentStationData = Config.Stations[mode][currentTrainJob.currentStation]
            if not currentStationData.isSkipping then
                local stationX = stationPos.x
                local stationY = stationPos.y
                local stationZ = stationPos.z
                local markerWidth = 3.0
                local markerLength = 55.0
                
                local corners = {
                    vector3(stationX - markerWidth / 2, stationY - markerLength / 2, stationZ - 0.9),
                    vector3(stationX + markerWidth / 2, stationY - markerLength / 2, stationZ - 0.9),
                    vector3(stationX + markerWidth / 2, stationY + markerLength / 2, stationZ - 0.9),
                    vector3(stationX - markerWidth / 2, stationY + markerLength / 2, stationZ - 0.9)
                }
                
                local stationHeading = currentStationData.heading or 0.0
                for i = 1, 4 do
                    corners[i] = rotatePoint(stationPos, corners[i], stationHeading)
                end
                
                local markerColor
                if frontDistanceToStation <= 25.0 then
                    markerColor = {0, 255, 0, 40}
                else
                    markerColor = {255, 0, 0, 40}
                end
                
                local topCorners = {
                    vector3(corners[1].x, corners[1].y, corners[1].z + 0.4),
                    vector3(corners[2].x, corners[2].y, corners[2].z + 0.4),
                    vector3(corners[3].x, corners[3].y, corners[3].z + 0.4),
                    vector3(corners[4].x, corners[4].y, corners[4].z + 0.4)
                }
                
                local function drawPolygon(p1, p2, p3, color)
                    DrawPoly(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, color[1], color[2], color[3], color[4])
                    DrawPoly(p3.x, p3.y, p3.z, p2.x, p2.y, p2.z, p1.x, p1.y, p1.z, color[1], color[2], color[3], color[4])
                end
                
                drawPolygon(corners[1], corners[3], corners[2], markerColor)
                drawPolygon(corners[1], corners[4], corners[3], markerColor)
                drawPolygon(topCorners[1], topCorners[2], topCorners[3], markerColor)
                drawPolygon(topCorners[1], topCorners[3], topCorners[4], markerColor)
                drawPolygon(corners[1], corners[2], topCorners[2], markerColor)
                drawPolygon(corners[1], topCorners[2], topCorners[1], markerColor)
                drawPolygon(corners[4], corners[3], topCorners[3], markerColor)
                drawPolygon(corners[4], topCorners[3], topCorners[4], markerColor)
                drawPolygon(corners[4], topCorners[1], corners[1], markerColor)
                drawPolygon(corners[4], topCorners[4], topCorners[1], markerColor)
                drawPolygon(corners[2], topCorners[3], corners[3], markerColor)
                drawPolygon(corners[2], topCorners[2], topCorners[3], markerColor)
            end
            
            if frameCount >= 2000 then
                frameCount = 0
            end
        end
    end)
    
    Citizen.CreateThread(function()
        while currentTrainJob do
            if currentTrainJob.currentStation > #stations then break end
            
            if not currentTrainJob then return end
            
            if currentTrainJob.isInsideTrain then
                local trainSpeed = GetEntitySpeed(currentTrainJob.train)
                if trainSpeed < 5.0 then
                    local startTimePlus30 = currentTrainJob.startTime + 30
                    if startTimePlus30 > GetCloudTimeAsInt() then
                        if not helpNotificationShown.w_s then
                            helpNotificationShown.w_s = true
                            PlaySound(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                        end
                        DrawMissionText(Config.Language.mission_text_2, 1000)
                    end
                end
            end
            
            local trainSpeed = GetEntitySpeed(currentTrainJob.train)
            if trainSpeed < 1.0 then
                if not currentTrainJob.isStopping then
                    local trainCoords = GetEntityCoords(currentTrainJob.train)
                    local stationPos = stations[currentTrainJob.currentStation].pos
                    local distanceToStation = #(trainCoords - stationPos)
                    
                    if distanceToStation < 30.0 then
                        DrawMissionText(Config.Language.mission_text_1, 1000)
                    end
                end
            end
            
            local trainSpeed = GetEntitySpeed(currentTrainJob.train)
            if trainSpeed < 0.1 then
                idleTime = idleTime + 1
                if idleTime >= 120 then
                    EndTrainJob(false)
                    return
                end
            else
                idleTime = 0
            end
            
            Wait(1000)
        end
    end)
    
    Citizen.CreateThread(function()
        local exitPressCount = 0
        local lastExitPressTime = 0
        
        while currentTrainJob do
            if currentTrainJob.currentStation > #stations then break end
            
            local waitTime = 1000
            
            if not currentTrainJob then return end
            
            if currentTrainJob.isInsideTrain then
                if IsPedInAnyTrain(PlayerPedId()) then
                    waitTime = 0
                    
                    DisableControlAction(0, 75, true)
                    DisableControlAction(0, 86, true)
                    
                    if IsControlPressed(0, 32) then
                        currentTrainJob.increaseSpeed()
                    end
                    
                    if IsControlPressed(0, 31) then
                        currentTrainJob.decreaseSpeed()
                    end
                    
                    if IsControlJustPressed(0, 38) then
                        currentTrainJob.toggleDoors()
                    end
                    
                    if IsDisabledControlJustPressed(0, 75) then
                        exitPressCount = exitPressCount + 1
                        local currentTime = GetGameTimer()
                        if currentTime - lastExitPressTime > 1000 then
                            exitPressCount = 0
                        end
                        
                        if exitPressCount >= 2 then
                            EndTrainJob(false)
                            exitPressCount = 0
                        end
                        
                        lastExitPressTime = currentTime
                    end
                end
            end
            
            Wait(waitTime)
        end
    end)
end

function rotatePoint(center, point, angle)
    local rad = math.rad(angle)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    
    local dx = point.x - center.x
    local dy = point.y - center.y
    
    local rotatedX = center.x + (dx * cos - dy * sin)
    local rotatedY = center.y + (dx * sin + dy * cos)
    
    return vector3(rotatedX, rotatedY, point.z)
end

RegisterNetEvent("qbx_trainjob:client:doorsOpened", function()
    local trainCoords = GetEntityCoords(currentTrainJob.train)
    local stations = Config.Stations[currentTrainJob.mode]
    local currentStationData = stations[currentTrainJob.currentStation]
    
    if currentStationData.isEnd then return end
    if currentStationData.isSkipping then return end
    
    local distanceToStation = #(trainCoords - currentStationData.pos)
    if distanceToStation <= 30.0 then
        local trainSpeed = GetEntitySpeed(currentTrainJob.train)
        if trainSpeed < 0.1 then
            currentTrainJob.isStopping = true
            startProgress(Config.WaitTime[currentTrainJob.mode] + 4, Config.Language.waiting_at_station)
            Wait(Config.WaitTime[currentTrainJob.mode] * 1000)
            currentTrainJob.isStopping = false
            
            currentTrainJob.currentStation = currentTrainJob.currentStation + 1
            currentTrainJob.toggleDoors()
            
            local nextStationData = Config.Stations[currentTrainJob.mode][currentTrainJob.currentStation]
            currentTrainJob.setMaxSpeed(currentStationData.newMaxSpeed)
            
            TriggerServerEvent("qbx_trainjob:server:completeStation", currentTrainJob.mode)
        end
    else
        notify(Config.Language.not_at_station, "error")
        currentTrainJob.toggleDoors()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if currentTrainJob then
            EndTrainJob(false)
        end
    end
end)

print("^2[qbx_trainjob]^0 Client script loaded successfully")



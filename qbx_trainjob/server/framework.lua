QBCore = nil

if Config.Framework == "QBCore" then
    QBCore = exports['qb-core']:GetCoreObject()
end

Citizen.CreateThread(function()
    if Config.Framework == "QBCore" then
        while QBCore == nil do
            QBCore = exports['qb-core']:GetCoreObject()
            Citizen.Wait(100)
        end
        print("^2[qbx_trainjob]^0 QBCore Framework loaded successfully")
    else
        print("^3[qbx_trainjob]^0 Unknown framework: " .. tostring(Config.Framework))
    end
end)

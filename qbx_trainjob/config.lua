Config = {}

-- ============================================
-- CONFIGURATION DU MÉTIER TRAIN
-- ============================================
Config.Job = {
    name = "train",
    label = "Train",
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = {
            name = "Trainee",
            payment = 50
        },
        [1] = {
            name = "Driver", 
            payment = 75
        },
        [2] = {
            name = "Senior Driver",
            payment = 100
        },
        [3] = {
            name = "Manager",
            isboss = true,
            payment = 125
        }
    }
}

Config.Framework = "QBCore"
Config.TargetSystem = false

Config.Trains = {
    ["metro"] = {
        variations = { 28 },
        maxSpeed = 80,
    },
    ["train"] = {
        variations = { 2, 5, 6, 9, 10, 11, 12, 19, 20, 24 },
        maxSpeed = 130,
    },
}

Config.Positions = {
    ["metro"] = {
        NPC = {
            model = "s_m_m_lsmetro_01",
            coords = vector3(-532.6339, -1264.7200, 26.8915),
            heading = 337.4612,
        },
        railPos = vector3(-530.0886, -1270.5343, 25.9033),
        endPos = vector3(-533.3856, -1265.9607, 26.9016),
        direction = true,
    },
    ["train"] = {
        NPC = {
            model = "s_m_m_lsmetro_01",
            coords = vector3(2618.7878, 1692.8821, 27.5986),
            heading = 91.8387,
        },
        railPos = vector3(2610.9312, 1691.5001, 26.9047),
        endPos = vector3(2620.1904, 1672.3811, 27.5996),
        direction = false,
    },
}

Config.WaitTime = {
    ["metro"] = 5,
    ["train"] = 15,
}

Config.Rewards = {
    ["metro"] = { min = 1800, max = 2000, bonus = 850 },
    ["train"] = { min = 3400, max = 3600, bonus = 3500 },
}

Config.Blips = {
    ["metro"] = {
        sprite = 795,
        color = 3,
        scale = 0.8,
        name = "Metro Depot",
    },
    ["train"] = {
        sprite = 795,
        color = 8,
        scale = 0.8,
        name = "Train Depot",
    },
}

Config.UI = {
    speed_limit = {
        unit = "kmh",
        position = { bottom = "1vh", left = "1vw" },
    },
    distance = {
        unit = "km",
        text = "Next Stop:",
        position = { top = "32vh", left = "1vw" },
    }
}

Config.Language = {
    npc_help_notification = "Press [E] to start train job",
    waiting_at_station = "Waiting for passengers...",
    not_at_station = "You must stop at the station!",
    job_started = "Train job started! Use [W] to accelerate, [S] to brake, [E] for doors",
    missed_station = "You missed the station! Continue to next stop",
    job_ended = "Train job completed!",
    mission_text_1 = "Press ~p~E~s~ to open/close doors",
    mission_text_2 = "Press ~p~W~s~ to accelerate ~p~S~s~ to brake",
    not_train_driver = "You are not a train driver!",
    on_duty_only = "You must be on duty to drive trains!",
    job_complete_bonus = "Line completed! Bonus: $%d",
    station_complete = "Station completed: +$%d",
}

Config.Stations = {
    ["metro"] = {
        {
            name = "Strawberry",
            pos = vector3(258.7029, -1210.0177, 38.0746),
            heading = 270.0,
        },
        {
            name = "Burton",
            pos = vector3(-287.1656, -332.1422, 9.1726),
            heading = 0.0,
        },
        {
            name = "Portola Drive",
            pos = vector3(-817.9713, -130.5173, 19.0597),
            heading = 120.0,
        },
        {
            name = "Del Perro",
            pos = vector3(-1359.2241, -467.0545, 14.1547),
            heading = 210.0,
        },
        {
            name = "Little Seoul",
            pos = vector3(-502.5719, -680.8267, 10.9186),
            heading = 270.0,
        },
        {
            name = "Pillbox South",
            pos = vector3(-218.0561, -1032.5148, 29.3254),
            heading = 160.0,
            newMaxSpeed = 50,
        },
        {
            name = "Davis",
            pos = vector3(112.9824, -1729.3881, 29.0559),
            heading = 230.0,
        },
        {
            name = "Davis Quarter",
            pos = vector3(119.3929, -1723.7031, 29.1272),
            heading = 230.0,
            newMaxSpeed = 50,
        },
        {
            name = "Pillbox South Return",
            pos = vector3(-208.0023, -1032.1862, 29.3227),
            heading = 340.2458,
        },
        {
            name = "Little Seoul Return",
            pos = vector3(-500.5500, -665.4594, 10.9198),
            heading = 90.2,
        },
        {
            name = "Del Perro Return",
            pos = vector3(-1345.5730, -459.9233, 14.1551),
            heading = 29.85,
        },
        {
            name = "Portola Drive Return",
            pos = vector3(-810.7444, -143.7276, 19.0599),
            heading = 300.0,
        },
        {
            name = "Burton Return",
            pos = vector3(-302.2440, -332.0439, 9.1726),
            heading = 0.0,
        },
        {
            name = "Strawberry Return",
            pos = vector3(263.1355, -1198.4581, 38.0757),
            heading = 90.0,
        },
        {
            name = "Puerto Del Sol Terminal",
            pos = vector3(-545.2571, -1281.0559, 25.9053),
            heading = 155.64,
            isEnd = true,
        },
    },
    ["train"] = {
        {
            name = "Iron Mines",
            pos = vector3(2612.4163, 2930.6208, 39.8856),
            heading = 324.0,
        },
        {
            name = "Paleto Bay",
            pos = vector3(-139.8481, 6142.5410, 31.5772),
            heading = 135.0,
        },
        {
            name = "Iron Mines Return",
            pos = vector3(2607.4248, 2934.0396, 40.0196),
            heading = 144.0,
        },
        {
            name = "Mirror Park",
            pos = vector3(664.5507, -898.7147, 22.2379),
            heading = 0.0,
        },
        {
            name = "Railway Crossing",
            pos = vector3(556.1844, -1496.6737, 21.4630),
            heading = 181.6500,
            isSkipping = true,
            newMaxSpeed = 50,
        },
        {
            name = "Harbour Bridge",
            pos = vector3(146.5812, -2055.6763, 18.3216),
            heading = 174.8581,
            isSkipping = true,
            newMaxSpeed = 130,
        },
        {
            name = "Harbour Approach",
            pos = vector3(692.0786, -2566.0730, 12.0574),
            heading = 327.6513,
            isSkipping = true,
            newMaxSpeed = 180,
        },
        {
            name = "Terminal Approach",
            pos = vector3(2610.7798, 1467.4595, 31.9006),
            heading = 357.8342,
            isSkipping = true,
            newMaxSpeed = 45,
        },
        {
            name = "Main Terminal",
            pos = vector3(2611.1006, 1698.0022, 26.7970),
            heading = 0.0,
            isEnd = true,
        },
    }
}
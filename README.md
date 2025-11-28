add qbx_core/shared/jobs.lua

<img width="1433" height="766" alt="Sans titre" src="https://github.com/user-attachments/assets/8aa031a5-83ac-4383-aed7-3edb7cd19d69" />
["train"] = {
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
            payment = 125, 
            bankAuth = true 
        },
    },
    },

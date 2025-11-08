local tracks = {
    {
        id = "vinewood_antenna",
        name = "Montée l'antenne de Vinewood",
        description = "Course courte et technique jusqu'à l'antenne de Vinewood.",
        start = { x = 472.0, y = 884.0, z = 197.6, heading = 345.21 },
        finish = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 },
        blip = {
            sprite = 1,
            color = 5,
            coords = {
                { pos = { x = 495.57968139648, y = 975.55279541016, z = 206.3720703125 }, scale = 1.0 },
                { pos = { x = 475.71682739258, y = 1100.7467041016, z = 230.4866790771 }, scale = 1.0  },
                { pos = { x = 493.63165283203, y = 1310.4053955078, z = 281.3562011718 }, scale = 1.0  },
                { pos = { x = 667.21203613281, y = 1369.6392822266, z = 325.96502685547 }, scale = 1.0  },
                { pos = { x = 853.21496582031, y = 1332.9610595703, z = 353.5494995117 }, scale = 1.0 },
                { pos = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 }, scale = 1.5  }    -- finish
            }
        },
        checkpoints = {
            { pos = { x = 495.57968139648, y = 975.55279541016, z = 206.3720703125 },  radius = 6.0 },
            { pos = { x = 475.71682739258, y = 1100.7467041016, z = 230.4866790771 },  radius = 6.0 },
            { pos = { x = 493.63165283203, y = 1310.4053955078, z = 281.3562011718 },  radius = 6.0 },
            { pos = { x = 667.21203613281, y = 1369.6392822266, z = 325.96502685547 }, radius = 6.0 },
            { pos = { x = 853.21496582031, y = 1332.9610595703, z = 353.5494995117 },  radius = 6.0 },
            { pos = { x = 805.91003417969, y = 1275.5114746094, z = 359.8896789550 },  radius = 8.0 } -- finish
        },
        meta = {
            maxPlayers = 2,
            minPlayers = 1,
            laps = 1,
            timeLimit = 100000,
            allowedVehicles = { "adder", "zentorno" }, -- empty = any
            reward = { money = 500, points = 10 }
        }
    },

    -- Add more tracks as needed
}

return tracks

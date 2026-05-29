Config = {}

Config.MaxPlayers = 10
Config.WordHeight = 1.2
Config.DrawDistance = 15.0
Config.AreaRadius = 30

Config.MaxLengthWord = 20
Config.MinLengthWord = 3

Config.Coords = {
    lobby = vector3(689.21887207031, 578.84558105469, 130.46127319336), -- remplacer par les coordonnées de la zone de lobby
    game = vector3(683.53, 581.43, 130.46), -- remplacer par les coordonnées du centre de la zone de jeu
    initialPosition = vector3(680.0, 580.0, 130.0) -- remplacer par les coordonnées de la position où les joueurs sont téléportés en dehors du jeu
}

Config.Locations = {
    {
        name = "Point de départ",
        type = "join",
        message = "Appuie sur ~INPUT_CONTEXT~ pour rejoindre la file d'attente",
        pos = {x=677.65, y=561.78, z=129.0},
        marker = 1,
        scale = 2.0,
        rgba = {120, 255, 120,155}
    },
    {
        name = "Point de leave",
        type = "leave",
        message = "Appuie sur ~INPUT_CONTEXT~ pour quitter",
        pos = {x=700.23, y=575.89, z=130.46},
        marker = 1,
        scale = 2.0,
        rgba = {255, 0, 20,155}
    },
    {
        name = "Point de start",
        type = "start",
        message = "Appuie sur ~INPUT_CONTEXT~ pour commencer la partie",
        pos = {x=689.99, y=588.22, z=131.05},
        marker = 1,
        scale = 2.0,
        rgba = {30, 120, 120,155}
    },
}
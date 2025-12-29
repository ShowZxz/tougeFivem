Config = {}

Config.Keys = {
    INTERACT = 38 -- E
}

Config.Distances = {
    LEGSUP_MAX = 1.5,
    PULLUP_MIN = 2.0,
    PULLUP_MAX = 5.0,
    MIN_WALL_DISTANCE = 2.0,
    MIN_ROOF_HEIGHT = 3.0
}

Config.Cooldowns = {
    LEGSUP = 5000,
    PULLUP = 5000
}

Config.Animation = {
    LEGSUP = {
        DICTJUMP = "lifted@animation",
        ANIMJUMP = "lifted_clip",

        DICTIDLE = "liftidle@pose",
        ANIMIDLE = "liftidle_clip",

        DICTLIFT = "liftanima@animation",
        ANIMLIFT = "liftanima_clip"

    },
    PULLUP = {

        DICTJUMP = "pupanim@animation",
        ANIMJUMP = "pupanim_clip",

        DICTIDLE = "idlepulluppose@pose",
        ANIMIDLE = "idlepulluppose_clip",

        DICTLIFT = "pullupanimation@anim",
        ANIMLIFT = "pullupanimation_clip"

    }
}
Config = {}

Config.Keys = {
    INTERACT = 38, -- E
    LEGSUP_SUPPORT = 113, -- G
    PULLUP_SUPPORT = 246,  -- H
    TOGGLE_SUPPORT = 73 -- X
}

Config.Distances = {
    LEGSUP_MAX = 1.5,
    PULLUP_MIN = 3.0,
    PULLUP_MAX = 5.0,
    MIN_WALL_DISTANCE = 2.0,
    MIN_ROOF_HEIGHT = 3.0
}

Config.Cooldowns = {
    INTERACTION = {
        LEGSUP = 5000,
        PULLUP = 5000
    }
}

Config.SupportToggleCooldown = 5000 -- ms

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

Config.Frame = {
    ANIM_FPS = 60,
    BOOST_FRAME = 20,
    TOTAL_FRAMES = 100
}

Config.Arc = {
    ARC_UP_FORCE = 10.0,
    ARC_FORWARD_FORCE = 3.0,
    ARC_STEP_TIME = 40,
    ARC_STEPS = 6
}

Config.Pulling = {
    PULLING_DURATION = 1200,
    PULLING_HEIGHT = 5.0
}

Config.OffsetPullup = {
    FRONT_OFFSET = 1.5,   
    SIDE_OFFSET  = 0.0, 
    Z_OFFSET     = 0.0 
}

Config.OffsetLegsup = {
    SUPPORT_OFFSET = 0.80,   
    HEIGHT_OFFSET  = 0.0
}

-- Set to true to enable debug commands like /legsup and /pullup
Config.debug = false

-- Set to true to disable the interaction buttons and use only Alt+Click interactions ESX / QBcore style
Config.DisableInteractionButtons = true
Config = {}

-- Key mappings
Config.Keys = {
    INTERACT = 38, -- E
    LEGSUP_SUPPORT = 113, -- G
    PULLUP_SUPPORT = 246,  -- Y
    TOGGLE_SUPPORT = 73 -- X
}


Config.Distances = {
    LEGSUP_MAX = 1.5,
    PULLUP_MIN = 3.0,
    PULLUP_MAX = 5.0,
    MIN_WALL_DISTANCE = 1.5,
    MIN_ROOF_HEIGHT = 3.0
}

-- You can adjust the cooldown times (in milliseconds) for each interaction here
Config.Cooldowns = {
    INTERACTION = {
        LEGSUP = 5000,
        PULLUP = 5000
    }
}

-- Cooldown time for toggling support position
Config.SupportToggleCooldown = 5000

-- You can your own animation dictionaries and names here
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

-- Animation frame 
Config.Frame = {
    ANIM_FPS = 60, -- FPS of the animation in blender
    BOOST_FRAME = 20, -- Frame at which the boost is applied and when my animation in blender start
    TOTAL_FRAMES = 100 -- Total frames of the animation in blender
}


-- Arc parameters for the legsup interaction
Config.Arc = {
    ARC_UP_FORCE = 4.2, -- Initial upward force
    ARC_FORWARD_FORCE = 4.2, -- Forward force applied at each step
    ARC_STEP_TIME = 40, -- Time (in ms) between each arc step
    ARC_STEPS = 6 -- How many time do we applied ARC_FORWARD_FORCE
}


-- Pulling parameters for the pullup interaction
Config.Pulling = {
    PULLING_DURATION = 1200,
    PULLING_HEIGHT = 5.0
}

-- Offsets for positioning the player during interactions you can see this in AlignPlayer function
Config.OffsetPullup = {
    FRONT_OFFSET = 1.5,   
    SIDE_OFFSET  = 0.0, 
    Z_OFFSET     = 0.0 
}

-- Offsets for positioning the player during interactions you can see this in AlignPlayer function
Config.OffsetLegsup = {
    SUPPORT_OFFSET = 0.80,   
    HEIGHT_OFFSET  = 0.0
}

-- Set to true to enable debug commands like /legsup and /pullup
Config.debug = true

-- Set to true to disable the interaction buttons and use only Alt+Click interactions ESX / QBcore style
Config.DisableInteractionButtons = false

Config.EnableOxIntegration = nil  -- Enable integration with interaction proxy resource ox_target
Config.EnableContextMenuIntegration = nil
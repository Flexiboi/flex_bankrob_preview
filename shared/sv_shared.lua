Config.SV_Config = {}

Config.SV_Config.fleeca = {
    maxMembers = 4,
    minigameHackAmount = math.random(3,4), -- Amount of times player outside in car needs to hack and tell the password (Like hack - password - hack - password, ....)
    itemsNeeded = {
        lockpick = 'lockpick',
        drill = 'drill',
        c4 = 'c4',
    },
    offets = {
        trolly = {
            [1] = vec4(-2.890, 2.006, -0.161, 177.140),
            [2] = vec4(-4.368, -2.970, -0.161, -1.332),
            [3] = vec4(-4.997, -1.976, -0.161, -94.019),
        },
        drill1 = {
            [1] = vec4(-1.3931, 2.4083, -0.3362, -0.4690),
            [2] = vec4(-4.3295, 2.4160, -0.3312, -4.4012),
            [3] = vec4(-5.4306, 1.1058, -0.3312, 90.1254),
        },
        drill2 = {
            [1] = vec4(0.0844, -2.0302, -0.3362, -99.6382),
            [2] = vec4(-1.5948, -3.0949, -0.3362, -174.6167),
        },
        door = vec4(1.228, -3.582, -0.045, 7.810),
        gate = vec4(-2.176, -0.662, 0.125, 176.832),
        vaultPanel = vec4(0.748, 2.466, 0.142, 4.139),
        pc = vec4(3.433, -7.456, -0.161, 92.177),
    },
    objects = {
        door = -551608542, -- First door
        vault = 504166510, -- Vault door
        gate = -410044919, -- Sliding gate
        trolly = {
            269934519, -- cash
            269934519, -- cash
            269934519, -- cash
            2007413986, -- gold
            881130828, -- diamond
        }
    },
    banks = {
        [1] = {
            center = vec4(146.29086303711, -1046.3134765625, 29.529062271118, 159.84617614746), -- The position of the vault door
            vaultOpenHeading = 125.0,
            vaultPassword = nil,
            inUse = false, -- If bank is in use
            isHacking = false, -- State if someone is hacking
            hacked = false, -- If computer is hacked
            isLockpicking = false, -- State if somone is lockpicking
            doorOpen = false, -- If lockpicked door is open
            vaultOpen = false, -- If vault door is open
            gateOpen = false, -- If the gate inside the vault is open
            trolly = {
                [1] = false, -- True = taken
                [2] = false, -- True = taken
                [3] = false, -- True = taken
            },
            trollyChance = {
                gold = 10,
                diamond = 5,
            },
            drill1 = {
                [1] = false, -- True = Drilled
                [2] = false, -- True = Drilled
            },
            drill2 = {
                [1] = false, -- True = Drilled
                [2] = false, -- True = Drilled
                [3] = false, -- True = Drilled
            },
        },
    }
}
Config = {}

Config.Debug = true
Config.CoreName = {
    qb = 'qb-core',
    esx = 'es_extended',
    ox = 'ox_core',
    ox_inv = 'ox_inventory',
    qbx = 'qbx_core',
}

Config.Notify = {
    client = function(msg, type, time)
        lib.notify({
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
    server = function(src, msg, type, time)
        lib.notify(src, {
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
}

Config.BankDistance = 24.0 -- Distance for the ox lib zone
Config.MaxHackDistance = 100.0 -- Max distance player can hack the bank from inside the vehicle
Config.VaultPasswordLength = math.random(2, 5)
Config.ExpostionTimer = 15 -- Time before bomb explode in seconds

Config.Minigame = {
    door = function()
        local p = promise:new()
        local success = exports.eye_minigames:Play('lockpick', {
            difficulty = 2,
        })
        p:resolve(success)
        return Citizen.Await(p)
    end,
    pc = function() -- The hack outside for getting password
        local p = promise:new()
        local ped = PlayerPedId()
        local propCoords = GetEntityCoords(ped)
        exports.flex_brickphone:closePhone()
        exports.flex_brickphone:startPhoneAnimation()

        local animDict = 'cellphone@'
        local animName = 'cellphone_text_read_base'
        while not IsEntityPlayingAnim(ped, animDict, animName, 3) do
            Wait(0)
        end
        SetEntityAnimSpeed(ped, animDict, animName, 0.0)
        SetEntityAnimCurrentTime(ped, animDict, animName, 0.2)
        SetPedCanPlayAmbientIdles(ped, false, true)
        FreezeEntityPosition(ped, true)

        local success = exports.eye_minigames:Play('slidepuzzle', {
            difficulty = 2,
            prop = {
                model = 'prop_prologue_phone',
                coords = vec4(propCoords.x, propCoords.y, propCoords.z, GetEntityHeading(ped)),
                txd = 'prop_prologue_phone',
                texture = 'prop_prologue_phone_screen',
                cameraDistance = 0.19,
                camera = true,
            },
        })
        p:resolve(success)
        FreezeEntityPosition(ped, false)
        SetPedCanPlayAmbientIdles(ped, true, false)
        exports.flex_brickphone:stopPhoneAnimation()
        return Citizen.Await(p)
        -- return true
    end,
    vault = function(password)
        local p = promise:new()
        local ped = PlayerPedId()
        local propCoords = GetEntityCoords(ped)
        local success = exports.eye_minigames:PlayDui('password', {
            difficulty = 2,
            attempts = 1,
            password = password,
            caseSensitive = true,
            prop = {
                model = 'hei_prop_hei_securitypanel',
                coords = vec4(propCoords.x, propCoords.y, propCoords.z, GetEntityHeading(ped)),
                txd = 'hei_prop_hei_securitypanel',
                texture = 'prop_hei_securitypanel_screen',
                screenWidth = 0.25,
                screenHeight = 0.22,
                camera = true,
            },
        })
        p:resolve(success)
        return Citizen.Await(p)
    end,
    drill = function()
        return exports['fivem-drilling']:startDrilling()
    end,
}
function GetOffsetFromVector4(coords, offset)
    local heading = math.rad(coords.w)

    local cosH = math.cos(heading)
    local sinH = math.sin(heading)

    local x = coords.x + (offset.x * cosH - offset.y * sinH)
    local y = coords.y + (offset.x * sinH + offset.y * cosH)
    local z = coords.z + offset.z

    -- Offset heading relative to the base heading
    local finalHeading = (coords.w + offset.w) % 360.0

    return vector4(x, y, z, finalHeading)
end

function SetDoorState(doorHash, coords, closed)
    local doorId = GetHashKey(("%s_%.2f_%.2f_%.2f"):format(
        doorHash,
        coords.x,
        coords.y,
        coords.z
   ))

    if not DoorSystemGetIsPhysicsLoaded(doorId) then
        AddDoorToSystem(
            doorId,
            doorHash,
            coords.x,
            coords.y,
            coords.z,
            false,
            false,
            false
       )
    end

    if closed then
        DoorSystemSetDoorState(doorId, 1, false, false)
    else
        DoorSystemSetDoorState(doorId, 0, false, false)
    end
end

function LoadModel(model)
    RequestModel(model)
    local timeout = GetGameTimer() + 2000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Citizen.Wait(100)
    end
    if GetGameTimer() > timeout then
        return false
    end
    return true
end

function GetEntityNetworkControl(entity)
    if NetworkGetEntityIsNetworked(entity) then
        local netId = NetworkGetNetworkIdFromEntity(entity)
        local timeout = GetGameTimer() + 2000
        while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
            NetworkRequestControlOfEntity(entity)
            SetNetworkIdCanMigrate(netId, true)
            Wait(0)
        end
        if not NetworkHasControlOfEntity(entity) then
            print('[flex_bankrob] Failed to get network control of entity:', entity, 'netId:', netId)
            return false
        end
    end
    return true
end

function DeleteNetworkedEntity(entity)
    if not entity or entity == 0 then
        return false
    end
    if not DoesEntityExist(entity) then
        return true
    end
    GetEntityNetworkControl(entity)
    SetEntityAsMissionEntity(entity, true, true)
    DeleteObject(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    return not DoesEntityExist(entity)
end

function AddSphereZone(coords, data, radius)
    for i = 1, #data do
        data[i].distance = data[i].distance or 1.5
    end

    return exports.ox_target:addSphereZone({
        debug = Config.Debug,
        coords = coords,
        options = data,
        radius = radius or 1.5
    })
end

function RemoveZone(Targets)
    if type(Targets) == 'table' then
        for _, target in ipairs(Targets) do
            exports.ox_target:removeZone(target)
        end
    else
        exports.ox_target:removeZone(Targets)
    end
end

function GetOffsetFromDoor(coords)
    local bank, offsets, objects = lib.callback.await('flex_bankrob:server:fleeca:GetFleecaData', false)
    if not bank then return end
    local center = bank.center
    local heading = math.rad(center.w)
    local dx = coords.x - center.x
    local dy = coords.y - center.y
    local dz = coords.z - center.z
    local offsetX = dx * math.cos(heading) + dy * math.sin(heading)
    local offsetY = -dx * math.sin(heading) + dy * math.cos(heading)
    local offsetHeading = coords.w - center.w
    while offsetHeading > 180.0 do
        offsetHeading = offsetHeading - 360.0
    end
    while offsetHeading < -180.0 do
        offsetHeading = offsetHeading + 360.0
    end
    return vec4( offsetX, offsetY, dz, offsetHeading)
end

function GetDoorOffsetVec4(offset)
    local bank, offsets, objects = lib.callback.await('flex_bankrob:server:fleeca:GetFleecaData', false)
    if bank and offset then
        return GetOffsetFromVector4(bank.center, offset)
    end
end

function GetDrillGroundSceneCoords(drillOffset)
    local x, y = drillOffset.x, drillOffset.y
    local fallbackZ = drillOffset.z - 1.0
    local groundZ = nil
    for height = drillOffset.z + 6.0, drillOffset.z - 4.0, -0.5 do
        local found, z = GetGroundZFor_3dCoord(x, y, height, false)
        if found and z and z > -100.0 then
            groundZ = z
            break
        end
    end
    return vector3(x, y, (groundZ or fallbackZ) + 0.015)
end

function SetDrillSceneLooped(networkScene, looped)
    if not networkScene then return end

    local localScene = NetworkGetLocalSceneFromNetworkId(networkScene)
    local timeout = GetGameTimer() + 500

    while (not localScene or localScene == -1) and GetGameTimer() < timeout do
        Wait(0)
        localScene = NetworkGetLocalSceneFromNetworkId(networkScene)
    end

    if localScene and localScene ~= -1 then
        SetSynchronizedSceneLooped(localScene, looped == true)
        SetSynchronizedSceneRate(localScene, 1.0)
    end
end

function DeleteDrillEntitySmooth(entity, delay)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return true
    end

    delay = delay or 100
    GetEntityNetworkControl(entity)
    SetEntityAsMissionEntity(entity, true, true)

    if delay > 0 then
        Wait(delay)
    end

    if DoesEntityExist(entity) then
        DeleteObject(entity)
    end

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    return not DoesEntityExist(entity)
end

function GeneratePassword(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*"
    local password = ""
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        password = password .. chars:sub(randomIndex, randomIndex)
    end
    return password
end

function HasBag(ped)
    -- return exports.qbx_core:IsWearingBag(ped)
    return true
end

function DisableAnimCancel(state)
    LocalPlayer.state:set('canCancel', state, true)
end

if Config.Debug then
    RegisterCommand("getbankoffset", function(source, args)
        if #args < 4 then print("Usage: /getbankoffset x y z h") return end
        local coords = vec4( tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4]))
        local bank = lib.callback.await('flex_bankrob:server:fleeca:GetFleecaData', false)
        if not bank then print("^1No bank data found^7") return end
        print(("^3Bank center: vec4(%.4f, %.4f, %.4f, %.4f)^7"):format( bank.center.x, bank.center.y, bank.center.z, bank.center.w))
        print(("^3Door: vec4(%.4f, %.4f, %.4f, %.4f)^7"):format( coords.x, coords.y, coords.z, coords.w))
        local offset = GetOffsetFromDoor(coords)
        if not offset then print("^1No offset found^7") return end
        print(("^2Offset: vec4(%.4f, %.4f, %.4f, %.4f)^7"):format( offset.x, offset.y, offset.z, offset.w))
    end)
end
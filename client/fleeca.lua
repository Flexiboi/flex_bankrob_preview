local BankData = {}
local fleeca_Zones, Targets, trollies = {}, {}, {}
local NetScene = nil

local function RegisterTargets()
    RemoveZone(Targets)
    Targets = {}
    local bank, offsets, objects = lib.callback.await('flex_bankrob:server:fleeca:GetFleecaData', false)
    if bank then
        if bank.inUse and bank.vaultOpen and not BankData.isInFleecaZone then
            local vault = GetClosestObjectOfType(bank.center.x, bank.center.y, bank.center.z, 1.5, objects.vault, false, false, false)
            if vault then
                SetEntityHeading(vault, bank.center.w)
                TriggerEvent('flex_bankrob:client:fleeca:OpenVault')
            end
        end
        if bank.inUse and bank.gateOpen then
            local gateOffset = GetOffsetFromVector4(bank.center, offsets.gate)
            if not gateOffset then return end
            local gate = GetClosestObjectOfType(gateOffset.x, gateOffset.y, gateOffset.z, 3.5, objects.gate, false, false, false)
            if not gate or gate == 0 then return end
            SetDoorState(objects.gate, GetEntityCoords(gate), false)
        end
        if bank.inUse and bank.doorOpen then
            local doorOffset = GetOffsetFromVector4(bank.center, offsets.door)
            if not doorOffset then return end
            local door = GetClosestObjectOfType(doorOffset.x, doorOffset.y, doorOffset.z, 3.5, objects.door, false, false, false)
            if not door or door == 0 then return end
            SetDoorState(objects.door, GetEntityCoords(door), false)
        end
        if bank.inUse and offsets.vaultPanel and not bank.vaultOpen and bank.hacked and bank.doorOpen then
            local vaultPanelOffset = GetOffsetFromVector4(bank.center, offsets.vaultPanel)
            if not vaultPanelOffset then return end
            local target = AddSphereZone(vaultPanelOffset.xyz, {
                {
                    name = "flex_bankrob_fleeca_vaultpanel",
                    label = locale("target.vaultpanel"),
                    icon = "fa-solid fa-square-binary",
                    onSelect = function()
                        Citizen.Wait(math.random(10,45))
                        lib.callback("flex_bankrob:server:fleeca:GetFleecaData", false, function(bank, offsets, objects)
                            if not bank.vaultOpen then
                                local ped = cache.ped
                                local dict = 'anim@heists@keypad@'
                                lib.requestAnimDict(dict)
                                TaskTurnPedToFaceCoord(ped, vaultPanelOffset.x, vaultPanelOffset.y, vaultPanelOffset.z, 2000)
                                TaskPlayAnim(ped, dict, 'enter', 3.0, 1.0, -1, 49, 0, true, true, true)
                                Wait(math.floor(GetAnimDuration(dict, 'enter') * 1000))
                                TaskPlayAnim(ped, dict, 'idle_a', 3.0, 1.0, -1, 49, 0, true, true, true)
                                lib.callback("flex_bankrob:server:fleeca:GetVaultPassword", false, function(password)
                                    if password then
                                        if Config.Minigame.vault and Config.Minigame.vault(password) then
                                            TaskPlayAnim(ped, dict, 'exit', 3.0, 1.0, -1, 49, 0, true, true, true)
                                            Wait(math.floor(GetAnimDuration(dict, 'exit') * 750))
                                            ClearPedTasks(ped)
                                            RemoveAnimDict(dict)
                                            TriggerServerEvent('flex_bankrob:server:fleeca:Vault')
                                            CreateThread(function()
                                                for k, v in pairs(offsets.trolly) do
                                                    local vault = GetClosestObjectOfType(bank.center.x, bank.center.y, bank.center.z, 1.5, objects.vault, false, false, false)
                                                    if not vault or vault == 0 then return end
                                                    local vaultHeading = GetEntityHeading(vault)
                                                    if not vaultHeading then return end
                                                    if not bank.center.w or bank.center.w == 0.0 then bank = vec4(bank.center.x, bank.center.y, bank.center.z, vaultHeading) end
                                                    local offset = GetOffsetFromVector4(bank.center, v)
                                                    if not offset then return end
                                                    local trolly = nil
                                                    for k, v in pairs(objects.trolly) do
                                                        if v == 881130828 and (math.random(0,100) <= bank.trollyChance.diamond) then -- Diamond
                                                            trolly = CreateObject(v, offset.x, offset.y, offset.z-1, true, false, false)
                                                            break
                                                        elseif v == 2007413986 and (math.random(0,100) <= bank.trollyChance.gold) then -- Gold
                                                            trolly = CreateObject(v, offset.x, offset.y, offset.z-1, true, false, false)
                                                            break
                                                        else -- Cash
                                                            trolly = CreateObject(v, offset.x, offset.y, offset.z-1, true, false, false)
                                                            break
                                                        end
                                                    end
                                                    if trolly then
                                                        SetEntityHeading(trolly, offset.w)
                                                        table.insert(trollies, trolly)
                                                    end
                                                end
                                            end)
                                        else
                                            TaskPlayAnim(ped, dict, 'exit', 3.0, 1.0, -1, 49, 0, true, true, true)
                                            Wait(math.floor(GetAnimDuration(dict, 'exit') * 1000))
                                            ClearPedTasks(ped)
                                            RemoveAnimDict(dict)
                                        end
                                    else
                                        TaskPlayAnim(ped, dict, 'exit', 3.0, 1.0, -1, 49, 0, true, true, true)
                                        Wait(math.floor(GetAnimDuration(dict, 'exit') * 1000))
                                        ClearPedTasks(ped)
                                        RemoveAnimDict(dict)
                                    end
                                end)
                            end
                        end)
                    end,
                    canInteract = function()
                        return not bank.vaultOpen and bank.hacked and bank.doorOpen
                    end,
                }
            }, 1.2)
            table.insert(Targets, target)
        end
        if offsets.door and not bank.vaultOpen and not bank.doorOpen and not bank.vaultOpen then
            local doorOffset = GetOffsetFromVector4(bank.center, offsets.door)
            if not doorOffset then return end
            local door = GetClosestObjectOfType(doorOffset.x, doorOffset.y, doorOffset.z, 2.5, objects.door, false, false, false)
            if not door or door == 0 then return end
            SetDoorState(objects.door, GetEntityCoords(door), true)
            if bank.inUse and not bank.doorOpen then
                local target = AddSphereZone(doorOffset.xyz, {
                    {
                        name = "flex_bankrob_fleeca_door",
                        label = locale("target.door"),
                        icon = "fa-solid fa-square-binary",
                        onSelect = function()
                            Citizen.Wait(math.random(10,45))
                            lib.callback("flex_bankrob:server:fleeca:CanPick", false, function(canPick)
                                if canPick then
                                    TriggerServerEvent('flex_bankrob:server:fleeca:SetLockpickState', true)
                                    local ped = cache.ped
                                    TaskTurnPedToFaceCoord(ped, doorOffset.x, doorOffset.y, doorOffset.z, 2000)
                                    Wait(500)
                                    local dict, anim = 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds'
                                    lib.requestAnimDict(dict)
                                    TaskPlayAnim(ped, dict, anim, 3.0, 1.0, -1, 49, 0, true, true, true)
                                    if Config.Minigame.door() then
                                        TriggerServerEvent('flex_bankrob:server:fleeca:Door')
                                        ClearPedTasks(ped)
                                        RemoveAnimDict(dict)
                                    else
                                        TriggerServerEvent('flex_bankrob:server:fleeca:SetLockpickState', false)
                                        ClearPedTasks(ped)
                                        RemoveAnimDict(dict)
                                    end
                                else
                                    Config.Notify.client(locale("info.missing_item"), 'info', 5000)
                                end
                            end)
                        end,
                        canInteract = function()
                            return not bank.vaultOpen and bank.hacked and not bank.doorOpen and not bank.vaultOpen
                        end,
                    }
                }, 1.2)
                table.insert(Targets, target)
            end
        end
        if bank.inUse and bank.vaultOpen then
            if offsets.trolly and bank.vaultOpen and bank.hacked and bank.doorOpen then
                for trolleyId, _ in pairs(offsets.trolly) do
                    if not bank.trolly[trolleyId] and bank.vaultOpen and bank.hacked and bank.doorOpen then
                        local trollyOffset = GetOffsetFromVector4(bank.center, offsets.trolly[trolleyId])
                        if not trollyOffset then
                            return
                        end
                        local target = AddSphereZone(trollyOffset.xyz, {
                            {
                                name = "flex_bankrob_fleeca_trolly:" .. trolleyId,
                                label = locale("target.trolly"),
                                icon = "fa-solid fa-square-binary",
                                onSelect = function()
                                    local ped = cache.ped
                                    Wait(math.random(10, 45))
                                    if HasBag(ped) then
                                        lib.callback("flex_bankrob:server:fleeca:GetFleecaData", false, function(bankData, bankOffsets, objects)
                                            if bankData.trolly[trolleyId] then
                                                return
                                            end
                                            if not objects or not objects.trolly or not objects.trolly[1] then print("^1[Fleeca] No trolley loot data^0") return end
                                            local model = "hei_prop_heist_cash_pile"
                                            local emptyobj = joaat("hei_prop_hei_cash_trolly_01")
                                            local lootType = "cash"
                                            for _, objectHash in pairs(objects.trolly) do
                                                if objectHash == 2007413986 then
                                                    -- Gold
                                                    model = "ch_prop_gold_bar_01a"
                                                    emptyobj = 2714348429
                                                    lootType = "gold"
                                                    break
                                                elseif objectHash == 881130828 then
                                                    -- Diamond
                                                    model = "ch_prop_vault_dimaondbox_01a"
                                                    emptyobj = 2714348429
                                                    lootType = "diamond"
                                                    break
                                                else
                                                    -- Cash
                                                    model = "hei_prop_heist_cash_pile"
                                                    emptyobj = 769923921
                                                    lootType = "cash"
                                                    break
                                                end
                                            end
                                            local Trolly = nil
                                            for _, objectHash in pairs(objects.trolly) do
                                                local found = GetClosestObjectOfType(trollyOffset.x, trollyOffset.y, trollyOffset.z, 2.0, objectHash, false, false, false)
                                                if found and found ~= 0 and DoesEntityExist(found) then
                                                    Trolly = found
                                                    break
                                                end
                                            end
                                            if not Trolly or Trolly == 0 or not DoesEntityExist(Trolly) then
                                                print("^1[Fleeca] Could not find trolley entity^0")
                                                return
                                            end
                                            local function RequestEntityControl(entity)
                                                if not entity
                                                    or entity == 0
                                                    or not DoesEntityExist(entity) then
                                                    return false
                                                end
                                                if NetworkHasControlOfEntity(entity) then
                                                    return true
                                                end
                                                NetworkRequestControlOfEntity(entity)
                                                local timeout = GetGameTimer() + 5000
                                                while not NetworkHasControlOfEntity(entity)
                                                    and GetGameTimer() < timeout do
                                                    Wait(0)
                                                    NetworkRequestControlOfEntity(entity)
                                                end
                                                return NetworkHasControlOfEntity(entity)
                                            end
                                            if not RequestEntityControl(Trolly) then
                                                print("^1[Fleeca] Could not get trolley network control^0")
                                                return
                                            end
                                            local trollyCoords = GetEntityCoords(Trolly)
                                            local trollyRotation = GetEntityRotation(Trolly)
                                            if not trollyCoords or not trollyRotation then
                                                print("^1[Fleeca] Invalid trolley coordinates/rotation^0")
                                                return
                                            end
                                            TriggerServerEvent('flex_bankrob:server:fleeca:Trolly', trolleyId)
                                            local animDict = "anim@heists@ornate_bank@grab_cash"
                                            local baghash = joaat("hei_p_m_bag_var22_arm_s")
                                            lib.requestAnimDict(animDict)
                                            LoadModel(baghash)
                                            LoadModel(emptyobj)
                                            if not DoesEntityExist(Trolly) then
                                                return
                                            end
                                            if not RequestEntityControl(Trolly) then
                                                return
                                            end
                                            local function SpawnLootObject()
                                                local pedCoords = GetEntityCoords(ped)
                                                local grabmodel = joaat(model)
                                                LoadModel(grabmodel)
                                                while not HasModelLoaded(grabmodel) do
                                                    Wait(0)
                                                end
                                                local grabobj = CreateObject(grabmodel, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
                                                if not grabobj or grabobj == 0 then
                                                    return nil
                                                end
                                                FreezeEntityPosition(grabobj, true)
                                                SetEntityInvincible(grabobj, true)
                                                SetEntityNoCollisionEntity(grabobj, ped, false)
                                                SetEntityVisible(grabobj, false, false)
                                                AttachEntityToEntity(grabobj, ped, GetPedBoneIndex(ped, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
                                                local startedGrabbing = GetGameTimer()
                                                CreateThread(function()
                                                    while GetGameTimer() - startedGrabbing < 37000 do
                                                        Wait(10)
                                                        DisableControlAction(0, 73, true)
                                                        if HasAnimEventFired(ped, joaat("CASH_APPEAR")) then
                                                            if not IsEntityVisible(grabobj) then
                                                                SetEntityVisible(grabobj, true, false)
                                                            end
                                                        end
                                                        if HasAnimEventFired(ped, joaat("RELEASE_CASH_DESTROY")) then
                                                            if IsEntityVisible(grabobj) then
                                                                SetEntityVisible(grabobj, false, false)
                                                                TriggerServerEvent('flex_bankrob:server:fleeca:TrollyLoot', trolleyId)
                                                            end
                                                        end
                                                    end
                                                    if DoesEntityExist(grabobj) then
                                                        DeleteEntity(grabobj)
                                                    end
                                                    SetModelAsNoLongerNeeded(grabmodel)
                                                end)
                                                return grabobj
                                            end
                                            local GrabBag = CreateObject(baghash, GetEntityCoords(ped), true, true, false)
                                            if not GrabBag or GrabBag == 0 then
                                                print("^1[Fleeca] Failed to create grab bag^0")
                                                return
                                            end
                                            local scene1 = NetworkCreateSynchronisedScene(trollyCoords, trollyRotation, 2, false, false, 1065353216, 0, 1.3)
                                            NetworkAddPedToSynchronisedScene(ped, scene1, animDict, "intro", 1.5, -4.0, 1, 16, 1148846080, 0)
                                            NetworkAddEntityToSynchronisedScene(GrabBag, scene1, animDict, "bag_intro", 4.0, -8.0, 1)
                                            local currentBag = GetPedDrawableVariation(ped, 5)
                                            SetPedComponentVariation(ped, 5, 0, 0, 0)
                                            DisableAnimCancel(true)
                                            NetworkStartSynchronisedScene(scene1)
                                            Wait(1500)
                                            NetworkStopSynchronisedScene(scene1)
                                            local grabobj = SpawnLootObject()
                                            local scene2 = NetworkCreateSynchronisedScene(trollyCoords, trollyRotation, 2, false, false, 1065353216, 0, 1.3)
                                            NetworkAddPedToSynchronisedScene(ped, scene2, animDict, "grab", 1.5, -4.0, 1, 16, 1148846080, 0)
                                            NetworkAddEntityToSynchronisedScene(GrabBag, scene2, animDict, "bag_grab", 4.0, -8.0, 1)
                                            NetworkAddEntityToSynchronisedScene(Trolly, scene2, animDict, "cart_cash_dissapear", 4.0, -8.0, 1)
                                            NetworkStartSynchronisedScene(scene2)
                                            Wait(37000)
                                            NetworkStopSynchronisedScene(scene2)
                                            local scene3 = NetworkCreateSynchronisedScene(trollyCoords, trollyRotation, 2, false, false, 1065353216, 0, 1.3)
                                            NetworkAddPedToSynchronisedScene(ped, scene3, animDict, "exit", 1.5, -4.0, 1, 16, 1148846080, 0)
                                            NetworkAddEntityToSynchronisedScene(GrabBag, scene3, animDict, "bag_exit", 4.0, -8.0, 1)
                                            NetworkStartSynchronisedScene(scene3)
                                            if DoesEntityExist(Trolly) then
                                                if RequestEntityControl(Trolly) then
                                                    DeleteEntity(Trolly)
                                                    local deleteTimeout = GetGameTimer() + 2000
                                                    while DoesEntityExist(Trolly) and GetGameTimer() < deleteTimeout do
                                                        Wait(0)
                                                        DeleteEntity(Trolly)
                                                    end
                                                end
                                            end
                                            local NewTrolly = CreateObject(emptyobj, trollyCoords.x, trollyCoords.y, trollyCoords.z - 0.985, true, true, false)
                                            if NewTrolly and NewTrolly ~= 0 then
                                                SetEntityRotation(NewTrolly, trollyRotation.x, trollyRotation.y, trollyRotation.z, 2, true)
                                                table.insert(trollies, NewTrolly)
                                            end
                                            if NewTrolly and NewTrolly ~= 0 and DoesEntityExist(NewTrolly) then
                                                PlaceObjectOnGroundProperly(NewTrolly)
                                                FreezeEntityPosition(NewTrolly, true)
                                            end
                                            Wait(1800)
                                            NetworkStopSynchronisedScene(scene3)
                                            DisableAnimCancel(false)
                                            if DoesEntityExist(GrabBag) then
                                                DeleteEntity(GrabBag)
                                            end
                                            SetPedComponentVariation(ped, 5, currentBag or 45, 0, 0)
                                            RemoveAnimDict(animDict)
                                            SetModelAsNoLongerNeeded(emptyobj)
                                            SetModelAsNoLongerNeeded(baghash)
                                        end)
                                    else
                                        Config.Notify.client(locale("info.missing_bag"), 'info', 5000)
                                    end
                                end,
                                canInteract = function()
                                    return not bank.trolly[trolleyId] and bank.vaultOpen and bank.hacked and bank.doorOpen
                                end,
                            }
                        }, 1.3)
                        table.insert(Targets, target)
                    end
                end
            end
            if offsets.gate and bank.vaultOpen and bank.hacked and bank.doorOpen and not bank.gateOpen then
                local gateOffset = GetOffsetFromVector4(bank.center, offsets.gate)
                if not gateOffset then return end
                local target = AddSphereZone(gateOffset.xyz, {
                    {
                        name = "flex_bankrob_fleeca_gate",
                        label = locale("target.gate"),
                        icon = "fa-solid fa-square-binary",
                        onSelect = function()
                            local ped = cache.ped
                            Citizen.Wait(math.random(10,45))
                            if HasBag(ped) then
                                lib.callback("flex_bankrob:server:fleeca:CanC4", false, function(canC4)
                                    if canC4 then
                                        lib.callback("flex_bankrob:server:fleeca:GetFleecaData", false, function(bank, offsets, objects)
                                            if bank.vaultOpen then
                                                local dict = 'anim@heists@ornate_bank@thermal_charge'
    
                                                local currentBag = GetPedDrawableVariation(ped, 5)
                                                if not LoadModel('hei_p_m_bag_var22_arm_s') or not LoadModel('prop_bomb_01') or not lib.requestAnimDict(dict) then
                                                    return false
                                                end
                                                local scenePos = vector3(gateOffset.x, gateOffset.y, gateOffset.z)
                                                local sceneRot = vector3(0.0, 0.0, gateOffset.w)
                                                SetEntityCoordsNoOffset(ped, scenePos.x, scenePos.y, scenePos.z, false, false, false)
                                                SetEntityHeading(ped, gateOffset.w)
                                                local scene = NetworkCreateSynchronisedScene(scenePos.x, scenePos.y, scenePos.z, sceneRot.x, sceneRot.y, sceneRot.z, 2, false, false, 1065353216, 0, 1.3)
                                                local bag = CreateObject(joaat('hei_p_m_bag_var22_arm_s'), scenePos.x, scenePos.y, scenePos.z, true, true, false)
                                                if bag == 0 then
                                                    return false
                                                end
                                                NetworkAddPedToSynchronisedScene(ped, scene, dict, 'thermal_charge', 1.5, -4.0, 1, 16, 1148846080, 0)
                                                NetworkAddEntityToSynchronisedScene(bag, scene, dict, 'bag_thermal_charge', 4.0, -8.0, 1)
                                                SetPedComponentVariation(ped, 5, 0, 0, 0)
                                                DisableAnimCancel(true)
                                                NetworkStartSynchronisedScene(scene)
                                                Wait(1500)
                                                local coords = GetEntityCoords(ped)
                                                local bomb = CreateObject(joaat('prop_bomb_01'), coords.x, coords.y, coords.z + 0.2, true, true, true)
                                                if bomb ~= 0 then
                                                    AttachEntityToEntity(bomb, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 200.0, true, true, false, true, 1, true)
                                                end
                                                Wait(3000)
                                                if DoesEntityExist(bag) then
                                                    DeleteEntity(bag)
                                                end
                                                if bomb ~= 0 and DoesEntityExist(bomb) then
                                                    DetachEntity(bomb, true, true)
                                                    FreezeEntityPosition(bomb, true)
                                                end
                                                SetPedComponentVariation(ped, 5, currentBag, 0, 0)
                                                NetworkStopSynchronisedScene(scene)
                                                SetModelAsNoLongerNeeded(joaat('hei_p_m_bag_var22_arm_s'))
                                                SetModelAsNoLongerNeeded(joaat('prop_bomb_01'))
                                                RemoveAnimDict(dict)
                                                DisableAnimCancel(false)
                                                TriggerServerEvent('flex_bankrob:server:fleeca:StartExplosion')
                                                Wait(1000 * Config.ExpostionTimer)
                                                if DoesEntityExist(bomb) then
                                                    DeleteEntity(bomb)
                                                end
                                                TriggerServerEvent('flex_bankrob:server:fleeca:Gate')
                                            end
                                        end)
                                    else
                                        Config.Notify.client(locale("info.missing_item"), 'info', 5000)
                                    end
                                end)
                            else
                                Config.Notify.client(locale("info.missing_bag"), 'info', 5000)
                            end
                        end,
                        canInteract = function()
                            return bank.vaultOpen and bank.hacked and bank.doorOpen and not bank.gateOpen
                        end,
                    }
                }, 1.2)
                table.insert(Targets, target)
            end
            if offsets.drill1 and bank.vaultOpen and bank.hacked and bank.doorOpen then
                for drillId, v in pairs(offsets.drill1) do
                    local drillOffset = GetOffsetFromVector4(bank.center, v)
                    if not drillOffset then return end

                    local target = AddSphereZone(drillOffset.xyz, {
                        {
                            name = "flex_bankrob_fleeca_drill1:" .. drillId,
                            label = locale("target.drill"),
                            icon = "fa-solid fa-square-binary",
                            onSelect = function()
                                local ped = cache.ped
                                Citizen.Wait(math.random(10, 45))
                                if HasBag(ped) then
                                    lib.callback("flex_bankrob:server:fleeca:CanDrill", false, function(canDrill)
                                        if canDrill then
                                            lib.callback("flex_bankrob:server:fleeca:GetFleecaData", false, function(bank, offsets, objects)
                                                if not bank or not bank.vaultOpen then return end
                                                TriggerServerEvent('flex_bankrob:server:fleeca:SetDrill1', drillId)
            
                                                local function GetDrillAnimDict(id)
                                                    local lockboxId = ((id - 1) % 4) + 1
                                                    return ("anim_heist@hs3f@ig10_lockbox_drill@pattern_01@lockbox_%02d@male@"):format(lockboxId)
                                                end
            
                                                local dict = GetDrillAnimDict(drillId)
                                                local drillHash = joaat("ch_prop_vault_drill_01a")
                                                local bagHash = joaat("hei_p_m_bag_var22_arm_s")
                                                local drillObject
                                                local bagObject
                                                local handObject
                                                local currentScene
            
                                                local groundCoords = GetDrillGroundSceneCoords(drillOffset)
                                                local sceneCoords = vector3(groundCoords.x, groundCoords.y, groundCoords.z)
                                                local pedCoords = sceneCoords
                                                local sceneRotation = vector3(0.0, 0.0, drillOffset.w)
            
                                                local function cleanup()
                                                    if currentScene then
                                                        NetworkStopSynchronisedScene(currentScene)
                                                        currentScene = nil
                                                    end
            
                                                    if handObject and handObject ~= 0 and DoesEntityExist(handObject) then
                                                        DeleteDrillEntitySmooth(handObject, 80)
                                                        handObject = nil
                                                    end
            
                                                    if drillObject and drillObject ~= 0 and DoesEntityExist(drillObject) then
                                                        DeleteDrillEntitySmooth(drillObject, 80)
                                                        drillObject = nil
                                                    end
            
                                                    if bagObject and bagObject ~= 0 and DoesEntityExist(bagObject) then
                                                        DeleteDrillEntitySmooth(bagObject, 80)
                                                        bagObject = nil
                                                    end
            
                                                    SetModelAsNoLongerNeeded(drillHash)
                                                    SetModelAsNoLongerNeeded(bagHash)
                                                    RemoveAnimDict(dict)
                                                end
                                                local currentBag = GetPedDrawableVariation(ped, 5)
                                                local function failCleanup()
                                                    cleanup()
            
                                                    if DoesEntityExist(ped) then
                                                        ClearPedTasksImmediately(ped)
                                                        SetPedComponentVariation(ped, 5, currentBag or 45, 0, 0)
                                                    end
                                                end
            
                                                if not LoadModel("ch_prop_vault_drill_01a") or not LoadModel("hei_p_m_bag_var22_arm_s") or not lib.requestAnimDict(dict) then
                                                    cleanup()
                                                    return
                                                end
            
                                                SetEntityCoordsNoOffset(ped, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
                                                SetEntityHeading(ped, sceneRotation.z)
                                                SetPedComponentVariation(ped, 5, 0, 0, 0)
            
                                                drillObject = CreateObject(drillHash, sceneCoords.x, sceneCoords.y, sceneCoords.z, true, true, false)
                                                bagObject = CreateObject(bagHash, sceneCoords.x, sceneCoords.y, sceneCoords.z, true, true, false)
            
                                                if drillObject == 0 or bagObject == 0 then
                                                    cleanup()
                                                    if DoesEntityExist(ped) then SetPedComponentVariation(ped, 5, currentBag or 45, 0, 0) end
                                                    return
                                                end
            
                                                local function getDuration(anim, minimum)
                                                    local duration = GetAnimDuration(dict, anim)
                                                    if not duration or duration <= 0 then return minimum end
                                                    return math.max(math.floor(duration * 1000), minimum)
                                                end
            
                                                local function phase(anim, drillAnim, bagAnim, duration)
                                                    local scene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z, sceneRotation.x, sceneRotation.y, sceneRotation.z, 2, false, false, 1065353216, 0, 1.3)
                                                    currentScene = scene
            
                                                    NetworkAddPedToSynchronisedScene(ped, scene, dict, anim, 1.5, -4.0, 1, 16, 1148846080, 0)
                                                    NetworkAddEntityToSynchronisedScene(drillObject, scene, dict, drillAnim, 4.0, -8.0, 1)
                                                    NetworkAddEntityToSynchronisedScene(bagObject, scene, dict, bagAnim, 4.0, -8.0, 1)
            
                                                    if handObject and DoesEntityExist(handObject) then
                                                        NetworkAddEntityToSynchronisedScene(handObject, scene, dict, "reward_ch_prop_ch_moneybag_01a", 4.0, -8.0, 1)
                                                    end
                                                    DisableAnimCancel(true)
                                                    NetworkStartSynchronisedScene(scene)
                                                    SetDrillSceneLooped(scene, false)
                                                    Wait(duration)
            
                                                    if currentScene == scene then
                                                        NetworkStopSynchronisedScene(scene)
                                                        currentScene = nil
                                                    end
                                                end
            
                                                phase("enter", "enter_ch_prop_vault_drill_01a", "enter_p_m_bag_var22_arm_s", getDuration("enter", 1000))
            
                                                local actionScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z, sceneRotation.x, sceneRotation.y, sceneRotation.z, 2, false, false, 1065353216, 0, 1.3)
                                                currentScene = actionScene
            
                                                NetworkAddPedToSynchronisedScene(ped, actionScene, dict, "action", 1.5, -4.0, 1, 16, 1148846080, 0)
                                                NetworkAddEntityToSynchronisedScene(drillObject, actionScene, dict, "action_ch_prop_vault_drill_01a", 4.0, -8.0, 1)
                                                NetworkAddEntityToSynchronisedScene(bagObject, actionScene, dict, "action_p_m_bag_var22_arm_s", 4.0, -8.0, 1)
            
                                                NetworkStartSynchronisedScene(actionScene)
                                                SetDrillSceneLooped(actionScene, true)
            
                                                if Config.Minigame.drill() then
                                                    if currentScene == actionScene then
                                                        SetDrillSceneLooped(actionScene, false)
                                                        NetworkStopSynchronisedScene(actionScene)
                                                        currentScene = nil
                                                    end
                                                    local rewardModel = 'ch_prop_ch_moneybag_01a'
                                                    local rewardHash = joaat(rewardModel)
                                                    if LoadModel(rewardModel) then
                                                        handObject = CreateObject(rewardHash, sceneCoords.x, sceneCoords.y, sceneCoords.z, true, true, false)
                                                    end
                                                    if handObject and handObject ~= 0 and DoesEntityExist(handObject) then
                                                        phase("reward", "reward_ch_prop_vault_drill_01a", "reward_p_m_bag_var22_arm_s", getDuration("reward", 2500))
                                                        TriggerServerEvent('flex_bankrob:server:fleeca:Drill1Loot', drillId)
                                                        DeleteDrillEntitySmooth(handObject, 100)
                                                        handObject = nil
                                                    else
                                                        phase("reward", "reward_ch_prop_vault_drill_01a", "reward_p_m_bag_var22_arm_s", getDuration("reward", 2500))
                                                    end
                                                    SetModelAsNoLongerNeeded(rewardHash)
                                                else
                                                    if currentScene == actionScene then
                                                        SetDrillSceneLooped(actionScene, false)
                                                        NetworkStopSynchronisedScene(actionScene)
                                                        currentScene = nil
                                                    end
                                                    Config.Notify.client(locale("error.drill_failed"), "error")
                                                    phase("no_reward", "no_reward_ch_prop_vault_drill_01a", "no_reward_p_m_bag_var22_arm_s", getDuration("no_reward", 1500))
                                                    TriggerServerEvent('flex_bankrob:server:fleeca:SetDrill1', drillId)
                                                end
                                                DisableAnimCancel(false)
                                                phase("exit", "exit_ch_prop_vault_drill_01a", "exit_p_m_bag_var22_arm_s", getDuration("exit", 800))
                                                failCleanup()
                                            end)
                                        else
                                            Config.Notify.client(locale("info.missing_item"), 'info', 5000)
                                        end
                                    end)
                                else
                                    Config.Notify.client(locale("info.missing_bag"), 'info', 5000)
                                end
                            end,
                            canInteract = function()
                                return bank.vaultOpen and bank.hacked and bank.doorOpen and not bank.drill1[drillId]
                            end,
                        }
                    }, 1.2)

                    table.insert(Targets, target)
                end
            end         
            if offsets.drill2 and bank.vaultOpen and bank.hacked and bank.doorOpen then
                for drillId, v in pairs(offsets.drill2) do
                    local drillOffset = GetOffsetFromVector4(bank.center, v)
                    if not drillOffset then return end

                    local target = AddSphereZone(drillOffset.xyz, {
                        {
                            name = "flex_bankrob_fleeca_drill1:" .. drillId,
                            label = locale("target.drill"),
                            icon = "fa-solid fa-square-binary",
                            onSelect = function()
                                local ped = cache.ped
                                Citizen.Wait(math.random(10, 45))
                                if HasBag(ped) then
                                    lib.callback("flex_bankrob:server:fleeca:CanDrill", false, function(canDrill)
                                        if canDrill then
                                            lib.callback("flex_bankrob:server:fleeca:GetFleecaData", false, function(bank, offsets, objects)
                                                if not bank or not bank.vaultOpen then return end
                                                TriggerServerEvent('flex_bankrob:server:fleeca:SetDrill2', drillId)
            
                                                local function GetDrillAnimDict(id)
                                                    local lockboxId = ((id - 1) % 4) + 1
                                                    return ("anim_heist@hs3f@ig10_lockbox_drill@pattern_01@lockbox_%02d@male@"):format(lockboxId)
                                                end
            
                                                local dict = GetDrillAnimDict(drillId)
                                                local drillHash = joaat("ch_prop_vault_drill_01a")
                                                local bagHash = joaat("hei_p_m_bag_var22_arm_s")
                                                local drillObject
                                                local bagObject
                                                local handObject
                                                local currentScene
            
                                                local groundCoords = GetDrillGroundSceneCoords(drillOffset)
                                                local sceneCoords = vector3(groundCoords.x, groundCoords.y, groundCoords.z)
                                                local pedCoords = sceneCoords
                                                local sceneRotation = vector3(0.0, 0.0, drillOffset.w)
            
                                                local function cleanup()
                                                    if currentScene then
                                                        NetworkStopSynchronisedScene(currentScene)
                                                        currentScene = nil
                                                    end
            
                                                    if handObject and handObject ~= 0 and DoesEntityExist(handObject) then
                                                        DeleteDrillEntitySmooth(handObject, 80)
                                                        handObject = nil
                                                    end
            
                                                    if drillObject and drillObject ~= 0 and DoesEntityExist(drillObject) then
                                                        DeleteDrillEntitySmooth(drillObject, 80)
                                                        drillObject = nil
                                                    end
            
                                                    if bagObject and bagObject ~= 0 and DoesEntityExist(bagObject) then
                                                        DeleteDrillEntitySmooth(bagObject, 80)
                                                        bagObject = nil
                                                    end
            
                                                    SetModelAsNoLongerNeeded(drillHash)
                                                    SetModelAsNoLongerNeeded(bagHash)
                                                    RemoveAnimDict(dict)
                                                end
                                                local currentBag = GetPedDrawableVariation(ped, 5)
                                                local function failCleanup()
                                                    cleanup()
            
                                                    if DoesEntityExist(ped) then
                                                        ClearPedTasksImmediately(ped)
                                                        SetPedComponentVariation(ped, 5, currentBag or 45, 0, 0)
                                                    end
                                                end
            
                                                if not LoadModel("ch_prop_vault_drill_01a") or not LoadModel("hei_p_m_bag_var22_arm_s") or not lib.requestAnimDict(dict) then
                                                    cleanup()
                                                    return
                                                end
            
                                                SetEntityCoordsNoOffset(ped, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
                                                SetEntityHeading(ped, sceneRotation.z)
                                                SetPedComponentVariation(ped, 5, 0, 0, 0)
            
                                                drillObject = CreateObject(drillHash, sceneCoords.x, sceneCoords.y, sceneCoords.z, true, true, false)
                                                bagObject = CreateObject(bagHash, sceneCoords.x, sceneCoords.y, sceneCoords.z, true, true, false)
            
                                                if drillObject == 0 or bagObject == 0 then
                                                    cleanup()
                                                    if DoesEntityExist(ped) then SetPedComponentVariation(ped, 5, currentBag or 45, 0, 0) end
                                                    return
                                                end
            
                                                local function getDuration(anim, minimum)
                                                    local duration = GetAnimDuration(dict, anim)
                                                    if not duration or duration <= 0 then return minimum end
                                                    return math.max(math.floor(duration * 1000), minimum)
                                                end
            
                                                local function phase(anim, drillAnim, bagAnim, duration)
                                                    local scene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z, sceneRotation.x, sceneRotation.y, sceneRotation.z, 2, false, false, 1065353216, 0, 1.3)
                                                    currentScene = scene
            
                                                    NetworkAddPedToSynchronisedScene(ped, scene, dict, anim, 1.5, -4.0, 1, 16, 1148846080, 0)
                                                    NetworkAddEntityToSynchronisedScene(drillObject, scene, dict, drillAnim, 4.0, -8.0, 1)
                                                    NetworkAddEntityToSynchronisedScene(bagObject, scene, dict, bagAnim, 4.0, -8.0, 1)
            
                                                    if handObject and DoesEntityExist(handObject) then
                                                        NetworkAddEntityToSynchronisedScene(handObject, scene, dict, "reward_ch_prop_ch_moneybag_01a", 4.0, -8.0, 1)
                                                    end
                                                    DisableAnimCancel(true)
                                                    NetworkStartSynchronisedScene(scene)
                                                    SetDrillSceneLooped(scene, false)
                                                    Wait(duration)
            
                                                    if currentScene == scene then
                                                        NetworkStopSynchronisedScene(scene)
                                                        currentScene = nil
                                                    end
                                                end
            
                                                phase("enter", "enter_ch_prop_vault_drill_01a", "enter_p_m_bag_var22_arm_s", getDuration("enter", 1000))
            
                                                local actionScene = NetworkCreateSynchronisedScene(sceneCoords.x, sceneCoords.y, sceneCoords.z, sceneRotation.x, sceneRotation.y, sceneRotation.z, 2, false, false, 1065353216, 0, 1.3)
                                                currentScene = actionScene
            
                                                NetworkAddPedToSynchronisedScene(ped, actionScene, dict, "action", 1.5, -4.0, 1, 16, 1148846080, 0)
                                                NetworkAddEntityToSynchronisedScene(drillObject, actionScene, dict, "action_ch_prop_vault_drill_01a", 4.0, -8.0, 1)
                                                NetworkAddEntityToSynchronisedScene(bagObject, actionScene, dict, "action_p_m_bag_var22_arm_s", 4.0, -8.0, 1)
            
                                                NetworkStartSynchronisedScene(actionScene)
                                                SetDrillSceneLooped(actionScene, true)
            
                                                
                                                if Config.Minigame.drill() then
                                                    if currentScene == actionScene then
                                                        SetDrillSceneLooped(actionScene, false)
                                                        NetworkStopSynchronisedScene(actionScene)
                                                        currentScene = nil
                                                    end
                                                    local rewardModel = 'ch_prop_ch_moneybag_01a'
                                                    local rewardHash = joaat(rewardModel)
                                                    if LoadModel(rewardModel) then
                                                        handObject = CreateObject(rewardHash, sceneCoords.x, sceneCoords.y, sceneCoords.z, true, true, false)
                                                    end
                                                    if handObject and handObject ~= 0 and DoesEntityExist(handObject) then
                                                        phase("reward", "reward_ch_prop_vault_drill_01a", "reward_p_m_bag_var22_arm_s", getDuration("reward", 2500))
                                                        TriggerServerEvent('flex_bankrob:server:fleeca:Drill2Loot', drillId)
                                                        DeleteDrillEntitySmooth(handObject, 100)
                                                        handObject = nil
                                                    else
                                                        phase("reward", "reward_ch_prop_vault_drill_01a", "reward_p_m_bag_var22_arm_s", getDuration("reward", 2500))
                                                    end
                                                    SetModelAsNoLongerNeeded(rewardHash)
                                                else
                                                    if currentScene == actionScene then
                                                        SetDrillSceneLooped(actionScene, false)
                                                        NetworkStopSynchronisedScene(actionScene)
                                                        currentScene = nil
                                                    end
                                                    Config.Notify.client(locale("error.drill_failed"), "error")
                                                    phase("no_reward", "no_reward_ch_prop_vault_drill_01a", "no_reward_p_m_bag_var22_arm_s", getDuration("no_reward", 1500))
                                                    TriggerServerEvent('flex_bankrob:server:fleeca:SetDrill2', drillId)
                                                end
                                                DisableAnimCancel(false)
                                                phase("exit", "exit_ch_prop_vault_drill_01a", "exit_p_m_bag_var22_arm_s", getDuration("exit", 800))
                                                failCleanup()
                                            end)
                                        else
                                            Config.Notify.client(locale("info.missing_item"), 'info', 5000)
                                        end
                                    end, drillId)
                                else
                                    Config.Notify.client(locale("info.missing_bag"), 'info', 5000)
                                end
                            end,
                            canInteract = function()
                                return bank.vaultOpen and bank.hacked and bank.doorOpen and not bank.drill2[drillId]
                            end,
                        }
                    }, 1.2)

                    table.insert(Targets, target)
                end
            end         
        end
    end
end

local function onEnter(self)
    if exports.flex_brickphone then exports.flex_brickphone:cleanupWaypoint() end
    RegisterTargets()
    BankData.isInFleecaZone = true
end

local function onExit(self)
    local bank, offsets, objects = lib.callback.await('flex_bankrob:server:fleeca:GetFleecaData', false)
    if bank then
        local vault = GetClosestObjectOfType(bank.center.x, bank.center.y, bank.center.z, 1.5, objects.vault, false, false, false)
        if vault then
            SetEntityHeading(vault, bank.center.w)
        end
    end
    RemoveZone(Targets)
    Targets = {}
    BankData.isInFleecaZone = false
end

local function initialize()
    while not LocalPlayer.state.isLoggedIn do
        Wait(1000)
    end
    if #fleeca_Zones > 0 then return end
    local banks, offsets, objects = lib.callback.await('flex_bankrob:server:fleeca:GetAllFleecaData', false)
    BankData.banks = banks
    BankData.offsets = offsets
    BankData.objects = objects
    if banks then
        for k, v in pairs(banks) do
            local zone = lib.zones.sphere({
                name = 'fleeca_bank_zone:'..k,
                coords = v.center.xyz,
                radius = Config.BankDistance,
                debug = Config.Debug,
                onEnter = onEnter,
                onExit = onExit
            })
            table.insert(fleeca_Zones, zone)
            local vault = GetClosestObjectOfType(v.center.x, v.center.y, v.center.z, 7.5, objects.vault, false, false, false)
            if not vault or vault == 0 then return end
            SetEntityHeading(vault, v.center.w or 0.0)
            local gateOffset = GetOffsetFromVector4(v.center, offsets.gate)
            if not gateOffset then return end
            local gate = GetClosestObjectOfType(gateOffset.x, gateOffset.y, gateOffset.z, 3.5, objects.gate, false, false, false)
            if not gate or gate == 0 then return end
            SetDoorState(objects.gate, GetEntityCoords(gate), true)
        end
    end
end

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        initialize()
    end
end)

RegisterNetEvent(onPlayerLoaded(), function()
    initialize()
end)

local function unload()
    if BankData.banks and BankData.offsets and BankData.objects then
        if BankData.banks then
            for k, v in pairs(BankData.banks) do
                local vault = GetClosestObjectOfType(v.center.x, v.center.y, v.center.z, 1.5, BankData.objects.vault, false, false, false)
                if not vault or vault == 0 then return end
                SetEntityHeading(vault, v.center.w or 0.0)
            end
        end
        for k, v in pairs(fleeca_Zones) do
            v:remove()
        end
        for i = #trollies, 1, -1 do
            local Trolly = trollies[i]
            if Trolly and Trolly ~= 0 then
                if DoesEntityExist(Trolly) then
                    local deleted = DeleteNetworkedEntity(Trolly)
                end
            end
        end
        trollies = {}
        fleeca_Zones = {}
        RemoveZone(Targets)
        Targets = {}
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        unload()
    end
end)

RegisterNetEvent(onPlayerUnLoaded(), function()
    unload()
end)


RegisterNetEvent('flex_bankrob:client:fleeca:RefreshTargets', function()
    RegisterTargets()
end)

RegisterNetEvent('flex_bankrob:client:fleeca:OpenVault', function()
    local bank, offsets, objects = lib.callback.await('flex_bankrob:server:fleeca:GetFleecaData', false)
    local pedCoords = GetEntityCoords(cache.ped)
    if #(pedCoords.xyz - bank.center.xyz) > (Config.BankDistance*2) then return end
    CreateThread(function()
        local vault = GetClosestObjectOfType(bank.center.x, bank.center.y, bank.center.z, 1.5, objects.vault, false, false, false)
        if not vault or vault == 0 then return end
        local vaultHeading = GetEntityHeading(vault)
        if not vaultHeading then return end
        local openHeading = 0
        while openHeading <= bank.vaultOpenHeading do
            SetEntityHeading(vault, vaultHeading-openHeading)
            openHeading += 0.05
            Citizen.Wait(10)
        end
    end)
end)

RegisterNetEvent('flex_bankrob:client:fleeca:HackComputer', function()
    local bank, offsets, objects = lib.callback.await('flex_bankrob:server:fleeca:GetFleecaData', false)
    local pedCoords = GetEntityCoords(cache.ped)
    if #(pedCoords.xyz - bank.center.xyz) > Config.MaxHackDistance then
        exports.flex_brickphone:sendContactMessage(
            'hacker_man',
            locale("phone_message.messages.fleeca.not_near_hackpos")
     )
        return
    end
    if not IsPedInAnyVehicle(cache.ped) or not cache.vehicle or GetVehicleTypeRaw(cache.vehicle) == 11 or GetVehicleTypeRaw(cache.vehicle) == 12 or GetVehicleTypeRaw(cache.vehicle) == 3 then
        exports.flex_brickphone:sendContactMessage(
            'hacker_man',
            locale("phone_message.messages.fleeca.not_in_vehicle")
     )
        return
    end
    TriggerServerEvent('flex_bankrob:server:fleeca:SetHackState', true)
    if Config.Minigame.pc() then
        TriggerServerEvent('flex_bankrob:server:fleeca:Hacked')
    else
        TriggerServerEvent('flex_bankrob:server:fleeca:SetHackState', false)
    end
end)

RegisterNetEvent('flex_bankrob:client:fleeca:GateExplosion', function(coords)
    local pedCoords = GetEntityCoords(cache.ped)
    if #(pedCoords.xyz - coords.xyz) > Config.MaxHackDistance then return end
    local soundId = GetSoundId()
    local endTime = GetGameTimer() + (Config.ExpostionTimer * 1000)
    local delay = 1000
    while GetGameTimer() < endTime do
        PlaySoundFromCoord(soundId, "Beep_Red", coords.x, coords.y, coords.z, "DLC_HEIST_HACKING_SNAKE_SOUNDS", false, 0, false)
        local remaining = endTime - GetGameTimer()
        local progress = 1.0 - (remaining / (Config.ExpostionTimer * 1000))
        delay = math.floor(1000 - (progress * 800))
        delay = math.max(delay, 200)
        Wait(delay)
    end
    StopSound(soundId)
    ReleaseSoundId(soundId)
    AddExplosion(coords.x, coords.y, coords.z + 0.15, 2, 0.35, true, false, 0.15)
end)
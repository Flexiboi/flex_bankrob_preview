local isDoingHeist = {}

lib.callback.register('flex_bankrob:server:fleeca:GetFleecaData', function(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return false, nil, nil
    end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(v.center.xyz - pedCoords.xyz) < Config.MaxHackDistance then
            return v, Config.SV_Config.fleeca.offets, Config.SV_Config.fleeca.objects
        end
    end
    return false, nil, nil
end)

lib.callback.register('flex_bankrob:server:fleeca:GetAllFleecaData', function(source)
    if not Config.SV_Config then return end
    return Config.SV_Config.fleeca.banks, Config.SV_Config.fleeca.offets, Config.SV_Config.fleeca.objects
end)

local function GetVaultPassword(source)
    local src = source
    Citizen.Wait(math.random(10,35))
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if Config.SV_Config.fleeca.banks[k].hacked then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < Config.MaxHackDistance then
                if not Config.SV_Config.fleeca.banks[k].vaultPassword then
                    Config.SV_Config.fleeca.banks[k].vaultPassword = GeneratePassword(Config.VaultPasswordLength)
                end
                return Config.SV_Config.fleeca.banks[k].vaultPassword
            end
        end
    end
    return false
end

lib.callback.register('flex_bankrob:server:fleeca:GetVaultPassword', function(source)
    return GetVaultPassword(source)
end)

RegisterNetEvent('flex_bankrob:server:fleeca:SetBankState', function(state)
    Citizen.Wait(math.random(10,35))
    local src = source
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(v.center.xyz - pedCoords.xyz) < Config.MaxHackDistance then
            if state then
                v.inUse = true
            else
                v.inUse = false
            end
        end
    end
end)

local function RefreshTargets(coords)
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        if ped ~= 0 then
            local playerCoords = GetEntityCoords(ped)
            local dx = playerCoords.x - coords.x
            local dy = playerCoords.y - coords.y
            local dz = playerCoords.z - coords.z
            local distanceSquared = dx * dx + dy * dy + dz * dz
            if distanceSquared <= Config.BankDistance then
                TriggerClientEvent('flex_bankrob:client:fleeca:RefreshTargets', playerId)
            end
        end
        Citizen.Wait(10)
    end
end

RegisterNetEvent('flex_bankrob:server:fleeca:SetLockpickState', function(state)
    local src = source
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if Config.SV_Config.fleeca.banks[k] and Config.SV_Config.fleeca.banks[k].inUse and Config.SV_Config.fleeca.banks[k].isLockpicking then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 18.0 then
                Config.SV_Config.fleeca.banks[k].isLockpicking = state
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:Door', function()
    local src = source
    Citizen.Wait(math.random(10,35))
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if not Config.SV_Config.fleeca.banks[k].doorOpen then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 18.0 then
                local door = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.door)
                if #(door.xyz - pedCoords.xyz) < 18.0 then
                    Config.SV_Config.fleeca.banks[k].doorOpen = true
                    RefreshTargets(door.xyz)
                    return
                end
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:SetHackState', function(state)
    local src = source
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if Config.SV_Config.fleeca.banks[k] and Config.SV_Config.fleeca.banks[k].inUse and Config.SV_Config.fleeca.banks[k].isHacking then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < Config.MaxHackDistance then
                Config.SV_Config.fleeca.banks[k].isHacking = state
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:Hacked', function()
    local src = source
    Citizen.Wait(math.random(10,35))
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if not Config.SV_Config.fleeca.banks[k].hacked then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < Config.MaxHackDistance then
                local pc = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.pc)
                if #(pc.xyz - pedCoords.xyz) < Config.MaxHackDistance then
                    Config.SV_Config.fleeca.banks[k].hacked = true
                    RefreshTargets(pc.xyz)
                    exports.flex_brickphone:sendContactMessage(
                        src,
                        'hacker_man',
                        locale("phone_message.messages.fleeca.hack_success", GetVaultPassword(src))
                    )
                    return
                end
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:Vault', function()
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local vault = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.vaultPanel)
            if #(vault.xyz - pedCoords.xyz) < 18.0 then
                Config.SV_Config.fleeca.banks[k].vaultOpen = true
                TriggerClientEvent('flex_bankrob:client:fleeca:OpenVault', -1)
                RefreshTargets(vault.xyz)
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:Trolly', function(id)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local trolly = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.trolly[id])
            if #(trolly.xyz - pedCoords.xyz) < 18.0 then
                Config.SV_Config.fleeca.banks[k].trolly[id] = true
                RefreshTargets(trolly.xyz)
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:TrollyLoot', function(id)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local trolly = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.trolly[id])
            if #(trolly.xyz - pedCoords.xyz) < 10.0 then
                if lootType == "gold" then
                    exports.flex_loothub:loot(src, 'gold_bar', trolly.xyz)
                elseif lootType == "diamond" then
                    exports.flex_loothub:loot(src, 'diamond', trolly.xyz)
                else
                    exports.flex_loothub:loot(src, 'black_money', trolly.xyz)
                end
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:StartExplosion', function()
    local src = source
    Citizen.Wait(math.random(10,35))
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if not Config.SV_Config.fleeca.banks[k].gateOpen then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < Config.BankDistance then
                local gate = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.gate)
                if #(gate.xyz - pedCoords.xyz) < Config.BankDistance then
                    TriggerClientEvent('flex_bankrob:client:fleeca:GateExplosion', -1, gate)
                    return
                end
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:Gate', function()
    local src = source
    Citizen.Wait(math.random(10,35))
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if not Config.SV_Config.fleeca.banks[k].gateOpen then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < Config.BankDistance then
                local gate = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.gate)
                if #(gate.xyz - pedCoords.xyz) < Config.BankDistance then
                    Config.SV_Config.fleeca.banks[k].gateOpen = true
                    RefreshTargets(gate.xyz)
                    return
                end
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:GateExplosion', function()
    local src = source
    Citizen.Wait(math.random(10,35))
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if not Config.SV_Config.fleeca.banks[k].gateOpen then
            if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < Config.BankDistance then
                local gate = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.gate)
                if #(gate.xyz - pedCoords.xyz) < 10.0 then
                    TriggerClientEvent('flex_bankrob:client:fleeca:GateExplosion', -1, gate.xyz)
                    return
                end
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:Drill1Loot', function(id)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local drill = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.drill1[id])
            if #(drill.xyz - pedCoords.xyz) < 10.0 then
                exports.flex_loothub:loot(src, 'fleeca', drill.xyz)
                RefreshTargets(drill.xyz)
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:Drill2Loot', function(id)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local drill = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.drill2[id])
            if #(drill.xyz - pedCoords.xyz) < 10.0 then
                exports.flex_loothub:loot(src, 'fleeca', drill.xyz)
                RefreshTargets(drill.xyz)
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:SetDrill1', function(id)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local drill = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.drill1[id])
            if #(drill.xyz - pedCoords.xyz) < 10.0 then
                Config.SV_Config.fleeca.banks[k].drill1[id] = not Config.SV_Config.fleeca.banks[k].drill1[id]
                return
            end
        end
    end
end)


RegisterNetEvent('flex_bankrob:server:fleeca:Drill2Loot', function(id)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local drill = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.drill2[id])
            if #(drill.xyz - pedCoords.xyz) < 10.0 then
                exports.flex_loothub:loot(source, 'fleeca', drill.xyz)
                return
            end
        end
    end
end)

RegisterNetEvent('flex_bankrob:server:fleeca:SetDrill2', function(id)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            local drill = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.drill2[id])
            if #(drill.xyz - pedCoords.xyz) < 10.0 then
                Config.SV_Config.fleeca.banks[k].drill2[id] = not Config.SV_Config.fleeca.banks[k].drill2[id]
                return
            end
        end
    end
end)

-- ITEM CHECKS
lib.callback.register('flex_bankrob:server:fleeca:CanPick', function(source)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            return HasInvGotItem(src, 'count', Config.SV_Config.fleeca.itemsNeeded.lockpick, nil, 1)
        end
    end
end)

lib.callback.register('flex_bankrob:server:fleeca:CanDrill', function(source)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            return HasInvGotItem(src, 'count', Config.SV_Config.fleeca.itemsNeeded.drill, nil, 1)
        end
    end
end)

lib.callback.register('flex_bankrob:server:fleeca:CanC4', function(source)
    local src = source
    Citizen.Wait(math.random(10, 35))
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < 30.0 then
            return HasInvGotItem(src, 'count', Config.SV_Config.fleeca.itemsNeeded.c4, nil, 1)
        end
    end
end)

-- BRICK PHONE
CreateThread(function()
    Citizen.Wait(1000)
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if not Config.SV_Config.fleeca.banks[k].isHacking then
            local password = GeneratePassword(Config.VaultPasswordLength)
            Config.SV_Config.fleeca.banks[k].vaultPassword = password
        end
    end
    local contactRegistered = exports.flex_brickphone:registerContact(
        'fleeca_heist',
        {
            id = 'fleeca_heist',
            name = locale("phone_message.messages.fleeca.contect_name"),
            number = '02749320123',
            enabled = true,
            target = 'all'
        }
    )

    local handlerRegistered = exports.flex_brickphone:registerContactHandler('fleeca_heist', function(source, data)
        local src = source
        if not src then return false end

        local message = (data.message or ''):lower()
        if message == locale("phone_message.commands.start_fleeca"):lower() then
            if isDoingHeist[src] then
                exports.flex_brickphone:sendContactMessage(
                    src,
                    'fleeca_heist',
                    locale("phone_message.messages.fleeca.already_inheist")
                )
                return {
                    received = true,
                    accepted = false
                }
            end
            local bank = Config.SV_Config.fleeca.banks[math.random(1, #Config.SV_Config.fleeca.banks)]

            local timeout = 30000
            local startTime = GetGameTimer()

            while bank.inUse and (GetGameTimer() - startTime) < timeout do
                bank = Config.SV_Config.fleeca.banks[math.random(1, #Config.SV_Config.fleeca.banks)]
                Citizen.Wait(1000)
            end

            if bank.inUse then
                exports.flex_brickphone:sendContactMessage(
                    src,
                    'fleeca_heist',
                    locale("phone_message.messages.fleeca.no_bank_found")
                )
                return {
                    received = true,
                    accepted = false
                }
            end

            local groupId = exports.flex_brickphone:GetAdminGroupId(src)
            if groupId then
                local members = exports.flex_brickphone:GetGroupMembers(groupId, src)
                if not members then
                    exports.flex_brickphone:sendContactMessage(
                        src,
                        'fleeca_heist',
                        locale("phone_message.messages.fleeca.no_members")
                    )
                    return {
                        received = true,
                        accepted = false
                    }
                end
                if #members > Config.SV_Config.fleeca.maxMembers then
                    for k, v in pairs(members) do
                        if v.identifier then
                            local player = GetPlayerByCitizenId(v.identifier)
                            if player and player.PlayerData then
                                exports.flex_brickphone:sendContactMessage(
                                    player.PlayerData.source,
                                    'fleeca_heist',
                                    locale("phone_message.messages.fleeca.max_members", Config.SV_Config.fleeca.maxMembers, #members)
                                )
                            end
                        end
                    end
                    return {
                        received = true,
                        accepted = false
                    }
                end
                bank.inUse = true
                for k, v in pairs(members) do
                    if v.identifier then
                        local player = GetPlayerByCitizenId(v.identifier)
                        if player and player.PlayerData then
                            exports.flex_brickphone:startMission(player.PlayerData.source, {
                                coords = bank.center.xyz,
                                label = locale("phone_message.messages.fleeca.title"),
                                contactId = 'fleeca_heist',
                                message = locale("phone_message.messages.fleeca.start_mission")
                            })
                            isDoingHeist[player.PlayerData.source] = true
                        end
                    end
                    Citizen.Wait(10)
                end
            else
                exports.flex_brickphone:sendContactMessage(
                    src,
                    'fleeca_heist',
                    locale("phone_message.messages.fleeca.not_leader")
                )
                return {
                    received = true,
                    accepted = false
                }
            end

            return {
                received = true,
                accepted = true
            }
        end
        return false
    end)

    local handlerRegistered = exports.flex_brickphone:registerContactHandler('hacker_man', function(source, data)
        local src = source
        if not src then return false end

        local message = (data.message or ''):lower()
        if message == locale("phone_message.commands.hack_fleeca"):lower() then
            if isDoingHeist[src] then
                Citizen.Wait(math.random(10,35))
                if not src then return end
                local ped = GetPlayerPed(src)
                if ped == nil or ped == 0 then return end
                local pedCoords = GetEntityCoords(ped)
                if not pedCoords then return end
                for k, v in pairs(Config.SV_Config.fleeca.banks) do
                    if Config.SV_Config.fleeca.banks[k] and Config.SV_Config.fleeca.banks[k].inUse and not Config.SV_Config.fleeca.banks[k].isHacking then
                        if #(Config.SV_Config.fleeca.banks[k].center.xyz - pedCoords.xyz) < Config.MaxHackDistance then
                            exports.flex_brickphone:sendContactMessage(
                                src,
                                'hacker_man',
                                locale("phone_message.messages.fleeca.started_hack")
                            )
                            TriggerClientEvent('flex_bankrob:client:fleeca:HackComputer', src)
                            return
                        end
                    end
                end
                exports.flex_brickphone:sendContactMessage(
                    src,
                    'hacker_man',
                    locale("phone_message.messages.fleeca.hack_out_of_distance")
                )
            else
                exports.flex_brickphone:sendContactMessage(
                    src,
                    'hacker_man',
                    locale("phone_message.messages.fleeca.not_in_heist")
                )
            end
        end
    end)
end)

lib.addCommand(locale('commands.fix_fleeca'), {
    help = locale('commands.fix_fleeca_desc'),
    params = {
        { name = 'target', type = 'Type', help = locale('commands.fix_fleeca_type') },
    },
    restricted = 'group.admin'
}, function(source, args)
    if not args.target then return end
    local src = source
    Citizen.Wait(math.random(10,35))
    if not src then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if not pedCoords then return end
    for k, v in pairs(Config.SV_Config.fleeca.banks) do
        if args.target:lower() == 'hack' then
            local vault = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.vaultPanel)
            Config.SV_Config.fleeca.banks[k].hacked = true
            RefreshTargets(vault.xyz)
            return
        elseif args.target:lower() == 'door' then
            local door = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.door)
            Config.SV_Config.fleeca.banks[k].doorOpen = true
            RefreshTargets(door.xyz)
            return
        elseif args.target:lower() == 'vault' then
            local vault = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.vaultPanel)
            Config.SV_Config.fleeca.banks[k].vaultOpen = true
            RefreshTargets(vault.xyz)
            return
        elseif args.target:lower() == 'gate' then
            local gate = GetOffsetFromVector4(Config.SV_Config.fleeca.banks[k].center, Config.SV_Config.fleeca.offets.gate)
            Config.SV_Config.fleeca.banks[k].gateOpen = true
            RefreshTargets(gate.xyz)
            return
        end
    end
end)
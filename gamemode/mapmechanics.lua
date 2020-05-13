-- This is called right after the game has processed all the map entities. This is responsible for using the weapon_spawn to remove them from the world and take note
-- of their positions for weapon spawning.
-- For info on mapping for this gamemode, check here: (insert youtube link when i make the guide video here)

local wepsTable = {}


local defaultWeaponDelay = 8

local weaponDelay = defaultWeaponDelay
local currentWeaponDelay = weaponDelay

playfight_isSuddenDeath = false

-- Table of weapons and their randomization weight respectively
playfight_weapons_table = {
    weapon_shotgun = 5,
    weapon_357 = 5,
    throwable_crowbar = 3,
    hitscan_crossbow = 5,
    ricochet_disk = 4
}

-- If the grace period is currently active
playfight_is_grace_period = false

-- How long the grace period should last in seconds
playfight_grace_period_length = 5

function PlayFightCountGracePeriod(length)
    net.Start("playfight_client_graceperiod_count")
    net.WriteFloat(playfight_grace_period_length)
    net.Broadcast()
end

function GM:InitPostEntity()

    SetGlobalBool("__ident1fier____Warmup_playfight__", true)
    SetGlobalInt("__ident1fier____Warmup_time_playfight__", 30)
    SetGlobalBool("__ident1fier____Waiting_playfight__", true)

    

    -- For the camera angles on the menu.
    local uiCams = {}

    local camAngles = {}

    for k, v in next, ents.GetAll() do

        if ( v:GetClass() == "info_target" and v:GetName() == "weapon_spawn" ) then

            table.insert(wepsTable, v:GetPos())
            
        end

        if ( v:GetClass() == "info_player_start" ) then

            table.insert(uiCams, v:GetPos())
            table.insert(camAngles, v:GetAngles())
            
        end

    end



-- This codebase dates back to about january 2018 and i'm not sure why I decided to do it this way, but this
-- seems to be storing the table in a global fashion so it can be accessed later outside of this scope i think question mark?
-- (Also an example of professional naming conventions)

-- Update: still not sure why i did it like this, also not sure what i was on about in the first comment.

SetGlobalString("wOwWWW___wepPSTaTALBE___xdddx", util.TableToJSON(wepsTable))
SetGlobalString("wOwWWW___RPGcAMERa___xdddx", util.TableToJSON(uiCams))

timer.Create("___PlayFight__weaponSpAwn__", 0.1, 0, function()

    currentWeaponDelay = currentWeaponDelay - 0.1

    -- Lower weapon spawn delay based on amount of players. The more players the less delay.
    local curPlayers = #player.GetAll()

    if curPlayers == 2 then
        curPlayers = 1
    end

    weaponDelay = defaultWeaponDelay / ((curPlayers) / 3)


    -- If it's been long enough since the last weapon spawn to spawn a weapon, spawn one.
    if currentWeaponDelay <= 0 then
        

        local spawn = false

        for k,v in next, player.GetAll() do
            local pCount = player.GetCount()

            for k,v in next, player.GetAll() do

                if table.HasValue(playfight_server_menu_info, v) then

                    pCount = pCount - 1
                end

            end

            -- This ensures we're taking into account weapons in player's hands
            if ( !v:HasWeapon("weapon_shotgun") and !v:HasWeapon("weapon_357") and !v:HasWeapon("throwable_crowbar") and !v:HasWeapon("hitscan_crossbow") and !v:HasWeapon("ricochet_disk") ) then
                spawn = true
            end
        end

        -- Make sure there aren't too many weapons in the map already
        local weaponsInMap = {}

        for tableIndex, tableEntry in pairs(playfight_weapons_table) do
            for wepIndex, weapon in pairs(ents.FindByClass(tableIndex)) do
                table.insert(weaponsInMap, weapon)
            end
        end

        local wepCount = #weaponsInMap
        
        if wepCount >= #player.GetAll() then
            spawn = false
        end

        -- Ensure weapon drops are even enabled
        if !GetConVar("pf_enableweapondrops"):GetBool() then
            spawn = false
        end

        -- Don't spawn weapons during sudden death
        if playfight_isSuddenDeath then
            spawn = false
        end

        -- Now that we know if we should spawn a weapon, lets actually do that.
        if ( spawn ) then

            -- Randomly choose weapon position out of table
            local totalWeight = 0
            local weaponWeightTable = {}


            -- This creates a table of weapons we can pick from based off of that weapons weight.
            -- EXAMPLE:
            -- table entry 1: WEAPON_TYPE_1
            -- table entry 2: WEAPON_TYPE_1
            -- table entry 3: WEAPON_TYPE_1  <---- This weapon had a weight of 3
            -- [------------------ divider -------------------]
            -- table entry 4: WEAPON_TYPE_2
            -- table entry 5: WEAPON_TYPE_2  <---- This weapon had a weight of 2

            -- It will then take a random number from 1 to the total added up value of all the weapon weights and that is how it decides which weapon to spawn.
            -- you can find playfight_weapons_table at the top of this script.

            for k, v in pairs(playfight_weapons_table) do
                totalWeight = totalWeight + v

                for i = 1, v, 1 do
                    table.insert(weaponWeightTable, k)
                end 

                
            end

            local posChoose = math.random(1, #wepsTable)
            local wepChoose = math.random(1, #weaponWeightTable)

            local wepSpawn = nil

            wepSpawn = ents.Create(weaponWeightTable[wepChoose])

            wepSpawn:SetPos(wepsTable[posChoose])

            wepSpawn:Spawn()
            wepSpawn:Activate()

            currentWeaponDelay = weaponDelay
        end
    end

end)

local globalTable = GetGlobalString("wOwWWW___wepPSTaTALBE___xdddx", nil)
local camTable = GetGlobalString("wOwWWW___RPGcAMERa___xdddx", nil)

if ( globalTable ~= nil ) then

    local tabWep = util.JSONToTable(globalTable)

    -- Counts down the timer every second.
    timer.Create("__ident1fier____Warmup_playfight____timerrr___", 1, 0, function()

        -- Checks if we are currently in the warmup.
        if (GetGlobalBool("__ident1fier____Warmup_playfight__", true)) then
            local playMenus = 0

            for k,v in next, player.GetAll() do
                if ( table.HasValue(playfight_server_menu_info, v) ) then
                    playMenus = playMenus + 1
                end
            end

            -- If there are enough players and the timer is not at 0, count down
            if ( player.GetCount() - playMenus > 1 and GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) >= 0) then
                SetGlobalInt("__ident1fier____Warmup_time_playfight__", GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) - 1)
                if (GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) <= 0) then
                    for k,v in next, player.GetAll() do
                        v:Freeze(true)

                        -- Time in seconds till the game starts
                        local timeTillStart = 5

                        -- Start round after 5 seconds
                        timer.Simple(timeTillStart, function()


                            -- Start round now
                            SetGlobalInt("__ident1fier____Warmup_time_playfight__", 300)
                            SetGlobalBool("__ident1fier____Warmup_playfight__", false)

                            game.CleanUpMap()

                            for k,v in next, player.GetAll() do
                                v:Freeze(false)
                                v:StripWeapons()
                                v:Spawn()

                                -- Teleport player to random spawn point
                                if #ents.FindByClass("info_player_start") > 0 then
                                    local spawnSelection = math.random(1, #ents.FindByClass("info_player_start"))

                                    for i, value in pairs(ents.FindByClass("info_player_start")) do
                                        if i == spawnSelection and util.IsInWorld(value:GetPos()) then
                                            v:SetPos(value:GetPos())
                                        end
                                    end
                                end
                            end
                            
                            

                            -- Play round start sound
                            net.Start("playfight_client_playsound")
                            net.WriteString("suitchargeok1.wav")
                            net.Broadcast()

                            -- Play music
                            net.Start("playfight_client_play_music")
                            net.Broadcast()

                            -- Grace Period
                            playfight_is_grace_period = true

                            PlayFightCountGracePeriod(playfight_grace_period_length)

                            timer.Create("playfight_timer_grace_period_disable", playfight_grace_period_length, 1, function()
                                playfight_is_grace_period = false
                            end)

                            hook.Add("PlayerDeath", "__PlAYEr_deeathTH_playfight__", function( ply, inflictor, attacker )
                                if !GetGlobalBool("__ident1fier____Warmup_playfight__", true) then
                                    ply.shouldSpec = true
                                    ply.killer = attacker
                                end
                            end)
                        end)

                        local timeCounted = 0

                        -- Timer for sending time till round start 
                        timer.Create("_gameStartTime_PLayFiGhT_", 1, timeTillStart, function()
                            timeCounted = timeCounted + 1

                            local countedTime = timeTillStart - timeCounted

                            net.Start("playfight_client_screenmessage")

                            if timeCounted == timeTillStart then
                                net.WriteString("")
                            else
                                net.WriteString("Game Starting in "..countedTime)
                            end

                            net.Broadcast()

                            
                        end)
                    end

                    timer.Simple(5, function()
                        print("Round starting!")
                    end)

                    timer.Stop("__ident1fier____Warmup_playfight____timerrr___")
                    timer.Remove("__ident1fier____Warmup_playfight____timerrr___")
                end
                SetGlobalBool("__ident1fier____Waiting_playfight__", false)
            else
                SetGlobalBool("__ident1fier____Waiting_playfight__", true)
            end
        end

    end)
    
    -- If we are not in the warmup, and there is more than one player alive, and the timer is not at 0 count down.
    timer.Create("__ident1fier____RoUnd_playfight____timerrr___", 1, 0, function()
        local alivePly = {}



        for k,v in next, player.GetAll() do
            if v:Alive() then
                table.insert(alivePly, v:Nick())
            end
        end

        if (!GetGlobalBool("__ident1fier____Warmup_playfight__", true) and #alivePly > 1) then
            if (GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) > 0) then
                SetGlobalInt("__ident1fier____Warmup_time_playfight__", GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) - 1)
            end
        end

        -- If the round is a draw
        if GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) <= 0 and #alivePly > 1 and !GetGlobalBool("__ident1fier____Warmup_playfight__", true) then
            -- Get list of alive players
            if #alivePly > 1 then
                -- If sudden death is enabled, do it
                if GetConVar("pf_suddendeath"):GetBool() then
                    net.Start("playfight_round_winner")
                    net.WriteString("pf_reserved_suddendeath")

                    net.Broadcast()

                    playfight_isSuddenDeath = true

                    
                else
                    net.Start("playfight_round_winner")
                    net.WriteString("pf_reserved_draw")
                    net.Broadcast()
                end
            end

            for k,v in next, player.GetAll() do
                v:Freeze(true)
            end

            if timer.Exists("__playfightRumblequestionnewRoundDRAW__") then
                timer.Stop("__playfightRumblequestionnewRoundDRAW__")
                timer.Remove("__playfightRumblequestionnewRoundDRAW__")
            end
            timer.Pause("__ident1fier____RoUnd_playfight____timerrr___")

            local endTimer = 8

            if playfight_isSuddenDeath then
                endTimer = 3
            end

            net.Start("playfight_client_playsound")
            net.WriteString("battery_pickup.wav")
            net.Broadcast()

            net.Start("playfight_client_playsound")
            net.WriteString("bell.wav")
            net.Broadcast()

            timer.Create("__playfightRumblequestionnewRoundDRAW__", 3, 1, function()
                
                -- Clean up map
                net.Start("playfight_round_winner")
                net.WriteString("")
                net.Broadcast()

                game.CleanUpMap()

                -- Play round start sound
                net.Start("playfight_client_playsound")
                net.WriteString("suitchargeok1.wav")
                net.Broadcast()

                -- Grace Period
                playfight_is_grace_period = true

                PlayFightCountGracePeriod(playfight_grace_period_length)

                timer.Create("playfight_timer_grace_period_disable", playfight_grace_period_length, 1, function()
                    playfight_is_grace_period = false
                end)

                for k,v in next, player.GetAll() do

                    v.ragfall = nil

                    if v:Health() > 0 then
                        v:Spawn()
                    end

                    v:Freeze(false)
                    v.fell = 0
                    v:StripWeapons()
                    if v.toModel ~= nil then
                        v:SetModel(v.toModel)
                    end

                    if playfight_isSuddenDeath then
                        v:SetHealth(1)
                    end

                    -- Teleport player to random spawn point
                    if #ents.FindByClass("info_player_start") > 0 then
                        local spawnSelection = math.random(1, #ents.FindByClass("info_player_start"))

                        for i, value in pairs(ents.FindByClass("info_player_start")) do
                            if i == spawnSelection then
                                v:SetPos(value:GetPos())
                            end
                        end
                    end

                    if table.HasValue(playfight_server_menu_info, v) then
                        v:KillSilent()
                        v:Spectate(OBS_MODE_ROAMING)

                        print("player was still in menu")
                    end

                end

                SetGlobalInt("__ident1fier____Warmup_time_playfight__", 300)
                timer.UnPause("__ident1fier____RoUnd_playfight____timerrr___")
            end)
        end

    end)

end

    -- We here at [redacted]™ take pride in our excellent documentation and readability for variable names.
    hook.Add("PlayerSpawn", "__p__la_yerI__niti__Spa__NW__Ns____nns___", function( ply )
        if ply:IsValid() then
            if ( ply.isSpawnedd == nil or ply.isSpawnedd == NULL) then
                if !ply.shouldSpec then
                    ply:Spectate( OBS_MODE_CHASE )
                    ply.isSpawnedd = true
                    local timerInc = 1

                    if uiCams[1] ~= nil then
                        ply:SetPos(uiCams[1])
                        ply:SetEyeAngles(camAngles[1])

                        timerInc = timerInc + 1

                        timer.Create("TiIImner__camAngles"..ply:Nick(), 11, 0, function()
                            if ply ~= nil and ply:IsValid() and uiCams[1] ~= nil then
                                if (  table.HasValue(playfight_server_menu_info, ply) ) then
                                    ply:SetPos(uiCams[timerInc])
                                    ply:SetEyeAngles(camAngles[timerInc])

                                    if ( timerInc + 1 > #uiCams) then

                                        timerInc = 1

                                    else

                                        timerInc = timerInc + 1

                                    end
                                end
                            end
                        end) 
                    end
                end
            end
        end
    end)
end



-- If there's only one player alive, that player wins.
hook.Add("PostPlayerDeath", "__PlayFight_ma1n_l00psbrother_", function( ply, inflictor, attacker )
    if (GetGlobalBool("__ident1fier____Warmup_playfight__") == false) then
        
        local alivePly = {}

        for k,v in next, player.GetAll() do
            if v:Alive() then
                table.insert(alivePly, v:Nick())
            end
            if v.toModel ~= nil then
                v:SetModel(v.toModel)
            end
        end

        if (#alivePly == 1 ) then
            net.Start("playfight_round_winner")
            net.WriteString(alivePly[1])
            net.Broadcast()
            for k,v in next, player.GetAll() do
                v:Freeze(true)

                if v:Alive() then
                    if v.wins == nil then
                        v.wins = 1
                    else
                        v.wins = v.wins + 1
                    end
                end

                PlayfightSendTabInfo(v)
            end

            if timer.Exists("__playfightRumblequestionnewRound__") then
                timer.Stop("__playfightRumblequestionnewRound__")
                timer.Remove("__playfightRumblequestionnewRound__")
            end
            
            net.Start("playfight_client_playsound")
            net.WriteString("bell.wav")
            net.Broadcast()

            timer.Create("__playfightRumblequestionnewRound__", 8, 1, function()
                local canStartNewRound = 0

                for k, v in next, player.GetAll() do
                    if v.wins ~= nil and v.wins >= GetConVar("pf_bestof"):GetInt() then
                        canStartNewRound = 1
                    end
                end
                
                if canStartNewRound == 0 then
                    playfight_isSuddenDeath = false

                    -- Clean up map
                    net.Start("playfight_round_winner")
                    net.WriteString("")
                    net.Broadcast()

                    print("Map cleaned")

                    game.CleanUpMap()

                    net.Start("playfight_client_playsound")
                    net.WriteString("suitchargeok1.wav")
                    net.Broadcast()

                    -- Grace Period
                    playfight_is_grace_period = true

                    PlayFightCountGracePeriod(playfight_grace_period_length)

                    timer.Create("playfight_timer_grace_period_disable", playfight_grace_period_length, 1, function()
                        playfight_is_grace_period = false
                    end)

                    for k,v in next, player.GetAll() do

                        v.ragfall = nil
                        v:Spawn()
                        v:Freeze(false)
                        v.fell = 0
                        v:StripWeapons()
                        if v.toModel ~= nil then
                            v:SetModel(v.toModel)
                        end

                        -- Teleport player to random spawn point
                        if #ents.FindByClass("info_player_start") > 0 then
                            local spawnSelection = math.random(1, #ents.FindByClass("info_player_start"))

                            for i, value in pairs(ents.FindByClass("info_player_start")) do
                                if i == spawnSelection then
                                    v:SetPos(value:GetPos())
                                end
                            end
                        end
                    end

                    for k,v in next, ents.GetAll() do
                        if v:GetClass() == "info_target" or v:GetClass() == "info_player_start" then
                            v:Remove()
                        end
                    end

                    SetGlobalInt("__ident1fier____Warmup_time_playfight__", 300)
                    
                    -- Add one to the current round
                    playfight_currentRound = playfight_currentRound + 1

                    -- Send info to client
                    net.Start("playfight_getround")
                    net.WriteFloat(playfight_currentRound)
                    net.Broadcast()
                else

                    local playerWin = 0
                    local playerName = ""

                    -- Get player with most wins
                    for k,ply in next, player.GetAll() do
                        if playerWin == 0 then
                            if ply.wins ~= nil then
                                playerWin = ply.wins
                                playerName = ply:GetName()
                            end
                        else
                            if ply.wins ~= nil then
                                if ply.wins > playerWin then
                                    playerWin = ply.wins
                                    playerName = ply:GetName()
                                end
                            end
                        end

                        PlayfightSendTabInfo(ply)
                    end

                    net.Start("playfight_mapinfo")
                    net.WriteFloat(#playfight_mapsinstalled)

                    -- Iterate through each map and send it to the client.
                    for k,v in next, playfight_mapsinstalled do
                        net.WriteString(v)
                    end

                    net.Broadcast()


                    net.Start("playfight_round_winner")
                    net.WriteString("Game end, " .. playerName)
                    net.Broadcast()

                    SetGlobalInt("__ident1fier____Warmup_time_playfight__", 15)

                    timer.Create("__PlayFight_SwitchMap_Timer__", 1, 0, function()
                        SetGlobalInt("__ident1fier____Warmup_time_playfight__", GetGlobalInt("__ident1fier____Warmup_time_playfight__", 15) - 1)
                    end)

                    timer.Create("__PlayFight_SwitchMap__", 15, 1, function()
                        local winningMaps = {}
                        local maxVotes = max(playfight_mapvotes)

                        for i = 1, #playfight_mapvotes do
                            if playfight_mapvotes[i] == maxVotes then
                                table.insert(winningMaps, playfight_mapsinstalled[i])
                            end
                        end

                        local mapToChange = math.random(1, #winningMaps)

                        print("map to change: " .. mapToChange)

                        RunConsoleCommand( "changelevel", winningMaps[mapToChange] )
                    end)
                end
            end)
        end
    end
end)
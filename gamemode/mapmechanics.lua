-- This is called right after the game has processed all the map entities. This is responsible for using the weapon_spawn to remove them from the world and take note
-- of their positions for weapon spawning.
-- For info on mapping for this gamemode, check here: (insert youtube link when i make the guide video here)

local wepsTable = {}


local defaultWeaponDelay = 5

local weaponDelay = defaultWeaponDelay
local currentWeaponDelay = weaponDelay

playfight_isSuddenDeath = false

playfight_kills_list = playfight_kills_list or {}

-- Table of weapons and their randomization weight respectively
playfight_weapons_table = {
    weapon_shotgun = 5,
    weapon_357 = 5,
    throwable_crowbar = 5,
    hitscan_crossbow = 5,
    ricochet_disk = 5
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

    -- If this map has no weapon spawns, use the player start positions.
    if #wepsTable == 0 then
        print("No weapon spawns found, using player start positions. This map may not be fully supported, but should work.")
        for k, v in next, ents.GetAll() do
            if v:GetClass() == "info_player_start" then
                table.insert(wepsTable, v:GetPos())
            end
        end
    end

    if #wepsTable == 0 then
        print("No weapon spawns found, using CS spawn entities. This map may not be fully supported, but should work.")
        for k, v in next, ents.GetAll() do
            if v:GetClass() == "info_player_terrorist" or v:GetClass() == "info_player_counterterrorist" then
                table.insert(wepsTable, v:GetPos())
            end
        end
    end

    -- Clears spectator list for all players who hit didn't hit spectate on the main menu and sends a packet to the clients about their spectate status.
    function playfight_clearspectators()
        for k, v in next, player.GetAll() do
            if table.HasValue(playfight_players_spectating, v) and v.spectatingGame ~= true then
                table.RemoveByValue(playfight_players_spectating, v)

                net.Start("playfight_client_spectate_info")
                net.WriteBool(false)
                net.Send(v);
            end
        end
    end


-- This codebase dates back to about january 2018 and I'm not sure why I decided to do it this way.
-- I have no idea why I am storing these as global variables with a method instead of just... setting them.
-- (Also an example of professional naming conventions)

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

            if #wepsTable > 0 then
                local wepSpawn = nil

                wepSpawn = ents.Create(weaponWeightTable[wepChoose])

                wepSpawn:SetPos(wepsTable[posChoose])

                wepSpawn:Spawn()
                wepSpawn:Activate()

                currentWeaponDelay = weaponDelay

            end
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
            local shouldCountDown = player.GetCount() - playMenus > 1
            if playfight_current_gamemode == 1 then
                shouldCountDown = team.NumPlayers(0) > 0 and team.NumPlayers(1) > 0
            end

            if ( shouldCountDown and GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) >= 0) then
                SetGlobalInt("__ident1fier____Warmup_time_playfight__", GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) - 1)
                if (GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) <= 0) then
                    

                    for k,v in next, player.GetAll() do
                        v:Freeze(true)
                    end

                    -- Time in seconds till the game starts
                    local timeTillStart = 5

                    -- Start round after 5 seconds
                    timer.Simple(timeTillStart, function()
                        -- Start round now
                        playfight_clearspectators()

                        SetGlobalInt("__ident1fier____Warmup_time_playfight__", 300)
                        SetGlobalBool("__ident1fier____Warmup_playfight__", false)

                        game.CleanUpMap()

                        for k,v in next, player.GetAll() do
                            v:Freeze(false)

                            SetSuper(v, 0)
                            v.cansuper = 0
                            v.useenergy = 0

                            if v.spectatingGame ~= true then
                                v.spectatedPlayer = nil
                                v.ragfall = nil
                                v:Spawn()
                                v.fell = 0
                                v:StripWeapons()

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
                        end
                        
                        

                        -- Play round start sound
                        net.Start("playfight_client_playsound")
                        net.WriteString("suitchargeok1.wav")
                        net.Broadcast()

                        -- Play music
                        //net.Start("playfight_client_play_music")
                        //net.Broadcast()

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
                    net.WriteString("Sudden Death!")
                    net.WriteString("") -- Dummy data
                    net.WriteInt(2, 32)
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.WriteString("") -- Dummy data

                    net.Broadcast()

                    playfight_isSuddenDeath = true

                    
                else
                    net.Start("playfight_round_winner")
                    net.WriteString("Draw!")
                    net.WriteString("") -- Dummy data
                    net.WriteInt(2, 32)
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.Broadcast()
                end
            end

            for k,v in next, player.GetAll() do
                playfight_player_reset_round_stats(v)
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
                net.WriteString("") -- Empty data so the client hides the round end screen
                net.WriteString("") -- Dummy data
                net.WriteInt(0, 32) -- Dummy data
                net.WriteInt(0, 32) -- Dummy data
                net.WriteInt(0, 32) -- Dummy data
                net.WriteInt(0, 32) -- Dummy data
                net.WriteInt(0, 32) -- Dummy data
                net.WriteString("") -- Dummy data
                net.WriteString("") -- Dummy data
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
                    v:Freeze(false)

                    SetSuper(v, 0)
                    v.cansuper = 0
                    v.useenergy = 0

                    if v.spectatingGame ~= true then
                        v.spectatedPlayer = nil
                        v.ragfall = nil

                        if v:Health() > 0 then
                            v:Spawn()
                        end

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
                        end
                    end
                end

                playfight_clearspectators()

                SetGlobalInt("__ident1fier____Warmup_time_playfight__", 300)
                timer.UnPause("__ident1fier____RoUnd_playfight____timerrr___")
            end)
        end

    end)

end

    -- We here at [redacted]™ take pride in our excellent documentation and code readability.
    hook.Add("PlayerSpawn", "__p__la_yerI__niti__Spa__NW__Ns____nns___", function( ply )
        net.Start("playfight_client_team_win_update")
        net.WriteInt(0, 18) -- Team ID
        net.WriteInt(team.GetScore(0), 18) -- Team Wins
        net.Broadcast()

        net.Start("playfight_client_team_win_update")
        net.WriteInt(1, 18) -- Team ID
        net.WriteInt(team.GetScore(1), 18) -- Team Wins
        net.Broadcast()

        if ply:IsValid() then
            if ( ply.isSpawnedd == nil or ply.isSpawnedd == NULL) then
                if !ply.shouldSpec then
                    ply:Spectate( OBS_MODE_CHASE )
                    ply.isSpawnedd = true
                    local timerInc = 1

                    timer.Simple(0, function()
                        if uiCams[1] ~= nil then

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
                    end)
                end
            end
        end
    end)
end

playfight_round_should_end = false
playfight_round_end_ply = nil
playfight_round_end_inflictor = nil
playfight_round_end_attacker = nil

hook.Add("Tick", "playfight_roundend_tick_timer", function()
    if playfight_round_should_end then
        
        if GetGlobalBool("__ident1fier____Warmup_playfight__") == false then
            local alivePly = {}
    
            for k,v in next, player.GetAll() do
                if v:Alive() then
                    table.insert(alivePly, v:Nick())
                end
                if v.toModel ~= nil then
                    v:SetModel(v.toModel)
                end
            end
    
            local alivePlayerEntities = {}
    
            for k,v in next, player.GetAll() do
                if v:Alive() then
                    table.insert(alivePlayerEntities, v)
                end
            end
    
            local aliveTeams = 0
            local winnerTeam = -1;
    
            for k, v in next, team.GetPlayers(0) do
                if v:Alive() then
                    aliveTeams = aliveTeams + 1
                    winnerTeam = 0
                    break
                end
            end
    
            for k, v in next, team.GetPlayers(1) do
                if v:Alive() then
                    aliveTeams = aliveTeams + 1
                    winnerTeam = 1
                    break
                end
            end
    
            local doSuddenDeath = false

            -- If all players died, draw
            if (playfight_current_gamemode == 0 and #alivePly == 0) or (playfight_current_gamemode == 1 and aliveTeams == 0) then
                -- If sudden death is enabled, do it
                if GetConVar("pf_suddendeath"):GetBool() then
                    net.Start("playfight_round_winner")
                    net.WriteString("Sudden Death!")
                    net.WriteString("") -- Dummy data
                    net.WriteInt(2, 32)
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.WriteString("") -- Dummy data

                    net.Broadcast()

                    playfight_isSuddenDeath = true
                    doSuddenDeath = true
                    
                else
                    net.Start("playfight_round_winner")
                    net.WriteString("Draw!")
                    net.WriteString("") -- Dummy data
                    net.WriteInt(2, 32)
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.Broadcast()
                end
            end

            -- If only one player/team is alive, they win
            if (playfight_current_gamemode == 0 and #alivePly == 1) or (playfight_current_gamemode == 1 and aliveTeams == 1) then
                if playfight_current_gamemode == 0 then
                    net.Start("playfight_round_winner")
    
                    local playerName = "";
                    local playerSteamID = "";
    
                    if #alivePlayerEntities > 0 and alivePlayerEntities[1] ~= nil and alivePlayerEntities[1]:IsValid() then
                        playerName = alivePlayerEntities[1]:Nick()
                        playerSteamID = alivePlayerEntities[1]:SteamID()
                    end
    
                    local plyWhoWon = alivePlayerEntities[1]
    
                    if plyWhoWon.roundKills == nil then
                        plyWhoWon.roundKills = 0
                    end
    
                    if plyWhoWon.roundDmg == nil then
                        plyWhoWon.roundDmg = 0
                    end
    
                    net.WriteString(playerName)
                    net.WriteString(playerSteamID) -- Player SteamID, dummy data
                    net.WriteInt(0, 32) -- Tell the client to show the player winner screen
                    net.WriteInt(math.floor(plyWhoWon.roundKills), 32) -- Dummy data
                    net.WriteInt(math.floor(plyWhoWon.roundDmg), 32) -- Dummy data
                    net.WriteInt(math.floor(plyWhoWon:Health()), 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.WriteString(playfight_get_round_funfact())
    
                    net.Broadcast()
                elseif playfight_current_gamemode == 1 then
                    net.Start("playfight_round_winner")
                    net.WriteString(team.GetName(winnerTeam))
                    net.WriteString("") -- Player SteamID, dummy data
                    net.WriteInt(1, 32) -- Tell the client to show the team winner screen
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(winnerTeam, 32) -- Team ID
                    local mvpName = "nil"
                    if playfight_team_get_mvp(winnerTeam) ~= nil and playfight_team_get_mvp(winnerTeam):IsValid() and playfight_team_get_mvp(winnerTeam):IsPlayer() then
                        mvpName = playfight_team_get_mvp(winnerTeam):Nick()
                    end
                    net.WriteString(mvpName)
                    net.WriteString(playfight_get_round_funfact())
    
                    net.Broadcast()
                end
    
                -- Increment team score
                if playfight_current_gamemode == 1 then
                    team.AddScore(winnerTeam, 1)
                end
            end

            for k,v in next, player.GetAll() do
                playfight_player_reset_round_stats(v)
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

                    if !doSuddenDeath then
                        playfight_isSuddenDeath = false
                    end

                    -- Clean up map
                    net.Start("playfight_round_winner")
                    net.WriteString("") -- Empty data so the client hides the round end screen
                    net.WriteString("") -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteInt(0, 32) -- Dummy data
                    net.WriteString("") -- Dummy data
                    net.WriteString("") -- Dummy data
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
                        v:Freeze(false)

                        SetSuper(v, 0)
                        v.cansuper = 0
                        v.useenergy = 0

                        if v.spectatingGame ~= true then
                            v.spectatedPlayer = nil
                            v.ragfall = nil
                            v:Spawn()
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

                            if playfight_isSuddenDeath then
                                v:SetHealth(1)
                            end
                        end
                    end

                    for k,v in next, ents.GetAll() do
                        if v:GetClass() == "info_target" then
                            v:Remove()
                        end
                    end

                    playfight_clearspectators()

                    SetGlobalInt("__ident1fier____Warmup_time_playfight__", 300)
                    
                    -- Add one to the current round
                    playfight_currentRound = playfight_currentRound + 1

                    -- Send info to client
                    net.Start("playfight_getround")
                    net.WriteFloat(playfight_currentRound)
                    net.Broadcast()
                else
                    playfight_end_game()
                    print("game end")
                end
            end)
        end

        playfight_round_should_end = false
        round_end_ply = nil
        round_end_inflictor = nil
        round_end_attacker = nil
    end
end)

-- If there's only one player/team alive, that player/team wins.
hook.Add("PostPlayerDeath", "__PlayFight_ma1n_l00psbrother_", function( ply, inflictor, attacker )
    playfight_round_should_end = true
    round_end_ply = ply
    round_end_inflictor = inflictor
    round_end_attacker = attacker
end)

local function switchmaps()
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
end

function playfight_team_get_mvp(teamIndex)
    local mvp = nil
    local highestMvpScore = 0;
    for k, v in next, player.GetAll() do
        if v:Team() == teamIndex then
            if v.roundDmg == nil then
                v.roundDmg = 0
            end

            if v.roundKills == nil then
                v.roundKills = 0
            end

            local mvpScore = v.roundDmg + v.roundKills

            if mvp == nil then
                mvp = v
            else
                if mvpScore > highestMvpScore then
                    mvp = v
                end
            end
        end
    end

    return mvp
end

function playfight_player_reset_round_stats(player)
    player.roundDmg = 0;
    player.roundKills = 0;
    player.timesRagdolled = 0;
    player.timesSupered = 0;
    player.weaponsPickedUp = 0;
    player.dmgUsingDisk = 0;
end

function playfight_get_round_funfact()
    possibleFacts = {}

    -- Most ragdolls
    local playerMostRagdolls = nil
    for k, v in next, player.GetAll() do 
        v.timesRagdolled = v.timesRagdolled or 0
        if playerMostRagdolls == nil then
            playerMostRagdolls = v
        else
            if v.timesRagdolled > playerMostRagdolls.timesRagdolled then
                playerMostRagdolls = v
            end
        end
    end

    table.insert(possibleFacts, playerMostRagdolls:Nick().." ragdolled "..playerMostRagdolls.timesRagdolled.." times.")

    -- Player got an ace
    if playfight_current_gamemode == 0 then
        for k, v in next, player.GetAll() do
            v.roundKills = v.roundKills or 0
            if v.roundKills >= player.GetCount() - 1 then
                table.insert(possibleFacts, v:Nick() .. " killed 100% of the players that round.")
            end
        end
    end

    if playfight_current_gamemode == 1 then
        for k, v in next, player.GetAll() do
            v.roundKills = v.roundKills or 0
            if v:Team() ~= nil and v.roundKills >= player.GetCount() - #team.GetPlayers(v:Team()) then
                table.insert(possibleFacts, v:Nick() .. " killed 100% of the players that round.")
            end
        end
    end

    -- Most weapons
    local playerMostWeapons = nil
    for k, v in next, player.GetAll() do 
        v.weaponsPickedUp = v.weaponsPickedUp or 0
        if playerMostWeapons == nil then
            playerMostWeapons = v
        else
            if v.weaponsPickedUp > playerMostWeapons.weaponsPickedUp then
                playerMostWeapons = v
            end
        end
    end

    table.insert(possibleFacts, playerMostWeapons:Nick().." picked up "..playerMostWeapons.weaponsPickedUp.." weapon(s) that round.")

    -- Most damage
    local playerMostDmg = nil
    for k, v in next, player.GetAll() do 
        v.roundDmg = v.roundDmg or 0
        if playerMostDmg == nil then
            playerMostDmg = v
        else
            if v.roundDmg > playerMostDmg.roundDmg then
                playerMostDmg = v
            end
        end
    end

    table.insert(possibleFacts, playerMostDmg:Nick().." did "..playerMostDmg.roundDmg.." damage that round.")

    -- Most supers
    local playerMostSupers = nil
    for k, v in next, player.GetAll() do 
        v.timesSupered = v.timesSupered or 0
        if playerMostSupers == nil then
            playerMostSupers = v
        else
            if v.timesSupered > playerMostSupers.timesSupered then
                playerMostSupers = v
            end
        end
    end

    table.insert(possibleFacts, playerMostSupers:Nick().." used their super "..playerMostSupers.timesSupered.." times that round.")

    -- Most ricochet disk damage
    local playerMostDiskDmg = nil
    for k, v in next, player.GetAll() do 
        v.dmgUsingDisk = v.dmgUsingDisk or 0
        if playerMostDiskDmg == nil then
            playerMostDiskDmg = v
        else
            if v.dmgUsingDisk > playerMostDiskDmg.dmgUsingDisk then
                playerMostDiskDmg = v
            end
        end
    end

    if playerMostDiskDmg.dmgUsingDisk > 0 then
        table.insert(possibleFacts, playerMostDiskDmg:Nick().." did "..playerMostDiskDmg.dmgUsingDisk.." damage with ricochet disks that round.")
    end
    return possibleFacts[math.random(1, #possibleFacts)]
end

function playfight_end_game()
    -- End game
    local playerWin = 0
    local playerName = "nobody"

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

    -- Get team with most wins
    local winningTeam = 0

    if team.GetScore(1) > team.GetScore(0) then
        winningTeam = 1 
    end

    net.Start("playfight_mapinfo")
    net.WriteFloat(#playfight_mapsinstalled)

    -- Iterate through each map and send it to the client.
    for k,v in next, playfight_mapsinstalled do
        net.WriteString(v)
    end

    net.Broadcast()


    net.Start("playfight_round_winner")
    if playfight_current_gamemode == 1 then
        net.WriteString("Game end, " .. team.GetName(winningTeam) .. " won!")
    else
        net.WriteString("Game end, " .. playerName .. " won!")
    end
    net.WriteString("") -- Dummy data
    net.WriteInt(2, 32) -- Dummy data
    net.WriteInt(0, 32) -- Dummy data
    net.WriteInt(0, 32) -- Dummy data
    net.WriteInt(0, 32) -- Dummy data
    net.WriteInt(0, 32) -- Dummy data
    net.WriteString("") -- Dummy data
    net.WriteString("") -- Dummy data
    net.Broadcast()

    SetGlobalInt("__ident1fier____Warmup_time_playfight__", 30)

    timer.Create("__PlayFight_SwitchMap_Timer__", 1, 0, function()
        SetGlobalInt("__ident1fier____Warmup_time_playfight__", GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30) - 1)

        if playfight_everyonevoted ~= nil and playfight_everyonevoted == true then
            switchmaps()
        end
    end)

    timer.Create("__PlayFight_SwitchMap__", 30, 1, function()
        switchmaps()
    end)

    playfight_game_ended = true
end

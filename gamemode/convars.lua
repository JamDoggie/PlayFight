-- Debug command, lets you set the current round timer. Works no matter if you're in warmup or not.
-- REQUIRES: sv_cheats 1
concommand.Add("pf_seconds", function( ply, cmd, args )
    if GetConVar("sv_cheats"):GetBool() then
        SetGlobalInt("__ident1fier____Warmup_time_playfight__", tonumber(args[1]))
    end
end)

-- Debug command, ends the game.
-- REQUIRES: sv_cheats 1
concommand.Add("pf_endgame", function( ply, cmd, args )
    
    if GetConVar("sv_cheats"):GetBool() then
        playfight_end_game()
    end
end)

-- Debug command, starts the game.
-- REQUIRES: sv_cheats 1
concommand.Add("pf_startgame", function( ply, cmd, args )
    
    if GetConVar("sv_cheats"):GetBool() then
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
 
                        local botEnt = ents.Create("playfight_bot")
                        botEnt:Spawn()

                        -- Teleport bot to random spawn point
                        if #ents.FindByClass("info_player_start") > 0 then
                            local spawnSelection = math.random(1, #ents.FindByClass("info_player_start"))

                            for i, value in pairs(ents.FindByClass("info_player_start")) do
                                if i == spawnSelection then
                                    botEnt:SetPos(value:GetPos())
                                end
                            end
                        end
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
                    
end)

-- Debug command, shows the hulltrace used to test if the place the player's in is valid to spawn in when the player gets out of ragdoll
-- When the hulltrace collides with nothing, that means that the position is safe and it is stored as a lastpos variable.
-- REQUIRES: sv_cheats 1
concommand.Add("pf_drawlastvalidpos", function( ply, cmd, args )
    if GetConVar("sv_cheats"):GetBool() and #args > 0 then
        if args[1] == "0" then
            ply.showlastpos = 0
        elseif args[1] == "1" then
            ply.showlastpos = 1
        end
    end
end)

-- Sets the client who called it's super
-- REQUIRES: sv_cheats 1
concommand.Add("pf_setsuper", function( ply, cmd, args )
    if GetConVar("sv_cheats"):GetBool() and #args > 0 then
        
        SetSuper(ply, tonumber(args[1]))
        
    end
end)

-- Sets the current round. The internal variable starts at 0, but the display starts at 1 so setting it to 1 will set the ingame visual to 2 etc.
concommand.Add("pf_setround", function( ply, cmd, args )
    -- Set the current round
    if GetConVar("sv_cheats"):GetBool() then
        playfight_currentRound = args[1]
        -- Send info to client
        net.Start("playfight_getround")
        net.WriteFloat(playfight_currentRound)
        net.Broadcast()
    end
end)

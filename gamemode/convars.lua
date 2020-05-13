-- Debug command, lets you set the current round timer. Works no matter if you're in warmup or not.
-- REQUIRES: sv_cheats 1
concommand.Add("pf_seconds", function( ply, cmd, args )
    if GetConVar("sv_cheats"):GetBool() then
        SetGlobalInt("__ident1fier____Warmup_time_playfight__", tonumber(args[1]))
    end
end)

-- Debug command, ends the game. (Not supported, buggy i think)
-- REQUIRES: sv_cheats 1
concommand.Add("pf_endgame", function( ply, cmd, args )
    
    if GetConVar("sv_cheats"):GetBool() then
        net.Start("playfight_mapinfo")
        net.WriteFloat(#playfight_mapsinstalled)

        -- Iterate through each map and send it to the client.
        for k,v in next, playfight_mapsinstalled do
            net.WriteString(v)
        end

        net.Broadcast()

        net.Start("playfight_round_winner")
        net.WriteString("Game end, nobody")
        net.Broadcast()
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
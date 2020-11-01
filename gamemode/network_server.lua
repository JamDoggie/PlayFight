util.AddNetworkString("playfight_player_start_play")
util.AddNetworkString("playfight_player_start_spectate")
util.AddNetworkString("playfight_round_winner")
util.AddNetworkString("playfight_hurtsound")
util.AddNetworkString("playfight_change_playermodel")
util.AddNetworkString("playfight_stunupdate")
util.AddNetworkString("playfight_client_showdamage")
util.AddNetworkString("playfight_request_winloss")
util.AddNetworkString("playfight_get_winloss")
util.AddNetworkString("playfight_getround")
util.AddNetworkString("playfight_mapinfo")
util.AddNetworkString("playfight_send_kills")
util.AddNetworkString("playfight_server_voteinfo")
util.AddNetworkString("playfight_client_voteinfo")
util.AddNetworkString("playfight_client_playsound")
util.AddNetworkString("playfight_client_showlastpos")
util.AddNetworkString("playfight_client_supercharging")

util.AddNetworkString("playfight_client_screenmessage")
util.AddNetworkString("playfight_client_playerdisconnect")
util.AddNetworkString("playfight_client_graceperiod_count")
util.AddNetworkString("playfight_client_player_menu")
util.AddNetworkString("playfight_client_play_music")
util.AddNetworkString("playfight_client_join_game")
util.AddNetworkString("playfight_client_spectate_info")
util.AddNetworkString("playfight_client_spectate_player_name")
util.AddNetworkString("playfight_client_spectate_player_healthsuper")
util.AddNetworkString("playfight_client_request_kills")
util.AddNetworkString("playfight_client_killfeed")

-- Gamemode voting
util.AddNetworkString("playfight_gamemode_vote") -- Sent to clients to tell the clients to open the gamemode voting menu
util.AddNetworkString("playfight_gamemode_client_vote_info") -- Sent by clients to tell the server what gamemode they voted for
util.AddNetworkString("playfight_enter_menu") -- Sent by server to tell the client to open the player model selector

-- Teams
util.AddNetworkString("playfight_open_team_selection_screen") -- Sent by server to tell client to open the team selection screen
util.AddNetworkString("playfight_client_team_vote") -- Sent by client to tell the server what team the client is voting for

-- Scoreboard game state
util.AddNetworkString("playfight_client_score_gamestate")
util.AddNetworkString("playfight_client_team_win_update")

-- Death freeze cam(sending a true value shows and initializes it, sending a false value resets and hides it)
util.AddNetworkString("playfight_client_deathcam_html")

-- Fix for smooth nametags, tells the client the id of the ragdoll instead of just teleporting the nametag to the ragdoll
util.AddNetworkString("playfight_client_ragdoll")

playfight_server_menu_info = playfight_server_menu_info or {}

-- When the client hits the play or spectate button, send the player into the game.
net.Receive("playfight_player_start_play", function( len, ply )

    if ply:IsValid() and ply:IsPlayer() and table.HasValue(playfight_server_menu_info, ply) and !playfight_gamemode_voting then
        table.RemoveByValue(playfight_server_menu_info, ply)

        if GetGlobalBool("__ident1fier____Warmup_playfight__") == true then
            ply:Spectate(OBS_MODE_NONE)
            ply:UnSpectate()
            ply:Spawn()
        else
            ply:KillSilent()
            table.insert(playfight_players_spectating, ply)
        end

        net.Start("playfight_client_player_menu")
        net.WriteString(ply:SteamID())
        net.WriteBool(false)
        net.Broadcast()
    end

end)

net.Receive("playfight_player_start_spectate", function( len, ply )

    if ply:IsValid() and ply:IsPlayer() and table.HasValue(playfight_server_menu_info, ply) then
        table.RemoveByValue(playfight_server_menu_info, ply)

        ply:KillSilent()

        table.insert(playfight_players_spectating, ply)

        ply.spectatingGame = true

        net.Start("playfight_client_player_menu")
        net.WriteString(ply:SteamID())
        net.WriteBool(false)
        net.Broadcast()
    end

end)

-- For the scoreboard, send clients player wins and losses when it requests them.
net.Receive("playfight_request_winloss", function(len,ply)
    if ply:IsValid() and ply:IsPlayer() then

        net.Start("playfight_get_winloss")
        net.WriteFloat(#player.GetAll()) 
        for k,v in next, player.GetAll() do
            net.WriteString(v:SteamID())
            if v.wins ~= nil then
                net.WriteFloat(tonumber(v.wins))
            else
                net.WriteFloat(0)
            end
        end
        net.Send(ply)
    end
end)

net.Receive("playfight_change_playermodel", function(len, ply)
    local model = net.ReadString()
    if (GetGlobalBool("__ident1fier____Warmup_playfight__") == false) then
        ply.toModel = model
    else
        ply:SetModel(model)
    end
end)

net.Receive("playfight_server_voteinfo", function(len, ply)
    local mapIndex = math.floor(net.ReadFloat()) 
    if !(table.contains(playfight_playersvoted, ply:SteamID())) then
        playfight_mapvotes[mapIndex] = playfight_mapvotes[mapIndex] + 1
        table.insert(playfight_playersvoted, ply:SteamID())
        print(playfight_mapvotes[mapIndex])

        net.Start("playfight_client_voteinfo")
        net.WriteFloat(mapIndex)
        net.WriteFloat(playfight_mapvotes[mapIndex])
        net.Broadcast()

        if #playfight_playersvoted >= #player.GetAll() then
            playfight_everyonevoted = true
        end
    end
end)

net.Receive("playfight_client_request_kills", function(len, ply)
    if ply:IsValid() then
        net.Start("playfight_send_kills")
        
        local killsLength = 0

        for k, v in pairs(playfight_kills_list) do
            killsLength = killsLength + 1
        end

        net.WriteInt(killsLength, 15)


        for k, v in pairs(playfight_kills_list) do
            if k:SteamID() ~= nil and v ~= nil then
                net.WriteString(k:SteamID())
                net.WriteInt(v, 32)
            else
                net.WriteString("")
                net.WriteInt(0, 32)
            end
        end

        net.Send(ply)
    end
end)
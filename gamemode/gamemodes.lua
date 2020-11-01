playfight_gamemode_voting = false;
playfight_voting_onlyadmin = true;

playfight_players_needing_to_vote = playfight_players_needing_to_vote or {}

playfight_gamemode_player_votes = playfight_gamemode_player_votes or {}

playfight_current_gamemode = 0; -- 0 = FFA, 1 = Teams

if GetConVar("pf_admins_vote_gamemode"):GetBool() == true then
    
    playfight_gamemode_voting = true;

end

function playfight_send_gamestate(ply)
    net.Start("playfight_client_score_gamestate")

        -- Whether or not we are in teams mode
        if playfight_current_gamemode == 1 then
            net.WriteBool(true)

            net.WriteString(team.GetName(0)) -- Team one name
            net.WriteString(team.GetName(1)) -- Team two name

            local teamOneColor = team.GetColor(0);
            local teamTwoColor = team.GetColor(1);

            net.WriteString(teamOneColor.r..", "..teamOneColor.g..", "..teamOneColor.b) -- Team one color(in CSS friendly rgb string)
            net.WriteString(teamTwoColor.r..", "..teamTwoColor.g..", "..teamTwoColor.b) -- Team two color(in CSS friendly rgb string)
        else
            net.WriteBool(false)

            net.WriteString("")
            net.WriteString("")

            net.WriteString("")
            net.WriteString("")
        end

        net.Send(ply)

        print("sent game state")
end

function playfight_broadcast_gamestate()
    for k, ply in next, player.GetAll() do
        playfight_send_gamestate(ply)
    end
end

hook.Add("PlayerInitialSpawn", "playfight_gamemode_vote_send_hook", function( ply, transition )
    timer.Simple(0.1, function()
        if table.HasValue(playfight_players_needing_to_vote, ply:UserID()) == false and playfight_gamemode_voting == true then
            table.insert(playfight_players_needing_to_vote, ply:UserID())
        end
    end)

    if playfight_gamemode_voting == false then
        if playfight_current_gamemode == 0 then
            net.Start("playfight_enter_menu")
            net.Send(ply)
        elseif playfight_current_gamemode == 1 then
            net.Start("playfight_open_team_selection_screen")
            net.Send(ply)
        end

        playfight_send_gamestate(ply)
    end
end)

local toRemove = {}

hook.Add("Tick", "playfight_tick_event_gamemode_vote", function()
    for k, v in next, playfight_players_needing_to_vote do  
        local ply = Player(v)

        if ply ~= nil and ply:IsValid() and playfight_gamemode_voting == true then

            net.Start("playfight_gamemode_vote")

            -- Whether or not the player is voting. If it's false, it'll just display that the player is waiting.
            if (ply:IsAdmin() or ply:IsSuperAdmin() or ply:IsListenServerHost()) or !playfight_voting_onlyadmin then
                net.WriteBool(true)
            else
                net.WriteBool(false)
            end


            net.WriteBool(playfight_voting_onlyadmin) 
            

            table.insert(toRemove, v)

            net.Send(ply);
        end
    end

    for i = #playfight_players_needing_to_vote, 1, -1 do
        if table.HasValue(toRemove, playfight_players_needing_to_vote[i]) then
            table.RemoveByValue(playfight_players_needing_to_vote, playfight_players_needing_to_vote[i])
        end
    end

    toRemove = {}

    -- Now, deal with voting and stuff
    if playfight_gamemode_voting then
        -- Key is the gamemode id, value is the number of votes
        local voteTable = {}

        for k, v in next, playfight_gamemode_player_votes do 
            local voteTableContainsKey = false;
            
            for i, j in next, voteTable do
                if i == v then
                    voteTableContainsKey = true;
                end
            end

            if voteTableContainsKey then
                voteTable[v] = voteTable[v] + 1
            else
                voteTable[v] = 1
            end

        end

        local maxValue = 0;

        for k, v in next, voteTable do
            if v > maxValue then

                maxValue = v;

            end
        end

        local selectedModes = {}

        for k, v in next, voteTable do
            if v == maxValue then
                table.insert(selectedModes, k)
            end
        end

        local selectedGamemode = nil;

        if #selectedModes == 1 then
            selectedGamemode = selectedModes[1]
        elseif #selectedModes > 1 then
            local chosenMode = math.random(1, #selectedModes)
            selectedGamemode = selectedModes[chosenMode]
        end
            

        if selectedGamemode ~= nil then
            if selectedGamemode ~= 2 then
                if selectedGamemode == 0 then
                    net.Start("playfight_enter_menu")

                    net.Broadcast()

                    playfight_players_needing_to_vote = {}

                    playfight_gamemode_voting = false
                end

                if selectedGamemode == 1 then
                    net.Start("playfight_open_team_selection_screen")

                    net.Broadcast()

                    playfight_players_needing_to_vote = {}

                    playfight_gamemode_voting = false
                end

                playfight_current_gamemode = selectedGamemode;

                playfight_broadcast_gamestate()
            else
                net.Start("playfight_gamemode_vote")
                net.WriteBool(true)
                net.WriteBool(false)
                net.Broadcast()

                playfight_gamemode_player_votes = {}
            end
        end
        
    end
end)

net.Receive("playfight_gamemode_client_vote_info", function(len, ply)
    gamemodeId = net.ReadInt(8)

    local playerAlreadyVoted = false;

    for k, v in next, playfight_gamemode_player_votes do
        if k == ply then
            playerAlreadyVoted = true;
        end
    end

    if !playerAlreadyVoted and playfight_gamemode_voting and (!playfight_voting_onlyadmin or (ply:IsAdmin() or ply:IsSuperAdmin() or ply:IsListenServerHost())) then
        if gamemodeId == 0 or gamemodeId == 1 then
            print("recieved gamemode vote")
            playfight_gamemode_player_votes[ply] = gamemodeId
        end

        -- This is the ID for the vote button, only allow them to vote this if they're admin and it's admin only vote currently.
        if gamemodeId == 2 then
            if playfight_voting_onlyadmin and (ply:IsAdmin() or ply:IsSuperAdmin() or ply:IsListenServerHost()) then
                print("recieved gamemode vote to let users vote")
                playfight_gamemode_player_votes[ply] = gamemodeId
            end
        end
    end
end)



net.Receive("playfight_client_team_vote", function( len, ply )
    if playfight_current_gamemode == 1 then
        local selectedTeam = net.ReadInt(8)

        if team.NumPlayers(selectedTeam) ~= nil and (team.NumPlayers(selectedTeam) < GetConVar("pf_team_size"):GetInt() or GetConVar("pf_team_size"):GetInt() == -1) then
            ply:SetTeam(selectedTeam)
            timer.Simple(0.1, function()
                net.Start("playfight_enter_menu")
                net.Send(ply)
            end)
        end
    end
end)
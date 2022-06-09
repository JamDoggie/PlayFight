
-- Scoreboard
playfight_scoreboard = playfight_scoreboard or {}

net.Receive("playfight_get_winloss", function(len, ply)
    local playerNum = math.floor(net.ReadFloat())
    for i = 1, playerNum do
        local steamID = net.ReadString()
        local wins = net.ReadFloat()
    end
end)

playfight_client_isteams = playfight_client_isteams or 0

playfight_client_player_wins = playfight_client_player_wins or {}
playfight_client_player_kills = playfight_client_player_kills or {}
-- When a player's avatar is grabbed from steam and loaded, it's cached here so we don't have to load it again.
playfight_client_player_avatars = playfight_client_player_avatars or {}

playfight_scoreboard_visible = false

playfight_scoreboard_html = playfight_scoreboard_html or vgui.Create("DHTML")
playfight_scoreboard_html:Dock( FILL )
playfight_scoreboard_html:OpenURL("http://jd.quintonswenski.com/Jamdoggie/tab_menu/index.html");
playfight_scoreboard_html:SetVisible(false)

playfight_scoreboard_html:AddFunction("playfight", "opensteamprofile", function(steamid)
    local ply = player.GetBySteamID(steamid)

    if ply ~= nil then
        ply:ShowProfile()
    end
end)

playfight_scoreboard_html:AddFunction("playfight", "togglemute", function(steamid)
    local ply = player.GetBySteamID(steamid)

    if ply ~= nil then
        ply:SetMuted(!ply:IsMuted())
    end
end)

function playfight_scoreboard:show()
    playfight_scoreboard_html:SetVisible(true)
    playfight_scoreboard_html:QueueJavascript("centerDiv.style.setProperty(\"width\", (vw * 40).toString() + \"px\");")
    playfight_scoreboard_html:QueueJavascript("centerDivBlue.style.setProperty(\"width\", (vw * 40).toString() + \"px\");")
    playfight_scoreboard_html:MoveToFront()
end

function playfight_scoreboard:hide()
    playfight_scoreboard_html:SetVisible(false)
    gui.EnableScreenClicker(false)
    playfight_scoreboard_html:QueueJavascript("centerDiv.style.setProperty(\"width\", \"0px\");")
    playfight_scoreboard_html:QueueJavascript("centerDivBlue.style.setProperty(\"width\", \"0px\");")
    playfight_scoreboard_html:MoveToBack()
end

hook.Add("KeyPress", "playfight_scoreboard_keypress", function(ply, key)
    if (key == IN_ATTACK2 and input.IsKeyDown(KEY_TAB)) then
        gui.EnableScreenClicker(true)
    end
end)

function GM:ScoreboardShow()
	playfight_scoreboard:show()

    net.Start("playfight_request_winloss")
    net.SendToServer()
end

function GM:ScoreboardHide()
	playfight_scoreboard:hide()
end

hook.Add("Tick", "__playfight_client_scoreboard_draw__", function()
    if playfight_scoreboard_html:IsVisible() then
        for k, v in next, player.GetAll() do
            local wins = 0
            if playfight_client_player_wins[v:SteamID()] ~= nil then
                wins = playfight_client_player_wins[v:SteamID()];
            end

            local kills = 0
            if playfight_client_player_kills[v:SteamID()] ~= nil then
                kills = playfight_client_player_kills[v:SteamID()];
            end

            local avatar = "";

            if player.GetBySteamID(v:SteamID()) then
                avatar = playfight_get_cached_avatar(v:SteamID(), v:SteamID64());
            end

            if !playfight_client_ismenu then
                local playerTeam = -1;

                if playfight_client_isteams != true then
                    playerTeam = 0;
                end

                if v:Team() ~= TEAM_UNASSIGNED then
                    playerTeam = v:Team()
                end

                playfight_scoreboard_html:QueueJavascript("updatePlayer(\""..avatar.."\", \""..v:GetName().."\", "..v:Health()..", "..wins..", "..kills..", "..v:Ping()..", \""..v:SteamID().."\", "..tostring(v:IsMuted())..", "..playerTeam..");")
            end
        end
    end
end)

-- Helper method for getting a player's avatar while also caching it. 
-- The function returns the avatar's url if it is already cached, and if it is not it returns a blank avatar url
-- Then, it requests the xml from steam's servers and parses the avatar out of it. If this is successful, it calls the httpFunction
-- while passing in the avatar that it got from steam. 
-- If you use this function, it is recommended to pass in a call back function to handle if the avatar is not already cached.
function playfight_get_cached_avatar(steamID, steamID64, httpFunction)
    local avatar = "";
    if playfight_client_player_avatars[steamID] == nil then
        http.Fetch( "https://steamcommunity.com/profiles/"..steamID64.."/?xml=1", function(xml, size, headers, code)
            avatar = string.match(xml, "<avatarFull><!%[CDATA%[(.-)%]%]></avatarFull>")
            playfight_client_player_avatars[steamID] = avatar;
            
            if httpFunction ~= nil then
                httpFunction(avatar)
                
            end
        end)
        playfight_client_player_avatars[steamID] = "";
    else
        avatar = playfight_client_player_avatars[steamID]
    end

    return avatar;
end

net.Receive("playfight_get_winloss", function(len, ply)
    local playerNum = math.floor(net.ReadFloat())
    for i = 1, playerNum do
        local steamID = net.ReadString()
        local wins = net.ReadFloat()

        playfight_client_player_wins[steamID] = wins;
    end
end)

net.Receive("playfight_client_playerdisconnect", function( len )
    local steamID64 = net.ReadString()

    playfight_scoreboard_html:QueueJavascript("removePlayer(\""..steamID64.."\");");
end)

net.Receive("playfight_send_kills", function(len)
   
    local steamID = net.ReadString()
    local kills = net.ReadInt(32)

    playfight_client_player_kills[steamID] = kills
    
end)

net.Receive("playfight_client_score_gamestate", function()
    local isTeams = net.ReadBool()

    playfight_client_isteams = isTeams

    local teamOneName = net.ReadString()
    local teamTwoName = net.ReadString()

    local teamOneColor = net.ReadString()
    local teamTwoColor = net.ReadString()

    playfight_scoreboard_html:QueueJavascript("setGameInfo("..tostring(isTeams)..", \""..teamOneName.."\", \""..teamTwoName.."\", \""..teamOneColor.."\", \""..teamTwoColor.."\")")
    
end)
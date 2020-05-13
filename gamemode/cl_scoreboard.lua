playfight_clientwins = 0
playfight_clientlosses = 0

playfight_clientplayers = playfight_clientplayers or {}
playfight_clientplayerwins = playfight_clientplayerwins or {}

--convienience function for screen scaling
local function ScrS()
    return math.Round(ScrH() / 768, 4) 
end

-- Scoreboard
playfight_scoreboard = playfight_scoreboard or {}

net.Receive("playfight_get_winloss", function(len, ply)
    local playerNum = math.floor(net.ReadFloat())
    for i = 1, playerNum do
        local steamID = net.ReadString()
        local wins = net.ReadFloat()

        playfight_clientplayers[i] = steamID
        playfight_clientplayerwins[i] = wins
    end
end)

local stripHeight = 30 * ScrS()

playfight_client_stripwidth = 500 * ScrS()
playfight_client_stripSize = 0

playfight_client_panels = playfight_client_panels or {}
playfight_client_userpictures = playfight_client_userpictures or {}

playfight_scoreboard_visible = false

hook.Add( "KeyPress", "__playfight_client_keypress_scoreboard_lerp__", function( ply, key )
	if ( key == IN_SCORE ) then
		playfight_client_stripSize = 0
	end
end )

hook.Add("HUDPaint", "__playfight_client_scoreboard_draw__", function()
    -- This is very questionable as if you change your tab bind, it'll still force you to use tab which will probably break things.
    -- I can't find a better way as simply doing LocalPlayer():IsKeyDown() only works if the round is going.
    if input.IsKeyDown(KEY_TAB) then
        for k,v in next, playfight_client_panels do
            local px, py = v:GetSize()
            v:SetSize(Lerp((0.05 * ScrS()) * FrameTime() * 250, px, playfight_client_stripwidth), stripHeight)
            local nx, ny = v:GetSize()
            v:SetPos(ScrW()/2 - (nx/2), (ScrH()/2 - (stripHeight/2) + (k*stripHeight)) - 300 * ScrS())
        end

        for k,v in next, playfight_client_userpictures do
            local strip = playfight_client_panels[k]
            local sx, sy = strip:GetSize()
            v:SetPos(ScrW()/2 - (sx/2), (ScrH()/2 - (stripHeight/2) + (k*stripHeight)) - 300 * ScrS())
        end

        -- Draw tool tip for showing mouse in tab
        draw.SimpleTextOutlined("Right click to show mouse", "PlayfightState", 530 * ScrS(), 90 * ScrS(), Color( 255, 255, 255, 80 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2 * ScrS(), Color( 0, 0, 0, 80 ))
    end

    

    stripHeight = 30 * ScrS()
    playfight_client_stripwidth = 500 * ScrS()
end)

function playfight_scoreboard:show()
    playfight_scoreboard_visible = true

    playfight_client_song_checkbox:Show()
    playfight_client_song_slider:Show()

	-- List
    local mainPanel = vgui.Create("DPanel")
    mainPanel:SetSize(ScrW(), ScrH())
    mainPanel:SetPos(0,0)

    mainPanel.Paint = function(s, w, h)
        -- Keep empty. We don't want to show this pane
    end

    for k,uuid in next, playfight_clientplayers do
        -- Display player's stats
        local tabStrip = vgui.Create("DPanel", mainPanel)
        tabStrip:SetPos(ScrW()/2 - (playfight_client_stripSize/2), (ScrH()/2 - (stripHeight/2) + (k*(stripHeight+3*ScrS()))) - 300 * ScrS())

        tabStrip.Paint = function(s, w, h)
            if ( FrameTime() ~= 0 ) then
                draw.RoundedBox(0, 0, 0, w, h, Color(66,66,66,255))
                draw.RoundedBox(0, 0, 0, w/5, h, Color(77,77,77,255))
            end
        end

        table.insert(playfight_client_panels, tabStrip)

        local userBox = vgui.Create("DPanel", mainPanel)
        userBox:SetPos(ScrW()/2 - (playfight_client_stripSize/2), (ScrH()/2 - (stripHeight/2) + (k*stripHeight)) - 300 * ScrS())
        userBox:SetSize(stripHeight, stripHeight)
        
        userBox.Paint = function(s, w, h)
            if ( FrameTime() ~= 0 ) then
                draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100,210))
            end
        end

        -- Display the user's profile picture
        local profileBox = vgui.Create("AvatarImage", userBox)
        profileBox:SetPos(2*ScrS(), 2*ScrS())
        profileBox:SetSize(stripHeight-(2*ScrS()), stripHeight-(2*ScrS()))

        -- Make invisible button that lets you click on the avatar to view the steam profile
        local profileButton = vgui.Create("DButton", userBox)
        profileButton:SetPos(2*ScrS(), 2*ScrS())
        profileButton:SetSize(stripHeight-(2*ScrS()), stripHeight-(2*ScrS()))

        profileButton.Paint = function(s, w, h)

        end

        profileButton:SetText("")

        profileButton.DoClick = function()
            if player.GetBySteamID(uuid) ~= false then
                player.GetBySteamID(uuid):ShowProfile()
            end
        end

        -- Only set profile picture if the player exists
        if player.GetBySteamID(uuid) ~= false then
            profileBox:SetPlayer(player.GetBySteamID(uuid), 84)
        end

        table.insert(playfight_client_userpictures, userBox)

        -- Display user's name
        surface.SetFont("PlayfightState")

        local text = ""

        if player.GetBySteamID(uuid) ~= false then
            text = player.GetBySteamID(uuid):Nick()
        else
            text = "?"
        end

        local pw, ph = surface.GetTextSize(text)
        local userName = vgui.Create("DLabel", tabStrip)
        
        
        userName:SetText(text)
        userName:SetPos(35 * ScrS(), 2*ScrS() + (3*ScrS()))
        userName:SetFont("PlayfightState")
        userName:SetSize(pw, ph)

        -- Player wins
        surface.SetFont("ScoreboardStatsPlayfight")
        local playerWins = vgui.Create("DLabel", tabStrip)
        playerWins:SetText("")
        playerWins:SetPos(103 * ScrS(), 6 * ScrS())
        playerWins:SetFont("ScoreboardStatsPlayfight")

        playerWins.Paint = function(s, w, h)
            local winText = ""

            if playfight_clientplayerwins[k] == 1 then
                winText = playfight_clientplayerwins[k] .. " Win"
            else
                winText = playfight_clientplayerwins[k] .. " Wins"
            end

            draw.DrawText(winText, "ScoreboardStatsPlayfight", 0, 0, Color( 220, 220, 220, 255 ), TEXT_ALIGN_LEFT)
        end

        -- Player Health
        if player.GetBySteamID(uuid) ~= false then

            surface.SetFont("ScoreboardStatsPlayfight")

            local playerHealth = vgui.Create("DLabel", tabStrip)
            playerHealth:SetText("")
            playerHealth:SetPos(163 * ScrS(), 6 * ScrS())
            playerHealth:SetFont("ScoreboardStatsPlayfight")

            playerHealth.Paint = function(s, w, h)
                local healthText = math.max(player.GetBySteamID(uuid):Health(), 0).."%"

                draw.DrawText(healthText, "ScoreboardStatsPlayfight", 0, 0, Color( 220, 220, 220, 255 ), TEXT_ALIGN_LEFT)
            end

        end

        -- Mute Button
        local Mute = vgui.Create("DImageButton", tabStrip)
		Mute:SetSize( 32 * ScrS(), 32 * ScrS() )
		Mute:Dock( RIGHT )
        Mute.ply = player.GetBySteamID(uuid)

        if Mute.ply ~= false then
            if Mute.ply:IsMuted() then
                Mute:SetImage("icon32/muted.png")
            else
                Mute:SetImage("icon32/unmuted.png")
            end
        else
            Mute:SetImage("icon32/unmuted.png")
        end

        Mute:SetStretchToFit(false)
        Mute.muted = false
        

        -- Toggle player muted state
        Mute.DoClick = function()
            Mute.muted = !Mute.muted

            if Mute.muted then
                Mute:SetImage("icon32/muted.png")
            else
                Mute:SetImage("icon32/unmuted.png")
            end

            if Mute.ply ~= false then
                Mute.ply:SetMuted(Mute.muted)
            end
        end
    end
    
    -- Remove everything when tab has stopped being held
	function playfight_scoreboard:hide()
        playfight_scoreboard_visible = false
        
        playfight_client_song_checkbox:Hide()
        playfight_client_song_slider:Hide()

        mainPanel:Remove()
        playfight_client_panels = {}
        playfight_client_userpictures = {}

        gui.EnableScreenClicker(false)
	end
end

hook.Add("KeyPress", "playfight_scoreboard_keypress", function(ply, key)
    if (key == IN_ATTACK2 and input.IsKeyDown(KEY_TAB)) then
        gui.EnableScreenClicker(true)
        playfight_client_song_checkbox:MoveToFront()
        playfight_client_song_slider:MoveToFront()
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

net.Receive("playfight_client_playerdisconnect", function( len )
    local steamID = net.ReadString()

    if player.GetBySteamID(steamID) ~= nil then
        for i = 1, #playfight_clientplayers do
            if playfight_clientplayers[i] == steamID then
                table.remove(playfight_clientplayers, i)
            end
        end
    end
end)
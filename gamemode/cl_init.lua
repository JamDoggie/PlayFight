include( "shared.lua" )
include( "cl_scoreboard.lua" )

--convienience function for screen scaling
local function ScrS()
    return math.Round(ScrH() / 768, 4) 
end

playfight_client_round = 0.0

playfight_client_maplist = playfight_client_maplist or {}

playfight_client_votelist = playfight_client_votelist or {}

playfight_client_maptexts = playfight_client_maptexts or {}

playfight_client_menu_list = playfight_client_menu_list or {}

playfight_client_gameend = false


playfight_client_current_song_channel = nil

playfight_client_song_volume = 0.5

playfight_client_should_play_song = false

-- Song check box and volume slider GUI elements
playfight_client_song_checkbox = vgui.Create("DCheckBoxLabel")

playfight_client_song_checkbox:SetPos( ScrW() / 2, ScrH() - (20 * ScrS()))
playfight_client_song_checkbox:SetText("Enable Music")
playfight_client_song_checkbox:SetValue(playfight_client_should_play_song)
playfight_client_song_checkbox:SizeToContents()

function playfight_client_song_checkbox:OnChange( val )
    print("checked")

	playfight_client_should_play_song = val
    if playfight_client_current_song_channel ~= nil then
        if !val then
            playfight_client_current_song_channel:SetVolume(0)
        else
            playfight_client_current_song_channel:SetVolume(playfight_client_song_volume)
        end
    end
end

playfight_client_song_slider = vgui.Create("DNumSlider")
playfight_client_song_slider:SetPos( (ScrW() / 2) - (300 * ScrS()), ScrH() - (20 * ScrS()))
playfight_client_song_slider:SetSize(300 * ScrS(), 20 * ScrS())
playfight_client_song_slider:SetText("Music Volume")
playfight_client_song_slider:SetMin(0)
playfight_client_song_slider:SetMax(1)
playfight_client_song_slider:SetDecimals( 2 )

function playfight_client_song_slider:OnValueChanged( val )
    playfight_client_song_volume = val

    

    if playfight_client_current_song_channel ~= nil then
        if playfight_client_should_play_song then
            playfight_client_current_song_channel:SetVolume(playfight_client_song_volume)
            print(playfight_client_current_song_channel:GetVolume())
        else
            playfight_client_current_song_channel:SetVolume(0)
        end
    end
end



playfight_damage_counter_visibility = 0;

playfight_damage_counter_pos = Vector(0, 0, 0)

playfight_damage_counter_text = ""

playfight_current_message = ""


local currentGraceCount = 0

LocalPlayer().playfight_client_super_charge = false

LocalPlayer().playfight_client_super_flash = 0
LocalPlayer().playfight_client_super_flash_dir = 0

local currentSuperLerp = 0
local currentHealthLerp = 0


surface.CreateFont( "PlayfightState", {
	font = "Tahoma", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 15 * ScrS(),
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )

surface.CreateFont( "DermaLargeScaled", {
	font = "Roboto", 
	extended = false,
	size = 32 * ScrS(),
	weight = 1000,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )

surface.CreateFont( "ScoreboardStatsPlayfight", {
	font = "Roboto", 
	extended = false,
	size = 18 * ScrS(),
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false
} )

playfight_client_stunposx = 0
playfight_client_stunstring = ""

//local html = vgui.Create( "DHTML" )
//html:Dock( FILL )
//html:SetAllowLua(true)
//html:OpenURL("asset://garrysmod/html/test.html")

//html:AddFunction("playfight", "playgame", function()
//    net.Start("playfight_player_start_play")
//    net.SendToServer()
//
//    playfight_client_song_checkbox:Hide()
//    playfight_client_song_slider:Hide()
//
//    gui.EnableScreenClicker(false)
//    frame:Remove()
//    html:Remove()
//end)

--main menu
local frame = vgui.Create("DFrame")
frame:SetSize((ScrW() / 2), (ScrH() / 7))
frame:SetPos((ScrW() / 8), (ScrH() / 15))
frame:SetVisible( true )

frame:ShowCloseButton(false)
frame:SetDraggable(false)
frame:SetTitle("")

util.PrecacheModel("models/weapons/ricochet/c_ricochet_disc.mdl")
util.PrecacheModel("models/weapons/ricochet/w_ricochet_disc.mdl")

util.PrecacheModel("models/weapons/c_crowbar.mdl")
util.PrecacheModel("models/weapons/w_crowbar.mdl")

util.PrecacheModel("models/weapons/c_crossbow.mdl")
util.PrecacheModel("models/weapons/w_crossbow.mdl")

frame.Paint = function(s, w, h)

    gui.EnableScreenClicker(true)

    if ( FrameTime() ~= 0 ) then
       
        Derma_DrawBackgroundBlur(frame, 0)
        draw.RoundedBox(0, 0, 0, w, h, Color(66, 66, 66, 170))

    end

end


--drag panel
local dragframe = vgui.Create("DFrame")
dragframe:SetSize((ScrW() / 2), ScrH() / 1.4)
dragframe:SetPos((ScrW() / 8), (ScrH() / 4.5))
dragframe:SetVisible( true )

dragframe:ShowCloseButton(false)
dragframe:SetDraggable(true)
dragframe:SetTitle("")

dragframe.Paint = function(s, w, h)

    --leave blank. we don't want to draw this panel

end

DragW,DragH = dragframe:GetSize()

--main menu
local playerframe = vgui.Create("DFrame", dragframe)
playerframe:SetSize(DragW/2, DragH)

playerframe:SetVisible( true )

playerframe:ShowCloseButton(false)
playerframe:SetDraggable(false)
playerframe:SetTitle("")

local dragx = 0
local dragy = 0

playerframe:SetPos(0, 0)

local pfpx,pfpy = playerframe:GetPos()
local pfx,pfy = playerframe:GetSize()

playerframe.Paint = function(s, w, h)

    gui.EnableScreenClicker(true)

    if ( FrameTime() ~= 0 ) then

        draw.RoundedBox(0, 0, 0, w, h, Color(66, 66, 66, 170))

    end

end

local playerchoose = vgui.Create("DPanelSelect", dragframe)

playerchoose:SetSize(DragW/2, DragH)
playerchoose:SetPos(DragW/2, 0)
playerchoose:SetVisible( true )

playerchoose.Paint = function(s, w, h)

    gui.EnableScreenClicker(true)

    if ( FrameTime() ~= 0 ) then

        draw.RoundedBox(0, 0, 0, w, h, Color(66, 66, 66, 170))

    end

end



local mdl = playerframe:Add("DModelPanel")
mdl:SetPos(0,0)

px,py = playerframe:GetSize()

mdl:Dock(FILL)

mdl:SetModel( "models/player/kleiner.mdl" )

mdl:SetFOV( 36 )
mdl:SetCamPos( Vector( 0, 0, 0 ) )
mdl:SetDirectionalLight( BOX_RIGHT, Color( 255, 160, 80, 255 ) )
mdl:SetDirectionalLight( BOX_LEFT, Color( 80, 160, 255, 255 ) )
mdl:SetAmbientLight( Vector( -64, -64, -64 ) )
mdl.Angles = Angle( 0, 0, 0 )
mdl:SetLookAt( Vector( -100, 0, -22 ) )
mdl.Entity:SetPos( Vector( -100, 0, -61 ) )

--for setting the playermodel
local function SetPlayerModel(model)

    net.Start("playfight_change_playermodel")
    net.WriteString(model)
    net.SendToServer()

end

--add the select boxes for other player models
for name, model in SortedPairs( player_manager.AllValidModels() ) do

    local icon = vgui.Create( "SpawnIcon" )
    icon:SetModel( model )
    icon:SetSize( 64, 64 )
    icon:SetTooltip( name )
    icon.playermodel = name

    playerchoose:AddPanel( icon, { cl_playermodel = name } )

end

dragframe:MoveToFront()

function mdl:LayoutEntity( ent )
    
end

function playerchoose:OnActivePanelChanged( old, new )

    timer.Simple( 0.1, function() 
        local model = LocalPlayer():GetInfo( "cl_playermodel" )
        local modelname = player_manager.TranslatePlayerModel( model )
        util.PrecacheModel(modelname)
        mdl.Entity:SetModel(modelname)
        mdl.Entity:SetPos( Vector( -100, 0, -61 ) )

        SetPlayerModel(modelname)

        local iSeq = mdl.Entity:LookupSequence( "idle_all_01" )
        if ( iSeq > 0 ) then mdl.Entity:ResetSequence(iSeq) end
    end)

end

local xtwo, ytwo = frame:GetSize()

dragframe:MoveToFront()

--play button
local playButton = vgui.Create("DButton", frame)

playButton:SetText("Play")

xt, yt = playButton:GetSize()

playButton:SetPos(xtwo/2 - (xt / 2), ytwo/2 - (ytwo/8))

playButton.DoClick = function()

    net.Start("playfight_player_start_play")
    net.SendToServer()

    playfight_client_song_checkbox:Hide()
    playfight_client_song_slider:Hide()

    playButton:Remove()
    gui.EnableScreenClicker(false)
    frame:Remove()
    playerframe:SetVisible(false)
    playerchoose:SetVisible(false)

end

--Play sound when people get hurt
net.Receive("playfight_hurtsound", function() 
    surface.PlaySound("physics/cardboard/cardboard_box_break2.wav")
end)

function dragframe:Think()
    dragframe:MoveToFront()
end

dragframe:MoveToFront()

hook.Add( "HUDShouldDraw", "__DraRaW_huUD_playfIght1___OONE__", function( name )

    local hide = {
	    ["CHudHealth"] = true,
        ["CHudAmmo"] = true,
        ["CHudBattery"] = true
    }

    if ( hide[name]) then return false end

end)
local winStr = ""
local super = 0

local winx = ScrW()
local panelx = ScrW()

local blur = Material("pp/blurscreen")
local function DrawBlurRect(x, y, w, h)
	local X, Y = 0,0

	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(blur)

	for i = 1, 5 do
		blur:SetFloat("$blur", (i / 3) * 2)
		blur:Recompute()

		render.UpdateScreenEffectTexture()

		render.SetScissorRect(x, y, x+w, y+h, true)
        surface.DrawTexturedRect(X, Y, ScrW(), ScrH())
		render.SetScissorRect(0, 0, 0, 0, false)
	end
   

end

net.Receive("playfight_getround", function()
    playfight_client_round = net.ReadFloat()
end)

net.Receive("playfight_client_screenmessage", function()
    local message = net.ReadString()

    playfight_current_message = message
end)

hook.Add("HUDPaint", "_s_d_huD_pAINt___playfi1ghtone___lp___", function()

    local ply = LocalPlayer()

    -- Current Message
    surface.SetFont("DermaLargeScaled")

    local messageW, messageH = surface.GetTextSize(playfight_current_message)

    draw.SimpleTextOutlined(playfight_current_message, "DermaLargeScaled", ScrW() / 2 - (messageW / 2), ScrH() / 2 - (messageH / 2), Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 4, Color( 0, 0, 0, 255 ))

    -- Status Box
    local timeWidth = math.Round(80 * ScrS())
    local timeHeight = math.Round(29 * ScrS())
    draw.RoundedBox(0, ScrW()/2 - timeWidth/2, 0, timeWidth, timeHeight, Color(0, 162, 232, 170))

    local capWidth = math.Round(80 * ScrS())
    local capHeight = math.Round(20 * ScrS())

    draw.RoundedBox(0, ScrW()/2 - timeWidth/2, timeHeight, capWidth, capHeight, Color(66, 66, 66, 170))

    local statusText = ""

    if !(playfight_client_gameend) then
        if GetGlobalBool("__ident1fier____Warmup_playfight__") then
            statusText = "Warmup"
        else
            statusText = "Round " .. playfight_client_round + 1
        end
    else
        statusText = "End"
    end

    surface.SetFont("PlayfightState")
    local textWidth, textHeight = surface.GetTextSize(statusText)

    draw.DrawText(statusText, "PlayfightState", ScrW()/2 - textWidth/2, capHeight/2 - capHeight/2 + timeHeight + 2, Color(255,255,255))

    surface.SetFont("DermaLargeScaled")

    local timeLeft = string.ToMinutesSeconds(GetGlobalInt("__ident1fier____Warmup_time_playfight__", 30))

    local timerWidth, timerHeight = surface.GetTextSize(timeLeft)

    draw.DrawText(timeLeft, "DermaLargeScaled", ScrW()/2 - timerWidth/2, 0, Color(255,255,255))


    -- Grace period
    if currentGraceCount > 0 then
        local graceText = "Grace period ends in "..currentGraceCount

        surface.SetFont("PlayfightState")
        local graceWidth, graceHeight = surface.GetTextSize(graceText)

        draw.SimpleTextOutlined(graceText, "PlayfightState", (ScrW() / 2) - (graceWidth / 2), ScrH() / 15, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1 * ScrS(), Color( 0, 0, 0, 255 ))
    end

    surface.SetFont("DermaLargeScaled")

    --set padding
    local padding = math.Round(10 * ScrS())

    --healthbar
    local dispWidth = math.Round(80 * ScrS())
    local dispHeight = math.Round(42 * ScrS())

    draw.RoundedBox(0, padding, ScrH() - dispHeight - padding, dispWidth, dispHeight, Color(66, 66, 66, 215))


    local healthWidth = math.Round(80 * ScrS())
    local healthHeight = math.Round(19 * ScrS())

    draw.RoundedBox(0, padding, ScrH() - padding - healthHeight - dispHeight, healthWidth, healthHeight, Color(86, 86, 86, 215))

    local plyHealth = LocalPlayer():Health()

    if plyHealth < 0 then
        plyHealth = 0
    end

    local healWidth, healHeight = surface.GetTextSize(plyHealth)
    local textPadding = 3

    draw.DrawText(plyHealth, "DermaLargeScaled", padding + (dispWidth/2 - healWidth/2), ScrH() - padding - (dispHeight/2 + healHeight/2), Color(255,255,255))


    surface.SetFont("PlayfightState")

    local labelW, labelH = surface.GetTextSize("Health/Super")

    draw.DrawText("Health/Super", "PlayfightState", padding + (healthWidth/2 - labelW/2), ScrH() - padding - dispHeight - (healthHeight/2 + labelH/2), Color(255,255,255))

    --health bar
    local barWidth = math.Round(7 * ScrS())
    local barHeight = (dispHeight + healthHeight)

    currentHealthLerp = Lerp(0.1 * (FrameTime() * 200), currentHealthLerp, ply:Health())
    local lerpHealth = currentHealthLerp

    draw.RoundedBox(0, padding + dispWidth, ScrH() - padding - barHeight, barWidth, barHeight, Color(46, 46, 46, 215))

    draw.RoundedBox(0, padding + dispWidth, ScrH() - padding - barHeight + (barHeight - barHeight * (lerpHealth/ply:GetMaxHealth())), barWidth, barHeight * (lerpHealth/ply:GetMaxHealth()), Color(30, 200, 100))


    -- UPDATE SUPER COLOR

    for k,v in next, player.GetAll() do
        if v.playfight_client_super_charge then
            if v.playfight_client_super_flash_dir == 0 then
                v.playfight_client_super_flash = v.playfight_client_super_flash + 5 * (FrameTime() * 200)

                if v.playfight_client_super_flash > 255 then
                    v.playfight_client_super_flash_dir = 1
                end
            else
                v.playfight_client_super_flash = v.playfight_client_super_flash - 5 * (FrameTime() * 200)

                if v.playfight_client_super_flash < 50 then
                    v.playfight_client_super_flash_dir = 0
                end
            end
        else
            v.playfight_client_super_flash = 255
        end
    end
    -- DRAW SUPER BAR

    currentSuperLerp = Lerp(0.05 * (FrameTime() * 200), currentSuperLerp, GetGlobalInt("__playGgfiHti_SUPErCLient_"..LocalPlayer():Nick()))
    super = currentSuperLerp

    draw.RoundedBox(0, padding + dispWidth + barWidth, ScrH() - padding - barHeight, barWidth, barHeight, Color(46, 46, 46, 215))
   
    draw.RoundedBox(0, padding + dispWidth + barWidth, ScrH() - padding - barHeight + (barHeight - barHeight * (super/100)), barWidth, barHeight * (super/100), Color(157, 80, 80, LocalPlayer().playfight_client_super_flash))


    surface.SetFont("DermaLargeScaled")
    local tw, th = surface.GetTextSize(winStr)

    if winStr ~= "" then
        winx = Lerp(0.1 * ScrS() * (FrameTime() * 200), winx, ScrW()/2 - tw/2)
        panelx = Lerp(0.1 * ScrS() * (FrameTime() * 200), panelx, 0)
    else
        winx = ScrW()
        panelx = ScrW()
    end
    
    local panelheightyy = ScrH()/5

    if !playfight_scoreboard_visible then
        draw.RoundedBox(0, panelx, ScrH()/2-(panelheightyy/2), ScrW(), panelheightyy, Color(70,70,70,230))

        draw.DrawText(winStr, "DermaLargeScaled", winx , ScrH()/2 - th/2, Color(200,200,200))
    end
    dragframe:MoveToFront()

    -- Stun timer
    if playfight_client_stunstring ~= "" then
        if playfight_client_stunposx < ScrW()/2 then
            playfight_client_stunposx = Lerp(0.1 * ScrS(), playfight_client_stunposx, ScrW()/2)
        end
    end

    if playfight_client_stunstring ~= "" and playfight_client_stunstring ~= "0" then
        local stunw,stunh = surface.GetTextSize("! YOU ARE STUNNED !")
        draw.DrawText("! YOU ARE STUNNED !", "DermaLargeScaled", ScrW()/2 - stunw/2 , ScrH()/2 - (55 * ScrS()), Color(200,200,200))

        draw.DrawText(playfight_client_stunstring, "DermaLargeScaled", playfight_client_stunposx , ScrH()/2 - th/2, Color(200,200,200))
    end
end)

function GM:PlayerBindPress( ply, bind, pressed )
    if !playerframe:IsVisible() then
        if bind == "+menu_context" then
            playerframe:SetVisible(true)
            playerchoose:SetVisible(true)
            gui.EnableScreenClicker(true)
        end
    else
        if bind == "+menu_context" then
            playerframe:SetVisible(false)
            playerchoose:SetVisible(false)
            gui.EnableScreenClicker(false)
        end
    end
end

-- Map Selection
net.Receive("playfight_mapinfo", function()
    local mapCount = net.ReadFloat()
    for k = 1, mapCount do
        playfight_client_maplist[k] = net.ReadString()
    end
end)

net.Receive("playfight_client_voteinfo", function()
    local index = net.ReadFloat()
    local votes = net.ReadFloat()
    playfight_client_votelist[index] = votes
    playfight_client_maptexts[index]:SetText("Votes: "..votes)
end)

local posX, posY, posZ, minX, minY, minZ, maxX, maxY, maxZ

local isValid

net.Receive("playfight_client_showlastpos", function()
    posX = net.ReadFloat()
    posY = net.ReadFloat()
    posZ = net.ReadFloat()

    minX = net.ReadFloat()
    minY = net.ReadFloat()
    minZ = net.ReadFloat()

    maxX = net.ReadFloat()
    maxY = net.ReadFloat()
    maxZ = net.ReadFloat()

    isValid = net.ReadBool()

    print(Vector(posX, posY, posZ))
    print(Vector(minX, minY, minZ))
    print(Vector(maxX, MaxY, maxZ))
end)

-- Retrives information about player ragdolling. This is so we can display the name tag even if the player is ragdolled.
net.Receive("playfight_client_ragdoll", function()

    local nick = net.ReadString()
    local israg = net.ReadBool()

    local ragX = net.ReadFloat()
    local ragY = net.ReadFloat()
    local ragZ = net.ReadFloat()

    for k,v in next, player.GetAll() do
        if v:Nick() == nick then
            v.israg = israg
            v.ragX = ragX
            v.ragY = ragY
            v.ragZ = ragZ
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "playfight_debug_hull_draw_id", function()
    -- debug box
    local clr = Color(255, 255, 255)

    if (!isValid) then
        clr = Color(255, 20, 20)
    end

    render.DrawWireframeBox( Vector(posX, posY, posZ), Angle( 0, 0, 0 ), Vector(minX, minY, minZ), Vector(maxX, maxY, maxZ), clr, true )

    local ang = LocalPlayer():EyeAngles()

    ang:RotateAroundAxis( ang:Forward(), 90 )
    ang:RotateAroundAxis( ang:Right(), 90 )

    local plyr = LocalPlayer()

    local lerpNum = 0.2 

    cam.Start3D2D( Vector(Lerp(lerpNum, playfight_damage_counter_pos.x, plyr:GetPos().x), Lerp(lerpNum, playfight_damage_counter_pos.y, plyr:GetPos().y), Lerp(lerpNum, playfight_damage_counter_pos.z, plyr:GetPos().z + 50)), Angle( 0, ang.y, 90 ), 0.25)
        -- Draw damage percents on hit
        draw.SimpleTextOutlined(playfight_damage_counter_text, "DermaLargeScaled", 2, 2, Color( 0, 0, 0, playfight_damage_counter_visibility ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color( 255, 255, 255, playfight_damage_counter_visibility ))
        -- slowly fade out
        if playfight_damage_counter_visibility > 0 then
            if (playfight_damage_counter_visibility > 255) then
                playfight_damage_counter_visibility = playfight_damage_counter_visibility - 1
            else
                playfight_damage_counter_visibility = Lerp(0.03 * (FrameTime() * 200), playfight_damage_counter_visibility, 0)
            end

            if playfight_damage_counter_visibility < 0 then
                playfight_damage_counter_visibility = 0
            end
        end
    cam.End3D2D()

    -- NAME TAGS
    for k, ply in next, player.GetAll() do
        if ply ~= LocalPlayer() and ply:Alive() and ((ply:GetObserverMode() ~= OBS_MODE_ROAMING and ply:GetObserverMode() ~= OBS_MODE_CHASE ) or ply.israg == true) and table.HasValue(playfight_client_menu_list, ply:SteamID()) then
            local drawHeight = 85

            if ( ply:LookupBone("ValveBiped.Bip01_Head1") ~= nil) then
                drawHeight = (ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_Head1")).z - ply:GetPos().z) + 15
            end

            if ply.israg then
                drawHeight = 50
            end

            local offset = Vector( 0, 0, drawHeight )
            local ang = LocalPlayer():EyeAngles()
            local pos = ply:GetPos() + offset + ang:Up()
        
            if ply.israg then
                pos = Vector(ply.ragX, ply.ragY, ply.ragZ) + offset + ang:Up()
            end

            ang:RotateAroundAxis( ang:Forward(), 90 )
            ang:RotateAroundAxis( ang:Right(), 90 )
        
            cam.Start3D2D( pos, Angle( 0, ang.y, 90 ), 0.25 )
                draw.SimpleTextOutlined(ply:GetName().." ("..ply:Health().."%)", "DermaLargeScaled", 2, 2, Color( 255, 255, 255, ply.playfight_client_super_flash ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color( 0, 0, 0, ply.playfight_client_super_flash ))
            cam.End3D2D()
        end
    end
end)

net.Receive("playfight_client_playsound", function()
    local soundToPlay = net.ReadString()

    surface.PlaySound(soundToPlay)
end)

net.Receive("playfight_round_winner", function()
        
    local winNicknameplayfight = net.ReadString()

    if !(winNicknameplayfight == "") then
        winStr = winNicknameplayfight.." is the winner!"
    else
        winStr = ""
    end

    if winNicknameplayfight == "pf_reserved_draw" then
        winStr = "Draw!"
    end

    if winNicknameplayfight == "pf_reserved_suddendeath" then
        winStr = "SUDDEN DEATH"
    end

    if string.find(winNicknameplayfight, "Game end,") then
        playfight_client_gameend = true

        local hw, hh = 500*ScrS(), 20*ScrS()
        local hx, hy = ScrW()/2-(hw/2), 50*ScrS()
        local mapHeader = vgui.Create("DPanel")
        mapHeader:SetPos(hx, hy)
        mapHeader:SetSize(hw, hh)
        mapHeader.Paint = function(s, w, h)

            gui.EnableScreenClicker(true)

            if ( FrameTime() ~= 0 ) then

                draw.RoundedBox(0, 0, 0, w, h, Color(0, 162, 232, 255))

            end

        end


        local pw, ph = 500*ScrS(), 220*ScrS()
        local px, py = ScrW()/2-(pw/2), 70*ScrS()
        local mapSelectPanel = vgui.Create("DScrollPanel")
        mapSelectPanel:SetPos(px, py)
        mapSelectPanel:SetSize(pw, ph)
        mapSelectPanel.Paint = function(s, w, h)

            gui.EnableScreenClicker(true)

            if ( FrameTime() ~= 0 ) then

                draw.RoundedBox(0, 0, 0, w, h, Color(66, 66, 66, 210))

            end

        end


        local mapIconPanel = vgui.Create("DIconLayout", mapSelectPanel)
        mapIconPanel:SetPos(3 * ScrS(), 3 * ScrS())
        mapIconPanel:SetSize(pw - (3*ScrS()), ph - (3*ScrS()))

        mapIconPanel:SetSpaceY( 5 ) -- Sets the space in between the panels on the Y Axis by 5
        mapIconPanel:SetSpaceX( 5 ) -- Sets the space in between the panels on the X Axis by 5

        for i = 1, #playfight_client_maplist do
            local ListItem = mapIconPanel:Add( "DButton" ) -- Add DPanel to the DIconLayout
	        ListItem:SetSize(80 * ScrS(), 40 * ScrS()) -- Set the size of it
            ListItem:SetText("")

            ListItem.DoClick = function()
                net.Start("playfight_server_voteinfo")
                net.WriteFloat(i)
                net.SendToServer()
            end

            ListItem.Paint = function(s, w, h)

                if ( FrameTime() ~= 0 ) then

                    draw.RoundedBox(0, 0, 0, w, h, Color(220, 220, 220, 210))

                end

            end

            local label = ListItem:Add("DLabel")
            label:SetText(playfight_client_maplist[i])
            label:SetFont("PlayfightState")
            local oldx,oldy = label:GetSize()
            label:SetPos(3 * ScrS(),1 * ScrS())
            label:SetSize(80 * ScrS(), oldy)
            label:SetColor(Color(0,0,0))

            local voteLabel = ListItem:Add("DLabel")
            voteLabel:SetText("Votes: 0")
            voteLabel:SetFont("PlayfightState")
            local oldvx,oldvy = voteLabel:GetSize()
            voteLabel:SetPos(3 * ScrS(),18 * ScrS())
            voteLabel:SetSize(80 * ScrS(), oldvy)
            voteLabel:SetColor(Color(33,33,33))

            playfight_client_maptexts[i] = voteLabel

        end

        local mapSelectLabel = vgui.Create("DLabel", mapHeader)

        mapSelectLabel:SetText("Map Selection")

        mapSelectLabel:SetFont("PlayfightState")

        surface.SetFont("PlayfightState")
        local lw,lh = surface.GetTextSize("Map Selection")
        local lx,ly = hw/2-(lw/2), hh/2-(lh/2)

        mapSelectLabel:SetPos(lx, ly)
        mapSelectLabel:SetSize(lw, lh)

    end

end)

timer.Create("__pfplayfight_notify_wa1t__", 20, 0, function()
    if ( GetGlobalBool("__ident1fier____Warmup_playfight__", false) and GetGlobalBool("__ident1fier____Waiting_playfight__", false)) then
        chat.AddText( Color(25,25,200), "There needs to be atleast 2 players in warmup for the round to start!")
    end
end)

net.Receive("playfight_stunupdate", function()
    local stuntimer = net.ReadFloat()
    playfight_client_stunposx = 0
    playfight_client_stunstring = tostring(stuntimer)
end)

net.Receive("playfight_client_showdamage", function()
    local damage = net.ReadFloat()

    local posx = net.ReadFloat()
    local posy = net.ReadFloat()
    local posz = net.ReadFloat() + 50

    playfight_damage_counter_pos = Vector(posx, posy, posz)

    playfight_damage_counter_text = damage

    playfight_damage_counter_visibility = 1000
end)

net.Receive("playfight_client_supercharging", function( len )
    local isCharging = net.ReadBool()
    local playerNickName = net.ReadString()

    for k, ply in next, player.GetAll() do
        if (ply:Nick() == playerNickName) then
            ply.playfight_client_super_charge = isCharging
        end
    end

    if playerNickName == LocalPlayer():Nick() then
        playfight_client_super_charge = isCharging
    end
end)

net.Receive("playfight_client_graceperiod_count", function( len )
    local count = net.ReadFloat()
    
    print("grace count down")

    currentGraceCount = count

    timer.Create("playfight_graceperiod_count_client", 1, count, function()
        currentGraceCount = currentGraceCount - 1
    end)
end)

net.Receive("playfight_client_player_menu", function( len )
    local steamID = net.ReadString()
    local isInMenu = net.ReadBool()

    if player.GetBySteamID(steamID) ~= nil then
        if !isInMenu then
            table.insert(playfight_client_menu_list, steamID)
        elseif table.HasValue(playfight_client_menu_list, steamID) then
            table.RemoveByValue(playfight_client_menu_list, steamID)
        end
    end
end)

net.Receive("playfight_client_play_music", function(len)
    sound.PlayFile("sound/grand_march.wav", "noplay", function( station, errCode, errStr )
        if IsValid( station ) then
            if playfight_client_current_song_channel == nil then
                station:Play()
                
                playfight_client_current_song_channel = station

                if playfight_client_should_play_song then
                    station:SetVolume(playfight_client_song_volume)
                else
                    station:SetVolume(0)
                end
            end
        else
            print( "Error playing song!", errCode, errStr )
        end
    end)
end)



-- Music
hook.Add("Initialize", "playfight_client_player_connect_music", function( ply )
    
end)


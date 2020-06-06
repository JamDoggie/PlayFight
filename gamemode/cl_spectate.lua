playfight_client_locally_spectated_player = playfight_client_locally_spectated_player or nil

playfight_client_spectatedHealth = playfight_client_spectatedHealth or 0
playfight_client_spectatedSuper = playfight_client_spectatedSuper or 0

if LocalPlayer().spectatedPlayer == nil then
    LocalPlayer().spectatedPlayer = ""
end

--convienience function for screen scaling
local function ScrS()
    return math.Round(ScrH() / 768, 4) 
end

net.Receive("playfight_client_spectate_info", function( len )
    local isSpectating = net.ReadBool()

    LocalPlayer().isSpectating = isSpectating

    if !isSpectating then
        LocalPlayer().spectatedPlayer = ""
    end

end)

net.Receive("playfight_client_spectate_player_name", function( len )
    local spectatedPlayer = net.ReadString()

    LocalPlayer().spectatedPlayer = spectatedPlayer
end)

net.Receive("playfight_client_spectate_player_healthsuper", function()
    playfight_client_spectatedHealth = net.ReadFloat()
    playfight_client_spectatedSuper = net.ReadFloat()
end)

hook.Add("HUDPaint", "playfight_paint_spectate_text", function()
    if LocalPlayer().isSpectating == true then
        
        local spectateText = "You are spectating"

        if LocalPlayer().spectatedPlayer ~= nil and LocalPlayer().spectatedPlayer ~= "" then
            spectateText = "Spectating "..LocalPlayer().spectatedPlayer
        end

        local spectateInfoText = "Press space to toggle between spectating world and players, left click to cycle between players."

        surface.SetFont("DermaLargeScaled")
        local specTextWidth, specTextHeight = surface.GetTextSize(spectateText)

        draw.SimpleTextOutlined(spectateText, "DermaLargeScaled", (ScrW() / 2) - (specTextWidth / 2), 520 * ScrS(), Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2 * ScrS(), Color( 0, 0, 0 ))

        surface.SetFont("PlayfightState")
        local specInfoTextWidth, specInfoTextHeight = surface.GetTextSize(spectateInfoText)

        draw.SimpleTextOutlined(spectateInfoText, "PlayfightState", (ScrW() / 2) - (specInfoTextWidth / 2), 560 * ScrS(), Color( 255, 255, 255 ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 1 * ScrS(), Color( 0, 0, 0 ))
    end
end)
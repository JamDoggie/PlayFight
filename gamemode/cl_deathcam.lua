-- This file mainly just controls the html overlay for the deathcam.

playfight_client_local_deathcam = false;

playfight_client_deathcam_html = playfight_client_deathcam_html or vgui.Create("DHTML")
playfight_client_deathcam_html:Dock(FILL)
playfight_client_deathcam_html:OpenURL("http://quintonswenski.com/Jamdoggie/deathcam/index.html");
playfight_client_deathcam_html:SetVisible(false)

net.Receive("playfight_client_deathcam_html", function( len )
    local showCam = net.ReadBool()

    playfight_client_local_deathcam = showCam;

    local playerName = net.ReadString()
    local playerID64 = net.ReadString()
    local playerID = net.ReadString()
    local playerHealth = net.ReadInt(18)
    local playerDamage = net.ReadInt(18)

    if showCam == true then
        playfight_client_deathcam_html:SetVisible(true)
        playfight_client_deathcam_html:QueueJavascript("showScreen(\""..playerName.."\", \""..playfight_get_cached_avatar(playerID, playerID64, function(requestedAvatar)
            print(requestedAvatar)
            playfight_client_deathcam_html:QueueJavascript("avatarButton.style.setProperty(\"background-image\", \"url('"..requestedAvatar.."')\");")
        end).."\", "..playerHealth..", "..playerDamage..");")
        print("istrue")
    else
        playfight_client_deathcam_html:SetVisible(false)
        playfight_client_deathcam_html:QueueJavascript("hideScreen();")
    end
end)
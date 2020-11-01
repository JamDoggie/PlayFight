hook.Add( "PreDrawHalos", "playfight_team_halos_hook", function()
	if playfight_client_isteams then
        for k, v in next, player.GetAll() do
            if v:Team() == LocalPlayer():Team() and LocalPlayer():Team() ~= TEAM_UNASSIGNED and v:Alive() and table.HasValue(playfight_client_menu_list, v:SteamID()) and !v:IsDormant() and !playfight_client_local_deathcam then
                if v.israg != true then
                    halo.Add({v}, team.GetColor(LocalPlayer():Team()))
                else
                    for i, e in next, ents.GetAll() do
                        if e.nick == v:Nick() and v != LocalPlayer() then
                            halo.Add({e}, team.GetColor(LocalPlayer():Team()))
                        end
                    end
                end
            end
        end
    end
end )

net.Receive("playfight_client_team_win_update", function( len, ply )
    local teamID = net.ReadInt(18)
    local wins = net.ReadInt(18)

    playfight_scoreboard_html:QueueJavascript("updateTeamWins("..tostring(teamID)..", "..tostring(wins)..");")
end)
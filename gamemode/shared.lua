GM.Name = "Play Fight"
GM.Author = "JamDoggie"
GM.Email = "jamdoggie3@gmail.com"
GM.Website = "twitter.com/jamdoggie"

function GM:Initialize()

end

-- Teams
hook.Add("CreateTeams", "playfight_gamemode_setup_teams_hook", function()
    team.SetUp(0, "Orange", Color(232, 174, 102))
    team.SetUp(1, "Blue", Color(0, 163, 232))
end)
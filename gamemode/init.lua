AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_scoreboard.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_spectate.lua" )
AddCSLuaFile( "cl_gamemodes.lua" )
AddCSLuaFile( "cl_deathcam.lua" )

include( "shared.lua" )
include( "network_server.lua" )
include( "balance.lua" )
include( "convars.lua" )
include( "mapmechanics.lua" )
include( "ricochet.lua" )
include( "gamemodes.lua" );

-- Main game state related variables. Should be pretty self Explanatory.
playfight_currentRound = 0

playfight_mapsinstalled = playfight_mapsinstalled or {}
playfight_mapvotes = playfight_mapvotes or {}
playfight_playersvoted = playfight_playersvoted or {}

playfight_players_spectating = playfight_players_spectating or {}

playfight_game_ended = playfight_game_ended or false


local ragdollCooldown = 0.3



-- CREDIT: https://github.com/Foohy/jazztronauts/blob/e5009a193320cf38ec0102acc6f2af2528bffd66/gamemodes/jazztronauts/gamemode/init.lua
local function SetIfDefault(convarstr, ...)
	local convar = GetConVar(convarstr)
	if not convar or convar:GetDefault() == convar:GetString() then
		print("Setting " .. convarstr)
		RunConsoleCommand(convarstr, ...)
	end
end

function GM:Initialize()
    -- Loading screen
    SetIfDefault("sv_loadingurl", "http://jd.quintonswenski.com/Jamdoggie/loadingscreen/index.html")
end

function GM:ShutDown()
    if GetConVar("sv_loadingurl"):GetString() == "http://jd.quintonswenski.com/Jamdoggie/loadingscreen/index.html" then
        RunConsoleCommand("sv_loadingurl", "")
    end -- This only mostly fixes the loading screen issue. If the player's game happens to crash or get force quit, the loading screen
        -- will still persist forever.
end


-- Set any variables related to player movement here
function GM:PlayerLoadout( ply )

    ply:SetWalkSpeed(400)
    ply:SetRunSpeed(400)

    ply:SetJumpPower(240)

end

-- Killing ragdolls when they enter kill triggers
local function SetupMapLua()
	local MapLua = ents.Create( "lua_run" )
	MapLua:SetName( "triggerhook" )
	MapLua:Spawn()

    -- Add an output to the entity so that it calls a hook in lua
	for _, v in ipairs( ents.FindByClass( "trigger_hurt" ) ) do
		v:Fire( "AddOutput", "OnStartTouch triggerhook:RunPassedCode:hook.Run( 'OnHurt' ):0:-1" )
        v:SetKeyValue("spawnflags", 64)
	end
end

hook.Add( "InitPostEntity", "playfight_post_entity_killtrigger_detection", SetupMapLua )
hook.Add( "PostCleanupMap", "playfight_post_entity_killtrigger_detection", SetupMapLua )
hook.Add( "OnHurt", "playfight_ragdoll_trigger_hurt_hook", function()
	local activator, caller = ACTIVATOR, CALLER
	print( activator, caller )

    if activator:GetClass() == "prop_ragdoll" then
        if activator.ownply ~= nil then
            -- This is a Play Fight ragdoll, murder the player
            activator.ownply:Kill()
            activator.ownply:GetRagdollEntity():Remove()
            activator.ownply.fell = 0
            activator.ownply.ragfall = nil
        end
    end
end )

-- Ease of use function that sets the player's super bar to a specified amount. Please use this instead of manually doing it, this
-- ensures that the super does not go over 100 and it also sends the data to the client so the super bar can update as needed.
function SetSuper( ply, num ) 

    local number = num

    if num > 100 then number = 100 end

    ply.superenergy = number
    
    SetGlobalInt("__playGgfiHti_SUPErCLient_"..ply:Nick(), number)
end

function playfight_increase_kills(ply)
    if GetGlobalBool("__ident1fier____Warmup_playfight__") == false then
        
        if ply.kills == nil then
            ply.kills = 1
        else
            ply.kills = ply.kills + 1
        end

        -- Send to clients
        net.Start("playfight_send_kills")

        
        if ply ~= nil and ply:SteamID() ~= nil then
            net.WriteString(ply:SteamID())
            net.WriteInt(ply.kills, 32)
        else
            net.WriteString("")
            net.WriteInt(0, 32)
        end
        

        net.Broadcast()
        
    end
end

function playfight_send_killfeed(attacker, attackerTeam, inflictor, victim, victimTeam)
    net.Start("playfight_client_killfeed")

    net.WriteString(attacker)
    net.WriteFloat(attackerTeam)
    net.WriteString(inflictor)
    net.WriteString(victim)
    net.WriteFloat(victimTeam)

    net.Broadcast()
end

function PlayfightSendTabInfo( ply )
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

function playfight_player_can_hurt(attacker, victim)
    local canHurt = true;

    if attacker == nil or victim == nil then
        return false;
    end

    if attacker:IsPlayer() == false or victim:IsPlayer() == false then
        return true;
    end

    if playfight_is_grace_period then
        canHurt = false;
    end

    if !victim:Alive() then
        canHurt = false;
    end

    if victim:Team() ~= TEAM_UNASSIGNED and (victim:Team() == attacker:Team()) and GetConVar("pf_friendly_fire"):GetBool() == false then
        canHurt = false;
    end

    if GetGlobalBool("__ident1fier____Warmup_playfight__") == true and GetConVar("pf_warmup_invulnerability"):GetBool() == true then
        canHurt = false;
    end

    return canHurt;
end

--= RAGDOLLING AND STUFF =--
hook.Add("KeyPress", "xddDDDdplRessKe___saDF", function( ply, key )
    if ( key == IN_ATTACK and ply:GetActiveWeapon() == NULL and !table.HasValue(playfight_server_menu_info, v) and ply.spectating == nil and ply.playtimer ~= nil and !table.HasValue(playfight_players_spectating, v)) and ply.lastavailable ~= nil then
        if !(ply.fell) then
            ply.fell = 0
        end

        -- If the player is not in ragdoll mode, fix that.
        if (ply.fell == 0 and ply:Alive()) then
            -- playtimer controls the delay between ragdolling.
            if ply.playtimer <= 0 then
                ply.fell = 1
                
                ply.leaveDelay = 0.5

                ply.healthBefore = ply:Health()

                ply.timesRagdolled = ply.timesRagdolled or 0
                ply.timesRagdolled = ply.timesRagdolled + 1

                -- Create ragdoll then set it's bones and velocities to match the player.
                local ragdoll = ents.Create("prop_ragdoll")
            
                ragdoll:SetModel(ply:GetModel())
                ragdoll:SetPos(ply:GetPos() + Vector(0,0,0))
                ragdoll:SetAngles(ply:GetAngles())
                ragdoll:SetVelocity(ply:GetVelocity())

                for i = 0, ply:GetNumBodyGroups() do
                    ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
                end
                
                ply.eyeAng = ply:GetAimVector():Angle()

                ragdoll:Spawn()
                ragdoll:Activate()	
        
                ragdoll.ownply = ply

                ragdoll.hitEntities = {}

                ragdoll:SetHealth(ply.healthBefore)
                ply.ragfall = ragdoll


                -- Damaging
                ragdoll:AddCallback("PhysicsCollide", function(ent, data)
                    local hit = data.HitEntity

                    if (hit:IsPlayer() and hit:IsValid() and hit:Alive() and !table.HasValue(ragdoll.hitEntities, hit)) or (hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and !table.HasValue(ragdoll.hitEntities, hit)) then
                        --local totalVelocity = ragdoll:GetVelocity().x + ragdoll:GetVelocity().y
                        local totalVelocity = ragdoll:GetVelocity():Length()

                        local damageToTake = math.floor(math.abs(totalVelocity) / 45)

                        

                        if damageToTake >= 7 and (playfight_player_can_hurt(ply, hit) or (hit.ownply ~= nil and playfight_player_can_hurt(ply, hit.ownply))) then
                            
                            if hit:IsPlayer() then
                                hit:DropWeapon()
                                hit:TakeDamage(damageToTake, ply, ragdoll)
                            elseif hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit ~= ragdoll && !playfight_is_grace_period and playfight_player_can_hurt(ply, hit.ownply) then
                                hit.ownply:TakeDamage(damageToTake, ply, ragdoll)
                                hit.ownply.healthBefore = hit.ownply.healthBefore - damageToTake
                                
                                if hit.ownply.healthBefore <= 0 then
                                    hit.ownply.healthBefore = 100

                                    hit.ownply:SetPos(ply.ragfall:GetPos())

                                    hit.ownply:KillSilent()

                                    net.Start("playfight_hurtsound")
                                    net.Broadcast()



                                    hit.ownply.watchingFreezeCam = true;

                                    timer.Simple(0.1, function()
                                        hit.ownply:Spectate(OBS_MODE_FREEZECAM)
                                        hit.ownply:SpectateEntity(ply)
                                    end)
                                    

                                    net.Start("playfight_client_deathcam_html")
                                    net.WriteBool(true)
                                    net.WriteString(ply:Name())
                                    if ply:SteamID64() ~= nil then
                                        net.WriteString(ply:SteamID64())
                                        net.WriteString(ply:SteamID())
                                    else
                                        net.WriteString("")
                                        net.WriteString("")
                                    end
                                    net.WriteInt(ply:Health(), 18)
                                    net.WriteInt(damageToTake, 18)
                                    net.Send(hit.ownply)

                                    timer.Simple(4.4, function()
                                        net.Start("playfight_client_deathcam_html")
                                        net.WriteBool(false)
                                        net.WriteString("")
                                        net.WriteString("")
                                        net.WriteString("");
                                        net.WriteInt(0, 18)
                                        net.WriteInt(0, 18)
                                        net.Send(hit.ownply)
                                    end)

                                    timer.Simple(5, function()
                                        hit.ownply.watchingFreezeCam = false;
                                        hit.ownply:SpectateEntity(nil)
                                    end)


                                    playfight_send_killfeed(ply:GetName(), ply:Team(), "prop_ragdoll", hit.ownply:GetName(), hit.ownply:Team())
                                    

                                    hit.ownply.fell = 0
                                end
                            end
                        end
                        

                        table.insert(ragdoll.hitEntities, hit)
                    end
                end)

                -- If the ragdoll takes non physics damage, make the player take that damage too.
                function TakeDmg( target, dmg )
    
                    if (target == ragdoll and ply:Alive()) then
                    
                        if !dmg:IsDamageType(1) then
                            if dmg:GetInflictor():IsPlayer() and playfight_player_can_hurt(dmg:GetInflictor(), ply) then
                                ply.healthBefore = ply.healthBefore - (dmg:GetDamage() / 2)

                                ply:SetHealth(ply.healthBefore)

                                -- Do health handling and stuff
                                if(ply.healthBefore <= 0) then
                                    
                                    ply.ragfall = ragdoll

                                    ply.healthBefore = 100

                                    ply:SetPos(ply.ragfall:GetPos())

                                    ply:Kill()
                                    
                                    ply:GetRagdollEntity():Remove()

                                    ply.fell = 0
                                end
                            end
                        end
                    end
                end
                        
                    hook.Add("EntityTakeDamage", "__playfight____takeDamagelolxd__DAAAAAMAAAAGEE", TakeDmg)

                    -- Average player velocity
                    local avgVelocity = 260
                    local eyeVector = Vector(ply:GetAimVector().x, ply:GetAimVector().y, ply:GetAimVector().z) 

                    //local velocityVector = Vector(math.abs(ply:GetVelocity().x), math.abs(ply:GetVelocity().y), 0)

                    //print(ply:GetVelocity())

                    //if (velocityVector.x ~= velocityVector.y) then
                    //    
                    //    if (velocityVector.x > velocityVector.y) then
                    //        avgVelocity = velocityVector.x
                    //    else
                    //        avgVelocity = velocityVector.y
                    //    end
                        
                    //else
                    //    if (velocityVector.x > 0 or velocityVector.y > 0) then
                    //        avgVelocity = velocityVector.x;
                    //    end
                    //end

                    //avgVelocity = math.abs(avgVelocity)

                    --Loop through each bone
                    local numberOfBones = ragdoll:GetPhysicsObjectCount()
                
                    for i = 1, numberOfBones - 1 do 
                
                        local ragBone = ragdoll:GetPhysicsObjectNum( i )	-- Get the current bone
                    
                        if IsValid( ragBone ) then
                    
                        local vicBonePos, vicBoneAng = ply:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )  
                        --get the position of the bone on the player
                                    
                        ragBone:SetPos( vicBonePos ) --set the ragdoll bone position to the player bone position
                        ragBone:SetAngles( vicBoneAng )

                        

                        ragBone:SetVelocity( Vector(eyeVector.x * avgVelocity * 6.0, eyeVector.y * avgVelocity * 6.0, ply:GetVelocity().z) )

                        ragBone:SetMass(12)
                    end

                    ply.ragdollCountdown = 5

                    ply:Spectate( OBS_MODE_CHASE )	
                    ply:SpectateEntity( ragdoll )

                end
            end
        else
            if ply:Alive() and ply.leaveDelay ~= nil && ply.leaveDelay <= 0 then

                

                ply.playtimer = ragdollCooldown

                ply.fell = 0
                ply:Spectate( OBS_MODE_NONE )	
                ply:UnSpectate()
                
                if ( ply.ragfall ~= nil and ply.ragfall ~= NULL) then
                    ply:SetVelocity(ply.ragfall:GetVelocity())
                end
                local oldsuper = ply.superenergy

                ply:Spawn()

                SetSuper(ply, oldsuper)

                if ply.eyeAng ~= nil then
                    ply:SetEyeAngles(ply.eyeAng)
                end

                if ( SERVER ) then
                    ply:SetHealth(ply.healthBefore)
                end
            end
        end
    end
end)  



hook.Add("Tick", "xdxddd__plAYer__clickKKPlay_dEdeaHooK", function() 
    -- Strip weapons from player if they have an empty or invalid weapon, and set their ammo capacity for specific guns(1 bullet for 357, 2 for shotgun)
    for k, v in next, player.GetAll() do

        if v.ragfall ~= nil then
            -- Send the entity id of the ragdoll so the client can display nametags smoothly
            net.Start("playfight_client_ragdoll")
            net.WriteBool(v.fell)
            net.WriteString(v:Nick())
            net.WriteInt(v.ragfall:EntIndex(), 18)
            net.Broadcast()
        else
            -- Send the entity id of the ragdoll so the client can display nametags smoothly
            net.Start("playfight_client_ragdoll")
            net.WriteBool(false)
            net.WriteString(v:Nick())
            net.WriteInt(0, 18)
            net.Broadcast()
        end

        if ( v:GetActiveWeapon() ~= NULL and v:GetActiveWeapon():Clip1() <= 0 and v:GetActiveWeapon():GetHoldType() ~= "physgun") then

            v:StripWeapons()

        end

        if ( v.fell == 1 and v.ragfall ~= nil) then

            v:SetPos(v.ragfall:GetPos())
            
        end

        if ( string.find(tostring(v:GetActiveWeapon()), "weapon_shotgun") and v:GetActiveWeapon():Clip1() > 2) then
            v:GetActiveWeapon():SetClip1(2)
        end

        if ( string.find(tostring(v:GetActiveWeapon()), "weapon_357") and v:GetActiveWeapon():Clip1() > 1) then
            v:GetActiveWeapon():SetClip1(1)
        end

        -- Ragdoll eye angles
        if v.ragfall ~= nil then
            v.eyeAng = v:EyeAngles()
        end

        
    end

    -- Check if it's not warmup, and there's 1 or less people connected to the server. If so, end the game(assuming pf_drawonsolo is set to true)
    if !playfight_game_ended and #player.GetAll() <= 1 and GetGlobalBool("__ident1fier____Warmup_playfight__") == false and GetConVar("pf_drawonsolo"):GetBool() == true then
        playfight_end_game()
        print("game end")
    end

end)

function ForceRagdollPlayer(ply)

    ply.fell = 1
                    
    ply.leaveDelay = 0.5

    ply.healthBefore = ply:Health()

    ply.playtimer = ragdollCooldown


    if ply:GetActiveWeapon() ~= nil and ply:GetActiveWeapon() ~= NULL then
        ply:DropWeapon(ply:GetActiveWeapon())
    end

    ply:StripWeapons()

    -- Create ragdoll then set it's bones and velocities to match the player.
    local ragdoll = ents.Create("prop_ragdoll")

    ragdoll:SetModel(ply:GetModel())
    ragdoll:SetPos(ply:GetPos() + Vector(0,0,0))
    ragdoll:SetAngles(ply:GetAngles())
    ragdoll:SetVelocity(ply:GetAbsVelocity())

    

    for i = 0, ply:GetNumBodyGroups() do
        ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
    end
    
    ply.eyeAng = ply:GetAimVector():Angle()

    ragdoll:Spawn()
    ragdoll:Activate()	

    ragdoll.ownply = ply

    ragdoll.hitEntities = {}

    ragdoll:SetHealth(ply.healthBefore)
    ply.ragfall = ragdoll

    

        -- Damaging
        ragdoll:AddCallback("PhysicsCollide", function(ent, data)
            local hit = data.HitEntity

            if (hit:IsPlayer() and hit:IsValid() and hit:Alive() and !table.HasValue(ragdoll.hitEntities, hit)) or (hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit.ownply:Alive() and !table.HasValue(ragdoll.hitEntities, hit)) then
                local totalVelocity = ragdoll:GetVelocity():Length()

                local damageToTake = math.floor(math.abs(totalVelocity) / 45)

                if damageToTake >= 7 then
                    if hit:IsPlayer() and playfight_player_can_hurt(ply, hit) then
                        hit:TakeDamage(damageToTake, ply, ragdoll)
                        hit:DropWeapon()
                    elseif hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit ~= ragdoll and playfight_player_can_hurt(ply, hit.ownply) then
                        hit.ownply:TakeDamage(damageToTake, ply, ragdoll)
                        hit.ownply.healthBefore = hit.ownply.healthBefore - damageToTake
                        
                        if hit.ownply.healthBefore <= 0 then

                            hit.ownply.healthBefore = 100

                            hit.ownply:SetPos(ply.ragfall:GetPos())

                            hit.ownply:Kill()
                            
                            hit.ownply:GetRagdollEntity():Remove()

                            hit.ownply.fell = 0
                        end
                    end
                end
                

                table.insert(ragdoll.hitEntities, hit)
            end
        end)

        function TakeDmg( target, dmg )

            if (target == ragdoll and ply:Alive()) then
            
                if !dmg:IsDamageType(1)  then

                    ply.healthBefore = ply.healthBefore - (dmg:GetDamage())
                        
                    --do health handling and stuff
                    if(ply.healthBefore <= 0) then
                        
                        ply.ragfall = ragdoll

                        ply.healthBefore = 100

                        ply:SetPos(ply.ragfall:GetPos())

                        ply:Kill()
                        
                        ply:GetRagdollEntity():Remove()

                        ply.fell = 0
                        
                    end 
                end                 
            end
        end
            
        hook.Add("EntityTakeDamage", "__playfight____takeDamagelolxd__DAAAAAMAAAAGEE", TakeDmg)

        --Loop through each bone
        local numberOfBones = ragdoll:GetPhysicsObjectCount()
    
        for i = 1, numberOfBones - 1 do 
    
            local ragBone = ragdoll:GetPhysicsObjectNum( i )	-- Get the current bone
        
            if IsValid( ragBone ) then
        
            local vicBonePos, vicBoneAng = ply:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )  
            --get the position of the bone on the player
                        
            ragBone:SetPos( vicBonePos ) --set the ragdoll bone position to the player bone position
            ragBone:SetAngles( vicBoneAng )

            

            ragBone:SetVelocity( Vector(ply:GetAbsVelocity().x, ply:GetAbsVelocity().y, ply:GetAbsVelocity().z) )

            ragBone:SetMass(12)
        end

        ply.ragdollCountdown = 5

        ply:Spectate( OBS_MODE_CHASE )	
        ply:SpectateEntity( ragdoll )

    end
end





hook.Add("PlayerLoadout", "__playfight_FmgmPSawn__", function( ply )
    -- Use the SetSuper function so the client updates its info correctly for HUD
    PlayfightSendTabInfo(ply)
end)

    timer.Create("__pff__supePRCHaReGe__", 0.2, 0, function()
        for k,v in next, player.GetAll() do
            if GetGlobalBool("__ident1fier____Warmup_playfight__") == false then
                
                if v:KeyDown(IN_ATTACK2) and v.cansuper == 100 then
                    if v.fell == 0 then
                        if v.useenergy == nil then v.useenergy = 0 end

                        if v.cansuper == 100 and v.useenergy < 100  then
                            SetSuper(v, v.superenergy - 15) 
                            if v.useenergy == nil then v.useenergy = 0 end
                            v.useenergy = v.useenergy + 15
                        end

                        if v.useenergy > 100 then
                            v.useenergy = 100
                        end
                    end
                else
                    local amount = 0

                    local inc = 1

                    if v.superenergy + inc < 100 then
                        amount = inc
                    else
                        amount = 0
                        SetSuper(v,100)
                    end

                    if amount ~= 0 then 
                        SetSuper(v,v.superenergy+amount) 
                    end
                end
            end
        end
    end)

function GM:KeyPress(ply, key)
    -- Super charging
    if key == IN_ATTACK2 and ply.superenergy ~= nil and ply.fell == 0 and ply.superenergy == 100 then 
        ply.cansuper = ply.superenergy 

        if ply:GetActiveWeapon() ~= NULL and ply:GetActiveWeapon():GetClass() == "weapon_shotgun" then 
            ply.lastpresswep = true 
        else 
            ply.lastpresswep = false 
        end

        net.Start("playfight_client_supercharging")
        net.WriteBool(true)
        net.WriteString(ply:Nick())
        net.Broadcast()
    end

    -- Throwing weapons
    if key == IN_RELOAD and ply:GetActiveWeapon() ~= NULL then
        ply:DropWeapon(ply:GetActiveWeapon(), nil, ply:EyeAngles():Forward() * 1000) -- Velocity actually clamps at 400 unfortunately
    end
end

-- If super is charged, make player get flung at full force.
function GM:KeyRelease(ply, key)
    if key == IN_ATTACK2 and ply.superenergy ~= nil and ply.fell == 0 and ply.lastpresswep == false and !table.HasValue(playfight_players_spectating, v) then 

        net.Start("playfight_client_supercharging")
        net.WriteBool(false)
        net.WriteString(ply:Nick())
        net.Broadcast()

        ply.cansuper = ply.superenergy 

        -- Use super mechanics here
        if ply.useenergy ~= nil and ply.useenergy ~= 0 then
            if!(ply.fell) then
                ply.fell = 0
            end

            if (ply.fell == 0 and ply:Alive()) then
                ply:SetMaxSpeed(115000)

                if ply:GetActiveWeapon() ~= NULL then ply:DropWeapon(ply:GetActiveWeapon()) end

                ply.timesSupered = ply.timesSupered or 0
                ply.timesSupered = ply.timesSupered + 1

                ply.fell = 1
                
                ply.healthBefore = ply:Health()
            
                local ragdoll = ents.Create("prop_ragdoll")
            
                ragdoll:SetModel(ply:GetModel())
                ragdoll:SetPos(ply:GetPos() + Vector(0,0,0))
                ragdoll:SetAngles(ply:GetAngles())
                ragdoll:SetVelocity(ply:GetVelocity())
            
                for i = 0, ply:GetNumBodyGroups() do
                    ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
                end

                ragdoll:Spawn()
                ragdoll:Activate()	
        
                ragdoll.ownply = ply

                ragdoll.hitEntities = {}

                ragdoll:SetName("superrag")

                ragdoll:SetHealth(ply.healthBefore)
                ply.ragfall = ragdoll


                -- Damaging
                ragdoll:AddCallback("PhysicsCollide", function(ent, data)
                    local hit = data.HitEntity

                    if (hit:IsPlayer() and hit:IsValid() and hit:Alive() and !table.HasValue(ragdoll.hitEntities, hit)) or (hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and !table.HasValue(ragdoll.hitEntities, hit)) then
                        local totalVelocity = ragdoll:GetVelocity():Length()

                        local damageToTake = math.floor(math.abs(totalVelocity) / 45)

                        if damageToTake >= 7 then
                            if hit:IsPlayer() and playfight_player_can_hurt(ply, hit) then
                                hit:TakeDamage(damageToTake, ply, ragdoll)
                                hit:DropWeapon()
                            elseif hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit ~= ragdoll && !playfight_is_grace_period and playfight_player_can_hurt(ply, hit.ownply) then
                                hit.ownply:TakeDamage(damageToTake, ply, ragdoll)
                                hit.ownply.healthBefore = hit.ownply.healthBefore - damageToTake
                                
                                if hit.ownply.healthBefore <= 0 then
                                    hit.ownply.healthBefore = 100

                                    hit.ownply:SetPos(ply.ragfall:GetPos())

                                    hit.ownply:KillSilent()

                                    net.Start("playfight_hurtsound")
                                    net.Broadcast()



                                    hit.ownply.watchingFreezeCam = true;

                                    timer.Simple(0.1, function()
                                        hit.ownply:Spectate(OBS_MODE_FREEZECAM)
                                        hit.ownply:SpectateEntity(ply)
                                    end)
                                    

                                    net.Start("playfight_client_deathcam_html")
                                    net.WriteBool(true)
                                    net.WriteString(ply:Name())
                                    if ply:SteamID64() ~= nil then
                                        net.WriteString(ply:SteamID64())
                                        net.WriteString(ply:SteamID())
                                    else
                                        net.WriteString("")
                                        net.WriteString("")
                                    end
                                    net.WriteInt(ply:Health(), 18)
                                    net.WriteInt(damageToTake, 18)
                                    net.Send(hit.ownply)

                                    timer.Simple(4.4, function()
                                        net.Start("playfight_client_deathcam_html")
                                        net.WriteBool(false)
                                        net.WriteString("")
                                        net.WriteString("")
                                        net.WriteString("");
                                        net.WriteInt(0, 18)
                                        net.WriteInt(0, 18)
                                        net.Send(hit.ownply)
                                    end)

                                    timer.Simple(5, function()
                                        hit.ownply.watchingFreezeCam = false;
                                        hit.ownply:SpectateEntity(nil)
                                    end)

                                    playfight_send_killfeed(ply:GetName(), ply:Team(), "prop_ragdoll", hit.ownply:GetName(), hit.ownply:Team())
                                    

                                    hit.ownply.fell = 0
                                end
                            end
                        end
                        

                        table.insert(ragdoll.hitEntities, hit)
                    end
                end)

                function TakeDmg( target, dmg )
    
                    if (target == ragdoll and ply:Alive()) then
                    
                        if !dmg:IsDamageType(1)  then
        
                            ply.healthBefore = ply.healthBefore - (dmg:GetDamage())
                                
                            --do health handling and stuff
                            if(ply.healthBefore <= 0) then
                                
                                ply.ragfall = ragdoll

                                ply.healthBefore = 100

                                ply:SetPos(ply.ragfall:GetPos())

                                ply:Kill()
                                
                                ply:GetRagdollEntity():Remove()

                                ply.fell = 0
                                
                            end 
                        end                 
                    end
                end
                    
                    hook.Add("EntityTakeDamage", "__playfight_takeDamagelolxd___nonplaydead"..ply:Nick(), TakeDmg)
                
                    -- Average player velocity
                    local avgVelocity = 450 * (ply.useenergy / 100)
                    local eyeVector = Vector(ply:GetAimVector().x, ply:GetAimVector().y, ply:GetAimVector().z) 

                    --Loop through each bone
                    local numberOfBones = ragdoll:GetPhysicsObjectCount()
                
                    for i = 1, numberOfBones - 1 do 
                
                        local ragBone = ragdoll:GetPhysicsObjectNum( i )	-- Get the current bone
                    
                        if IsValid( ragBone ) then
                    
                        local vicBonePos, vicBoneAng = ply:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )  
                        --get the position of the bone on the player
                                    
                        ragBone:SetPos( vicBonePos ) --set the ragdoll bone position to the player bone position
                        ragBone:SetAngles( vicBoneAng )

                        

                        ragBone:SetVelocity( Vector(eyeVector.x * avgVelocity * 9.0, eyeVector.y * avgVelocity * 9.0, eyeVector.y * 3.0) )

                        ragBone:SetMass(12)
                    end

                    ply.ragdollCountdown = 5

                    ply:Spectate( OBS_MODE_CHASE )	
                    ply:SpectateEntity( ragdoll )

                end
            end
        end
        ply.useenergy = 0
    end
end

-- Make sure player doesn't pick a weapon up if they already have a weapon.
hook.Add( "PlayerCanPickupWeapon", "xdDXdX____sDOuble_pickTEsCHECK___", function( ply, wep )
	if ( ply:KeyDown(IN_ATTACK2) ) then return false end

    for k, v in pairs(playfight_weapons_table) do
        if ply:HasWeapon(k) then return false end
    end
end )


hook.Add("PlayerInitialSpawn", "xddd___Xd_playerspawn_setragfall_nil_playf_gight_addon", function( ply )
    ply.ragfall = nil

    -- 0 = Free Roam, 1 = Spectate players in firstperson, 2 = Spectate players in thirdperson
    ply.spectateMode = 0 

    ply:SetModel("models/player/kleiner.mdl")
    ply:SetMaxSpeed(1150)

    util.PrecacheModel("models/weapons/ricochet/c_ricochet_disc.mdl")
    util.PrecacheModel("models/weapons/ricochet/w_ricochet_disc.mdl")

    table.insert(playfight_server_menu_info, ply)

    -- Music
    if !GetGlobalBool("__ident1fier____Warmup_playfight__") then
        net.Start("playfight_client_play_music")
        net.Send(ply)
    end

    -- This variable determines if the player selected the "spectate" option on the main menu, NOT if they are currently spectating after, say, they lost a round.
    ply.spectatingGame = false

    SetSuper(ply, 0);
end)

hook.Add("PlayerSpawn", "I_N_I_T_I_A_L_playerspawn_setragfall_nil_playf_gight_addon", function( ply )
    ply:SetMaxSpeed(1150)

    ply.watchingFreezeCam = false;

    if ply.ragfall ~= nil then
        ply.fell = 0 

        -- Loop through each bone
        local freebone = false

        local numberOfBones = ply.ragfall:GetPhysicsObjectCount()
        
        for i = 1, numberOfBones - 1 do 
            if !freebone then
                local ragBone = ply.ragfall:GetPhysicsObjectNum( i )	-- Get the current bone
            
                if IsValid( ragBone ) then
            
                    local pos = ragBone:GetPos() -- Choose your position.

                    minsply, maxsply = ply:GetHull()

                    local traceply = {
                        start = pos,
                        endpos = pos,
                        mins = Vector( -16, -16, 0 ),
                        maxs = Vector( 16, 16, 71 )
                    }
                    
                    local hullTrace = util.TraceHull( traceply )

                    if !hullTrace.Hit then
                        ply:SetPos(pos)
                        freebone = true
                    end
                end
            end        
        end
        
        if freebone == false then
            if ply.lastavailable == nil then
                ply:SetPos(ply.ragfall:GetPos())
            else
                ply:SetPos(ply.lastavailable)
            end
        end

        ply.ragfall:Remove()
    end
    ply.ragfall = nil


    for k, v in ipairs(player.GetAll()) do
        net.Start("playfight_client_player_menu")
        net.WriteString(v:SteamID())
        net.WriteBool(table.HasValue(playfight_server_menu_info, v))
        net.Broadcast()
    end
end)

-- Collect round stats for win screen
hook.Add( "PlayerDeath", "playfight_round_death_stats_hook", function( victim, inflictor, attacker )
    if attacker ~= nil then
        if attacker:IsPlayer() then
            if attacker ~= victim then
                if attacker.roundKills == nil then
                    attacker.roundKills = 0
                end
                
                attacker.roundKills = attacker.roundKills + 1;
            end
        end
    end
end)

hook.Add( "PlayerHurt", "playfight_round_hurt_stats_hook", function( victim, attacker, healthRemaining, dmgTaken )
    if attacker ~= nil then
        if attacker:IsPlayer() then
            if attacker ~= victim then
                if attacker.roundDmg == nil then
                    attacker.roundDmg = 0
                end
                
                attacker.roundDmg = attacker.roundDmg + dmgTaken;
            end
        end
    end
end)

hook.Add("WeaponEquip", "playfight_stats_equip_weapon", function(weapon, player)
    player.weaponsPickedUp = player.weaponsPickedUp or 0
    player.weaponsPickedUp = player.weaponsPickedUp + 1
end)


-- Respawning
hook.Add("PlayerDeathThink", "__PLayF1Ght_playDeADTTHthINK__", function( ply )
    

    if (!GetGlobalBool("__ident1fier____Warmup_playfight__") or ply.spectatingGame) and !ply.watchingFreezeCam then 
        
        net.Start("playfight_client_spectate_info")
        net.WriteBool(true)
        net.Send(ply)

        if table.HasValue(playfight_players_spectating, ply) then
            -- SPECTATE CONTROLS
            -- Spacebar to toggle between players and free roam.
            if ply:KeyPressed(IN_JUMP) then
                -- Cycle through spectate modes
                if ply.spectateMode == nil then ply.spectateMode = 0 end

                ply.spectateMode = ply.spectateMode + 1
                if ply.spectateMode > 2 then
                    ply.spectateMode = 0
                end

                -- I wish i had switch statements here :)
                -- First Person Spectate
                if ply.spectateMode == 1 then
                    local playerToSpectate = ply.spectatedPlayer

                    if playerToSpectate == nil then
                        local playerToSpectateFound = false

                        for k, v in next, player.GetAll() do
                            if v ~= ply and !table.HasValue(playfight_server_menu_info, v) and v:Alive() and !table.HasValue(playfight_players_spectating, v) then
                                if !playerToSpectateFound then

                                    playerToSpectate = v

                                    playerToSpectateFound = true
                                end
                            end
                        end
                    end

                    if playerToSpectate != nil then
                        ply.spectatedPlayer = playerToSpectate
                    end

                -- Third Person Spectate
                elseif ply.spectateMode == 2 then
                    local playerToSpectate = ply.spectatedPlayer

                    if playerToSpectate == nil then
                        local playerToSpectateFound = false

                        for k, v in next, player.GetAll() do
                            if v ~= ply and !table.HasValue(playfight_server_menu_info, v) and v:Alive() and !table.HasValue(playfight_players_spectating, v) then
                                if !playerToSpectateFound then

                                    playerToSpectate = v

                                    playerToSpectateFound = true
                                end
                            end
                        end
                    end

                    if playerToSpectate ~= nil then
                        ply.spectatedPlayer = playerToSpectate
                    end
                end
            end
        end

        if ply.spectatedPlayer ~= nil and !ply.spectatedPlayer:IsValid() then
            ply:SpectateEntity(NULL)
            ply:Spectate(OBS_MODE_ROAMING)
            ply.spectatedPlayer = nil;
        end

        if table.HasValue(playfight_players_spectating, ply) or ply.spectatingGame then
            -- Send packet to client updating the current spectated player's name
            net.Start("playfight_client_spectate_player_name")
                if ply.spectatedPlayer ~= nil then
                    net.WriteString(ply.spectatedPlayer:Nick())
                else
                    net.WriteString("")
                end
            net.Send(ply)

            if ply.spectatedPlayer ~= nil and ply.spectatedPlayer:IsPlayer() and ply.spectatedPlayer:IsValid() then
                net.Start("playfight_client_spectate_player_healthsuper")
                    local sendHealth = ply.spectatedPlayer:Health()
                    local sendSuper = GetGlobalInt("__playGgfiHti_SUPErCLient_"..ply.spectatedPlayer:Nick())

                    net.WriteFloat(sendHealth)
                    net.WriteFloat(sendSuper)
                net.Send(ply)
            end
            
        end

        -- Cycle through players on left click, or put player into first person spectate mode if they're in free roam
        if ply:KeyPressed(IN_ATTACK) then
            
            local alivePlayers = {}

            for k, v in next, player.GetAll() do
                if !table.HasValue(playfight_players_spectating, v) and !table.HasValue(playfight_server_menu_info, v) and v != ply then
                    table.insert(alivePlayers, v)
                end
            end

            -- If player is in free roam, put them in spectate mode 1(first person)
            if ply.spectateMode == 0 then

                ply.spectateMode = 1
                local playerToSpectateFound = false

                for k, v in next, player.GetAll() do
                    if v ~= ply and !table.HasValue(playfight_server_menu_info, v) and v:Alive() and !table.HasValue(playfight_players_spectating, v) then
                        if !playerToSpectateFound then

                            ply.spectatedPlayer = v

                            playerToSpectateFound = true
                        end
                    end
                end

                -- Send packet to client updating the current spectated player's name
                net.Start("playfight_client_spectate_player_name")
                    if ply.spectatedPlayer != nil then
                        net.WriteString(ply.spectatedPlayer:Nick())
                    else
                        net.WriteString("")
                    end
                net.Send(ply)
            else
                -- Otherwise, just cycle through the players
                local currentIndex = 0
                for k, v in next, alivePlayers do
                    if v == ply.spectatedPlayer and v != ply then
                        currentIndex = k
                    end
                end

                currentIndex = currentIndex + 1

                if currentIndex > #alivePlayers then
                    currentIndex = 0 
                    local playerFound = false

                    for k, v in next, alivePlayers do
                        if v != ply and !table.HasValue(playfight_players_spectating, v) and !table.HasValue(playfight_server_menu_info, v) and !playerFound then
                            currentIndex = k

                            playerFound = true
                        end
                    end
                end

                if alivePlayers[currentIndex] ~= nil then
                    ply.spectatedPlayer = alivePlayers[currentIndex]
                end

                -- Send packet to client updating the current spectated player's name
                net.Start("playfight_client_spectate_player_name")
                    if ply.spectatedPlayer != nil then
                        net.WriteString(ply.spectatedPlayer:Nick())
                    else
                        net.WriteString("")
                    end
                net.Send(ply)
            end
        end

        if ply.spectatedPlayer ~= nil then
            if ply.spectatedPlayer.ragfall ~= nil then
                ply:Spectate(OBS_MODE_CHASE)
                ply:SpectateEntity(ply.spectatedPlayer.ragfall)
            else

                if ply.spectateMode == 0 and ply:GetObserverMode() != OBS_MODE_ROAMING then
                    ply.spectatedPlayer = nil
                    ply:SpectateEntity(NULL)
                    ply:Spectate(OBS_MODE_ROAMING)
                end

                if ply.spectateMode == 1 then
                    ply:Spectate(OBS_MODE_IN_EYE)
                    ply:SpectateEntity(ply.spectatedPlayer)

                    
                end
                if ply.spectateMode == 2 then
                    ply:Spectate(OBS_MODE_CHASE)
                    ply:SpectateEntity(ply.spectatedPlayer)
                end
            end

            -- If spectated player dies, do appropriate action(either move to next player or move to roaming if there are no more players)
            if table.HasValue(playfight_players_spectating, ply.spectatedPlayer) then
                local alivePlayers = {}

                for k, v in next, player.GetAll() do
                    if !table.HasValue(playfight_players_spectating, v) and !table.HasValue(playfight_server_menu_info, v) and v != ply then
                        table.insert(alivePlayers, v)
                    end
                end

                if #alivePlayers > 0 then
                    ply.spectatedPlayer = alivePlayers[1]
                else
                    ply.spectatedPlayer = nil
                    ply:SpectateEntity(NULL)
                    ply:Spectate(OBS_MODE_ROAMING)
                end
            end
        end

        if ply:GetObserverMode() == OBS_MODE_ROAMING or ply.spectatedPlayer ~= nil then
            return false
        end

        if !ply:Alive() then
            ply:Spectate(OBS_MODE_ROAMING)
        end

        if !table.HasValue(playfight_players_spectating, ply) then
            

            table.insert(playfight_players_spectating, ply)
        end
    end

    if !GetGlobalBool("__ident1fier____Warmup_playfight__") then
        return false;
    end
end)

-- Map Selection
local AllMaps = file.Find( "maps/*.bsp", "GAME" )
for key, map in pairs( AllMaps ) do
	AllMaps[ key ] = string.gsub( map, ".bsp", "" )

    if string.sub(AllMaps[key], 0, 3) == "pf_" or AllMaps[key] == "gm_trajectory" then
        table.insert(playfight_mapsinstalled, AllMaps[key])
        table.insert(playfight_mapvotes, 0)
    end
end

for key, map in pairs( AllMaps ) do
	AllMaps[ key ] = string.gsub( map, ".bsp", "" )

    if GetConVar("pf_show_all_maps"):GetBool() == true and string.sub(AllMaps[key], 0, 3) ~= "pf_" and AllMaps[key] ~= "gm_trajectory" then
        table.insert(playfight_mapsinstalled, AllMaps[key])
        table.insert(playfight_mapvotes, 0)
    end
end


-- Helper function to return the highest number in a table. I believe this was used for map selection (Citation Needed)
function max(a)
  local values = {}

  for k,v in pairs(a) do
    values[#values+1] = v
  end
  table.sort(values) -- Automatically sorts lowest to highest

  return values[#values]
end

timer.Create("__playdelay___timer__playfight_____", 0.1, 0, function()
    for k,v in next,player.GetAll() do
        if v.playtimer ~= nil and v.playtimer ~= NULL then
            if v.playtimer > 0 then
                v.playtimer = v.playtimer - 0.1;
            end
        else
            v.playtimer = 0
        end
        
        if v.leaveDelay ~= nil and v.leaveDelay > 0 then
            v.leaveDelay = v.leaveDelay - 0.1
        end

        -- Auto unragdoll
        if v.ragfall ~= nil && v.ragdollCountdown ~= nil then
            v.ragdollCountdown = v.ragdollCountdown - 0.1

            if v.ragdollCountdown <= 0 then
                local ply = v

                -- Take player out of ragdoll
                if ply:Alive() and !table.HasValue(playfight_players_spectating, ply) then

                    ply.fell = 0
                    ply:Spectate( OBS_MODE_NONE )	
                    ply:UnSpectate()

                    if ( ply.ragfall ~= nil and ply.ragfall ~= NULL) then
                        ply:SetVelocity(ply.ragfall:GetVelocity())
                    end
                    local oldsuper = ply.superenergy
                    ply:Spawn()
                    SetSuper(ply, oldsuper)

                    if ply.eyeAng ~= nil then
                        ply:SetEyeAngles(ply.eyeAng)
                    end

                    if ( SERVER ) then
                        ply:SetHealth(ply.healthBefore)
                    end

                end
            end
        end
    end
end)

-- This is responsible for saving the last valid position the player was in so we can safely get out of ragdoll mode without being stuck.
hook.Add("Tick", "__pfPLayIfghIT__tikcFREeeEEEe___Postiion", function()
    for k, ply in next, player.GetAll() do
        if table.HasValue(playfight_server_menu_info, ply) then
            ply:Lock()
        else
            ply:UnLock()
        end

        local pos = ply:GetPos() -- Choose your position.
        
        minsply, maxsply = ply:GetHull()

        local tr = {
            start = pos,
            endpos = pos,
            mins = minsply,
            maxs = maxsply,
            filter = {ply, ply.ragfall}
        }

        local hullTrace = util.TraceHull( tr )


        if !hullTrace.Hit then
            ply.lastavailable = pos
        end

        if !ply:Alive() then
            ply.lastavailable = nil
        end

        -- Teleport to spectated player every tick.
        -- This is because when spectating an entity, gmod doesn't actually set the position of the player to the player that's being spectated
        -- This means that optimizations like area portals or just general visleaf calculations might break in weird ways.
        if ply.spectatedPlayer ~= nil and ply.spectatedPlayer:IsValid() and table.HasValue(playfight_players_spectating, ply) then
            if ply.spectatedPlayer.ragfall ~= nil then
                ply:SetPos(ply.spectatedPlayer.ragfall:GetPos())
            else
                ply:SetPos(ply.spectatedPlayer:GetPos())
            end
        end
        
            net.Start("playfight_client_showlastpos")

            -- Show hulltrace?
            if ply.showlastpos == 0 then
                net.WriteBool(false)
            elseif ply.showlastpos == 1 then
                net.WriteBool(true)
            end
            net.WriteFloat(pos.x)
            net.WriteFloat(pos.y)
            net.WriteFloat(pos.z)

            net.WriteFloat(minsply.x)
            net.WriteFloat(minsply.y)
            net.WriteFloat(minsply.z)

            net.WriteFloat(maxsply.x)
            net.WriteFloat(maxsply.y)
            net.WriteFloat(maxsply.z)

            net.WriteBool(!hullTrace.Hit)

            net.Send(ply)

        -- Killing ragdolls in kill brushes
        -- I made this then realized brushes can be more complex shapes than just boxes
        /*for i, ent in next, ents.GetAll() do
            if ent:GetClass() == "trigger_hurt" then
                local entMin, entMax = ent:GetCollisionBounds()

                //print("entmin"..tostring(entMin))
                //print("entmax"..tostring(entMax))

                local tr = util.TraceHull( {
                    start = ent:GetPos(),
                    endpos = ent:GetPos(),
                    ignoreworld = true,
                    mins = entMin,
                    maxs = entMax
                } )

                if tr.Hit and tr.Entity:GetClass() == "prop_ragdoll" and tr.Entity.ownply ~= nil and tr.Entity.ownply == ply and tr.Entity.ownply:Alive() then
                    ply:Kill()
                    ply:GetRagdollEntity():Remove()
                end
            end
        end*/

    end
end)

hook.Add("PlayerSpawn","__plAPYIghiT ___ _NoCollide __ __ Players", function(ply)
    ply:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end)

-- Helper function
function table.contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

-- Adds super when someone takes damage. Some values are tweaked as needed. Ragdoll is not divided by anything in an attempt to buff ragdoll damage.
hook.Add("EntityTakeDamage", "__ENtityPtaKePLayIGHGHtSUPPER___w_E_E_EEEE_", function(ply, dmg)

    if ply.ownply ~= nil and ply.ownply:IsPlayer() then
        if !playfight_player_can_hurt(dmg:GetAttacker(), ply.ownply) then
            return true
        end
    end

    if dmg:GetInflictor().ownply ~= nil and dmg:GetInflictor().ownply:IsPlayer() then
        if !playfight_player_can_hurt(dmg:GetInflictor().ownply, ply) then
            return true
        end
    end

    if dmg:GetAttacker():IsPlayer() and ply:IsPlayer() then
        if !playfight_player_can_hurt(dmg:GetAttacker(), ply) then
            return true
        end
    end

    

    //if dmg:GetAttacker():GetEntity() ~= nil and dmg:GetAttacker():GetEntity().ownply ~= nil and dmg:GetAttacker():GetEntity().ownply:IsPlayer() then
   //     if !playfight_player_can_hurt(dmg:GetAttacker():GetEntity().ownply, ply) then
    //        print("should cancel")
   //         return true
   //     end
  //  end

    -- Misc Damage
    if GetGlobalBool("__ident1fier____Warmup_playfight__") == false and dmg:GetAttacker() ~= nil and dmg:GetAttacker():IsValid() and dmg:GetAttacker():IsPlayer() then
        if dmg:GetAttacker().cansuper == nil or (dmg:GetAttacker().cansuper ~= nil and dmg:GetAttacker().cansuper < 100) then
            SetSuper(dmg:GetAttacker(),dmg:GetAttacker().superenergy + dmg:GetDamage()/2)
        end
    end

    -- Ragdoll Damage
    if ply:IsPlayer() and dmg:GetAttacker():GetClass() == "prop_ragdoll" and dmg:GetAttacker().ownply ~= nil and dmg:IsDamageType(DMG_CRUSH) then
        return true
    end

    -- Throwable Crowbar Damage
    if GetGlobalBool("__ident1fier____Warmup_playfight__") == false and dmg:GetAttacker() ~= nil and dmg:GetAttacker():GetClass() == "prop_physics" and dmg:GetAttacker().ownply ~= nil then
        if dmg:GetAttacker().ownply.cansuper == nil or (dmg:GetAttacker().ownply.cansuper ~= nil and dmg:GetAttacker().ownply.cansuper < 100) then
            SetSuper(dmg:GetAttacker().ownply,dmg:GetAttacker().ownply.superenergy + dmg:GetDamage()/1.4)
        end
    end

    -- Tell clients to play the hurt sound(currently just a cardboard box sound, not very elegant but is here for now so there's a good damage sound indicator)
    if ply:IsPlayer() then
        net.Start("playfight_hurtsound")
        net.Broadcast()
    end

    -- Drop weapon if player is hurt by ragdoll
    if ply:IsPlayer() and dmg:GetAttacker() ~= nil and dmg:GetAttacker():GetClass() == "prop_ragdoll" and dmg:GetAttacker().ownply ~= nil and (dmg:GetAttacker().ragfall == nil or dmg:GetAttacker():GetName() ~= "superrag")  then
        ply:DropWeapon()
    end

    if playfight_is_grace_period then return true end

    -- Show damage to client
    if ply:IsPlayer() and dmg:GetAttacker():IsPlayer() then
        net.Start("playfight_client_showdamage")

        net.WriteFloat(dmg:GetDamage())

        net.WriteFloat(ply:GetPos().x)
        net.WriteFloat(ply:GetPos().y)
        net.WriteFloat(ply:GetPos().z)

        net.Send(dmg:GetAttacker())
    end


    -- Show damage amount where the hit happened client side
    if ply:IsPlayer() and dmg:GetAttacker().ownply != nil then
        net.Start("playfight_client_showdamage")

        net.WriteFloat(dmg:GetDamage())

        net.WriteFloat(ply:GetPos().x)
        net.WriteFloat(ply:GetPos().y)
        net.WriteFloat(ply:GetPos().z)

        net.Send(dmg:GetAttacker().ownply)
    end

    

    

    -- DEATH CAM
    local killer = dmg:GetAttacker();
    if dmg:GetAttacker().ownply ~= nil and dmg:GetAttacker().ownply:IsPlayer() then
        killer = dmg:GetAttacker().ownply
    end

    

    if !GetGlobalBool("__ident1fier____Warmup_playfight__") and ply:Health() - dmg:GetDamage() <= 0 and ply:IsPlayer() then

        playfight_increase_kills(killer)

        if killer:IsPlayer() then
            ply.watchingFreezeCam = true;

            timer.Simple(0.1, function()
                if ply.watchingFreezeCam == true then
                    ply:Spectate(OBS_MODE_FREEZECAM)
                    if killer.ragfall == nil then
                        ply:SpectateEntity(killer)
                    else
                        ply:SpectateEntity(killer.ragfall)
                    end
                end
            end)
            

            net.Start("playfight_client_deathcam_html")
            net.WriteBool(true)
            net.WriteString(killer:Name())
            if killer:SteamID64() ~= nil then
                net.WriteString(killer:SteamID64())
                net.WriteString(killer:SteamID())
            else
                net.WriteString("")
                net.WriteString("")
            end
            net.WriteInt(killer:Health(), 18)
            net.WriteInt(dmg:GetDamage(), 18)
            net.Send(ply)

            timer.Simple(4.4, function()
                net.Start("playfight_client_deathcam_html")
                net.WriteBool(false)
                net.WriteString("")
                net.WriteString("")
                net.WriteString("");
                net.WriteInt(0, 18)
                net.WriteInt(0, 18)
                net.Send(ply)
            end)

            timer.Simple(5, function()
                if ply.watchingFreezeCam == true then
                    ply.watchingFreezeCam = false;
                    ply:SpectateEntity(nil)
                end
            end)
        else
            ply.watchingFreezeCam = false;
        end
    end

    net.Start("playfight_client_team_win_update")
    net.WriteInt(0, 18) -- Team ID
    net.WriteInt(team.GetScore(0), 18) -- Team Wins
    net.Broadcast()

    net.Start("playfight_client_team_win_update")
    net.WriteInt(1, 18) -- Team ID
    net.WriteInt(team.GetScore(1), 18) -- Team Wins
    net.Broadcast()
end)

hook.Add("PlayerDisconnected", "___playfight_player_disconnect___", function(ply)
    if ply:SteamID64() ~= nil then
        net.Start("playfight_client_playerdisconnect")
        net.WriteString(ply:SteamID64())
        net.Broadcast()
    end
    -- Remove player from spectator table so if they join back it won't mess things up.
    if table.HasValue(playfight_players_spectating, ply) then
        table.RemoveByValue(playfight_players_spectating, ply)
    end
end)

-- If an admin says "you're british" in chat, and peake is in the game, kill him.
hook.Add("PlayerSay", "playfight_kill_peake", function(sender, text, teamChat)
    if sender:IsAdmin() and text == "you're british" then
        print("Killing Peake")
        for k, v in next, player.GetAll() do
            if v:SteamID64() == "76561198168787219" then
                v:Kill()
            end
        end
    end
end)
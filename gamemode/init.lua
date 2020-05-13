AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_scoreboard.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )
include( "network_server.lua" )
include( "balance.lua" )
include( "convars.lua" )
include( "mapmechanics.lua" )
include( "ricochet.lua" )

-- Main game state related variables. Should be pretty self Explanatory.
playfight_currentRound = 0

playfight_mapsinstalled = playfight_mapsinstalled or {}
playfight_mapvotes = playfight_mapvotes or {}
playfight_playersvoted = playfight_playersvoted or {}

local ragdollCooldown = 0.3

-- Set any variables related to player movement here
function GM:PlayerLoadout( ply )

    ply:SetWalkSpeed(400)
    ply:SetRunSpeed(400)

    ply:SetJumpPower(240)

end

-- Ease of use function that sets the player's super bar to a specified amount. Please use this instead of manually doing it, this
-- Ensures that the super does not go over 100 and it also sends the data to the client so the super bar can update as needed.
local function SetSuper( ply, num ) 

    local number = num

    if num > 100 then number = 100 end

    ply.superenergy = number
    
    SetGlobalInt("__playGgfiHti_SUPErCLient_"..ply:Nick(), number)

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



--=RAGDOLLING AND STUFF=--
hook.Add("KeyPress", "xddDDDdplRessKe___saDF", function( ply, key )
    if ( key == IN_ATTACK and ply:GetActiveWeapon() == NULL and !table.HasValue(playfight_server_menu_info, v) and ply.spectating == nil and ply.playtimer ~= nil) then
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
                        local totalVelocity = ragdoll:GetVelocity().x + ragdoll:GetVelocity().y

                        local damageToTake = math.floor(math.abs(totalVelocity) / 45)

                        if damageToTake >= 7 then
                            if hit:IsPlayer() then
                                hit:TakeDamage(damageToTake, ply, ragdoll)
                                hit:DropWeapon()
                            elseif hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit ~= ragdoll then
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

                -- If the ragdoll takes non physics damage, make the player take that damage too.
                function TakeDmg( target, dmg )
    
                    if (target == ragdoll and ply:Alive()) then
                    
                        if !dmg:IsDamageType(1) then
        
                            ply.healthBefore = ply.healthBefore - (dmg:GetDamage() / 2)

                            ply:SetHealth(ply.healthBefore)

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

    for k, v in next, player.GetAll() do

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
    
    -- Send ragdoll information to clients for proper name tag displaying.
    for k, ply in next, player.GetAll() do
        if ply.ragfall ~= nil then
            net.Start("playfight_client_ragdoll")
            net.WriteString(ply:Nick())
            net.WriteBool(true)
            net.WriteFloat(ply.ragfall:GetPos().X)
            net.WriteFloat(ply.ragfall:GetPos().Y)
            net.WriteFloat(ply.ragfall:GetPos().Z)
            net.Broadcast()
        else
            net.Start("playfight_client_ragdoll")
            net.WriteString(ply:Nick())
            net.WriteBool(false)
            net.WriteFloat(0)
            net.WriteFloat(0)
            net.WriteFloat(0)
            net.Broadcast()
        end
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
                local totalVelocity = ragdoll:GetVelocity().x + ragdoll:GetVelocity().y

                local damageToTake = math.floor(math.abs(totalVelocity) / 45)

                if damageToTake >= 7 then
                    if hit:IsPlayer() then
                        hit:TakeDamage(damageToTake, ply, ragdoll)
                        hit:DropWeapon()
                    elseif hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit ~= ragdoll then
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
    SetSuper(ply, 0)

    PlayfightSendTabInfo(ply)
end)

    timer.Create("__pff__supePRCHaReGe__", 0.2, 0, function()
        for k,v in next, player.GetAll() do
            if GetGlobalBool("__ident1fier____Warmup_playfight__") == false then
                
                if !v:KeyDown(IN_ATTACK2) then
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
                else
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
                end
            end
        end
    end)

function GM:KeyPress(ply, key)
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
end

-- If super is charged, make player get flung at full force.
function GM:KeyRelease(ply, key)
    if key == IN_ATTACK2 and ply.superenergy ~= nil and ply.fell == 0 and ply.lastpresswep == false then 

        net.Start("playfight_client_supercharging")
        net.WriteBool(false)
        net.WriteString(ply:Nick())
        net.Broadcast()

        ply.cansuper = ply.superenergy 

        --use super mechanics here
        if ply.useenergy ~= nil and ply.useenergy ~= 0 then
            if!(ply.fell) then
                ply.fell = 0
            end

            if (ply.fell == 0 and ply:Alive()) then
                ply:SetMaxSpeed(115000)

                if ply:GetActiveWeapon() ~= NULL then ply:DropWeapon(ply:GetActiveWeapon()) end

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

                    if (hit:IsPlayer() and hit:IsValid() and hit:Alive() and !table.HasValue(ragdoll.hitEntities, hit)) or (hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit.ownply:Alive() and !table.HasValue(ragdoll.hitEntities, hit)) then
                        local totalVelocity = ragdoll:GetVelocity().x + ragdoll:GetVelocity().y

                        local damageToTake = math.floor(math.abs(totalVelocity) / 45)

                        if damageToTake >= 7 then
                            if hit:IsPlayer() then
                                hit:TakeDamage(damageToTake, ply, ragdoll)
                                hit:DropWeapon()

                                table.insert(ragdoll.hitEntities, hit)
                            elseif hit:GetClass() == "prop_ragdoll" and hit.ownply ~= nil and hit ~= ragdoll then
                                hit.ownply:TakeDamage(damageToTake, ply, ragdoll)
                                hit.ownply.healthBefore = hit.ownply.healthBefore - damageToTake
                                
                                table.insert(ragdoll.hitEntities, hit)

                                if hit.ownply.healthBefore <= 0 then

                                    hit.ownply.healthBefore = 100

                                    hit.ownply:SetPos(ply.ragfall:GetPos())

                                    hit.ownply:Kill()
                                    
                                    hit.ownply:GetRagdollEntity():Remove()

                                    hit.ownply.fell = 0
                                end
                            end
                        end
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
end)

hook.Add("PlayerSpawn", "xddd_I_N_I_T_I_A_L_Xd_playerspawn_setragfall_nil_playf_gight_addon", function( ply )

    ply:SetMaxSpeed(1150)

    if ply.ragfall ~= nil then
        ply.fell = 0 

        -- Loop through each bone
        local freebone = false

        local numberOfBones = ply.ragfall:GetPhysicsObjectCount()
        
        for i = 1, numberOfBones - 1 do 
            if !freebone then
                local ragBone = ply.ragfall:GetPhysicsObjectNum( i )	--Get the current bone
            
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


    for k, v in next, player.GetAll() do
        net.Start("playfight_client_player_menu")
        net.WriteString(v:SteamID())
        net.WriteBool(table.HasValue(playfight_server_menu_info, v))
        net.Broadcast()
    end
end)

-- Respawning
hook.Add("PlayerDeathThink", "__PLayF1Ght_playDeADTTHthINK__", function( ply )
    if !GetGlobalBool("__ident1fier____Warmup_playfight__") then 
        if (ply:GetObserverMode() == OBS_MODE_ROAMING) then
            return false
        end

        ply:Spectate(OBS_MODE_ROAMING)
    end
end)

local playfight_mapcount = 1

-- Map Selection
local AllMaps = file.Find( "maps/*.bsp", "GAME" )
for key, map in pairs( AllMaps ) do
	AllMaps[ key ] = string.gsub( map, ".bsp", "" )
    if string.sub(AllMaps[key], 0, 3) == "pf_" then
        playfight_mapsinstalled[playfight_mapcount] = AllMaps[key]
        playfight_mapvotes[playfight_mapcount] = 0
        playfight_mapcount = playfight_mapcount + 1
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
                if ply:Alive() then

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


        //net.Start("playfight_client_showlastpos")
        //net.WriteFloat(pos.x)
        //net.WriteFloat(pos.y)
        //net.WriteFloat(pos.z)

        //net.WriteFloat(minsply.x)
        //net.WriteFloat(minsply.y)
        //net.WriteFloat(minsply.z)

        //net.WriteFloat(maxsply.x)
        //net.WriteFloat(maxsply.y)
        //net.WriteFloat(maxsply.z)

        //net.WriteBool(!hullTrace.Hit)

        //net.Send(ply)
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

    -- Misc Damage
    if GetGlobalBool("__ident1fier____Warmup_playfight__") == false and dmg:GetAttacker() ~= nil and dmg:GetAttacker():IsValid() and dmg:GetAttacker():IsPlayer() then
        SetSuper(dmg:GetAttacker(),dmg:GetAttacker().superenergy + dmg:GetDamage()/2)
    end

    -- Ragdoll Damage
    if ply:IsPlayer() and dmg:GetAttacker():GetClass() == "prop_ragdoll" and dmg:GetAttacker().ownply ~= nil and dmg:IsDamageType(DMG_CRUSH) then
        return true
    end

    -- Throwable Crowbar Damage
    if GetGlobalBool("__ident1fier____Warmup_playfight__") == false and dmg:GetAttacker() ~= nil and dmg:GetAttacker():GetClass() == "prop_physics" and dmg:GetAttacker().ownply ~= nil then
        SetSuper(dmg:GetAttacker().ownply,dmg:GetAttacker().ownply.superenergy + dmg:GetDamage()/1.4)
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

    if ply:IsPlayer() and dmg:GetAttacker().ownply != nil then
        net.Start("playfight_client_showdamage")

        net.WriteFloat(dmg:GetDamage())

        net.WriteFloat(ply:GetPos().x)
        net.WriteFloat(ply:GetPos().y)
        net.WriteFloat(ply:GetPos().z)

        net.Send(dmg:GetAttacker().ownply)
    end
end)

hook.Add("PlayerDisconnected", "___playfight_player_disconnect___", function(ply)
    net.Start("playfight_client_playerdisconnect")
    net.WriteString(ply:SteamID())
    net.Broadcast()
end)
AddCSLuaFile()

SWEP.ViewModel = Model( "models/weapons/c_stunstick.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_stunbaton.mdl" )

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= 1
SWEP.Secondary.DefaultClip	= 1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"


SWEP.PrintName	= "#PLAYFIGHT_StunStick"

SWEP.Slot		= 5
SWEP.SlotPos	= 2

SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= true
SWEP.Spawnable		= true
SWEP.UseHands       = true

SWEP.ShootSound = Sound( "Weapon_Crowbar.Single" )

if ( SERVER ) then

	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false

end

SWEP.canUse = true

-- Initialize Stuff
--
function SWEP:Initialize()

	self:SetHoldType( "melee" )

end

function SWEP:PrimaryAttack( right )
	if not IsValid(self:GetOwner()) then return end

	self.Owner:SetAnimation( PLAYER_ATTACK1 )

	local anim = self:GetSequenceName(self.Owner:GetViewModel():GetSequence())

	self.Owner:LagCompensation(true)

	if self.canUse then
		local spos = self:GetOwner():GetShootPos()
		local sdest = spos + (self:GetOwner():GetAimVector() * 70)

		local kmins = Vector(1,1,1) * -10
		local kmaxs = Vector(1,1,1) * 10

		local tr = util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

		-- Hull might hit environment stuff that line does not hit
		if not IsValid(tr.Entity) then
			tr = util.TraceLine({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL})
		end

		local ply = tr.Entity

   		if IsValid(ply) and self.canUse then
			self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )

			local edata = EffectData()
			edata:SetStart(spos)
			edata:SetOrigin(tr.HitPos)
			edata:SetNormal(tr.Normal)
			edata:SetEntity(ply)

			if ply:IsPlayer() or ply:GetClass() == "prop_ragdoll" then
				util.Effect("BloodImpact", edata)
			end
			if SERVER and ply:IsPlayer() and (ply.ragfall == nil or ply.ragfall == NULL) then
				ply.fell = 1
							
				ply.healthBefore = ply:Health()

				ply.playtimer = 1.5

				if ply:HasWeapon("weapon_shotgun") or ply:HasWeapon("weapon_357") or ply:HasWeapon("throwable_crowbar") or ply:HasWeapon("stun_baton") then
					ply:DropWeapon(ply:GetActiveWeapon())
				end
				local ragdoll = ents.Create("prop_ragdoll")
			
				ragdoll:SetModel(ply:GetModel())
				ragdoll:SetPos(ply:GetPos() + Vector(0,0,0))
				ragdoll:SetAngles(ply:GetAngles())
				ragdoll:SetVelocity(ply:GetVelocity())

				for i = 0, ply:GetNumBodyGroups() do
					ragdoll:SetBodygroup(i, ply:GetBodygroup(i))
				end
				
				ply.eyeAng = ply:GetAimVector():Angle()

				ply.stuntimer = 5.0

				ragdoll:Spawn()
				ragdoll:Activate()	
		
				ragdoll.ownply = ply

				ragdoll:SetHealth(ply.healthBefore)
				ply.ragfall = ragdoll
					function TakeDmg( target, dmg )
		
						if (target == ragdoll and ply:Alive()) then
						
							if (dmg:IsDamageType(1) ) then
								if dmg:GetAttacker():GetClass() == "prop_ragdoll" and dmg:GetAttacker():GetName() ~= "superrag" and math.abs( dmg:GetAttacker():GetVelocity().x + dmg:GetAttacker():GetVelocity().y) > math.abs(ragdoll:GetVelocity().x + ragdoll:GetVelocity().y) then
									ply.healthBefore = ply.healthBefore - (dmg:GetDamage()/90)

									print(math.abs(dmg:GetAttacker():GetVelocity().x + dmg:GetAttacker():GetVelocity().y))
									print(math.abs(ragdoll:GetVelocity().x + ragdoll:GetVelocity().y))
									print(dmg:GetDamage()/90)
									print("-")
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
							else
			
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
						
						--return false
					end
						
					hook.Add("EntityTakeDamage", "__playfight____takeDamagelolxd__DAAAAAMAAAAGEE", TakeDmg)

					--Loop through each bone
					local numberOfBones = ragdoll:GetPhysicsObjectCount()
				
					for i = 1, numberOfBones - 1 do 
				
						local ragBone = ragdoll:GetPhysicsObjectNum( i )	--Get the current bone
					
						if IsValid( ragBone ) then
					
						local vicBonePos, vicBoneAng = ply:GetBonePosition( ragdoll:TranslatePhysBoneToBone( i ) )  
						--get the position of the bone on the player
									
						ragBone:SetPos( vicBonePos ) --set the ragdoll bone position to the player bone position
						ragBone:SetAngles( vicBoneAng )
							
						if ply:GetVelocity().x <= 1050 and ply:GetVelocity().y <= 1050 then
							ragBone:SetVelocity( Vector(ply:GetVelocity().x * 3.5, ply:GetVelocity().y * 3.5, ply:GetVelocity().z) )
						else
							ragBone:SetVelocity( Vector(ply:GetVelocity().x/ply:GetVelocity().x * 1050, ply:GetVelocity().y/ply:GetVelocity().y * 1050, ply:GetVelocity().z) )
						end
					end

					ply:Spectate( OBS_MODE_CHASE )	
					ply:SpectateEntity( ragdoll )

				end
			end
			self.canUse = false

			if SERVER then
				self:Remove()
			end
		elseif self.canUse then
			self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )

			if SERVER then
				self.canUse = false
				timer.Simple(0.1, function()
					self:Remove()
				end)
			end
		end
		self:GetOwner():LagCompensation(false)
	end
end

-- Override this to get rid of the default shooting, we don't actually need to put anything here.
function SWEP:SecondaryAttack()
end

function SWEP:Tick()
    
end

--
-- Deploy - Allow lastinv
--
function SWEP:Deploy()

	return true

end
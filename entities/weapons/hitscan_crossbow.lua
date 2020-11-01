AddCSLuaFile()

SWEP.ViewModel = Model( "models/weapons/c_crossbow.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_crossbow.mdl" )

SWEP.Primary.ClipSize		= 1
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= 0
SWEP.Secondary.DefaultClip	= 0
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"


SWEP.PrintName	= "Crossbow"

SWEP.Slot		= 5
SWEP.SlotPos	= 1

SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= true
SWEP.Spawnable		= true
SWEP.UseHands       = true

local crossbowDamage = 25

SWEP.ShootSound = Sound( "Weapon_Crossbow.BoltFly" )

if SERVER then

	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false

end

SWEP.canUse = true

-- Initialize Stuff
--
function SWEP:Initialize()

	self:SetHoldType( "crossbow" )

end

function SWEP:Equip(newOwner)
    if self.canUse == false then
        newOwner:StripWeapons()
    end

    util.PrecacheModel("models/weapons/c_crossbow.mdl")
    util.PrecacheModel("models/weapons/w_crossbow.mdl")

    self:SetModel("models/weapons/c_crossbow.mdl")
end


local globalEnt = nil

-- Shoot the cross bow
function SWEP:PrimaryAttack()
    ply = self:GetOwner()

    if self.canUse then
        ply:LagCompensation(true)

        self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        
        ply:SetAnimation(PLAYER_ATTACK1)

        ply:EmitSound(self.ShootSound)
        ply:EmitSound(Sound( "Weapon_Crossbow.Single" ))

        local spos = self:GetOwner():GetShootPos()
		local sdest = spos + (self:GetOwner():GetAimVector() * 70000)

		local kmins = Vector(1,1,1) * -10
		local kmaxs = Vector(1,1,1) * 10

		local tr = util.TraceHull({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

		-- Hull might hit environment stuff that line does not hit
		if !IsValid(tr.Entity) then
			tr = util.TraceLine({start=spos, endpos=sdest, filter=self:GetOwner(), mask=MASK_SHOT_HULL})
		end

		local hitPly = tr.Entity

        -- Hurt player and ragdoll them
        if SERVER then
            if hitPly ~= nil and hitPly:IsPlayer() and playfight_player_can_hurt(ply, hitPly) then
                local direction = ply:EyeAngles():Forward()

                
                hitPly:TakeDamage(crossbowDamage, ply, self)
                hitPly:SetAbsVelocity(Vector(direction.x * 2000, direction.y * 2000, direction.z * 2000))
                if hitPly:Alive() then
                    ForceRagdollPlayer(hitPly)
                end
                -- Fake damage and damage sound
                net.Start("playfight_client_showdamage")

                net.WriteFloat(crossbowDamage)

                net.WriteFloat(hitPly:GetPos().x)
                net.WriteFloat(hitPly:GetPos().y)
                net.WriteFloat(hitPly:GetPos().z)

                net.Send(ply)



                net.Start("playfight_hurtsound")
                net.Broadcast()

                
            end

            timer.Simple(0.05, function()
                ply:StripWeapons()
            end)
        end
        self.canUse = false
    end
    self:GetOwner():LagCompensation(false)
end

--override this to get rid of the default shooting, we don't actually need to put anything here besides the function
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
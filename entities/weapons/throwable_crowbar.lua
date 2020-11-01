AddCSLuaFile()

SWEP.ViewModel = Model( "models/weapons/c_crowbar.mdl" )
SWEP.WorldModel = Model( "models/weapons/w_crowbar.mdl" )

SWEP.Primary.ClipSize		= 5
SWEP.Primary.DefaultClip	= 5
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= 5
SWEP.Secondary.DefaultClip	= 5
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"


SWEP.PrintName	= "Throwable Crowbar"

SWEP.Slot		= 5
SWEP.SlotPos	= 1

SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= true
SWEP.Spawnable		= true
SWEP.UseHands       = true

SWEP.ShootSound = Sound( "Weapon_Crowbar.Single" )

if ( SERVER ) then

	SWEP.AutoSwitchTo		= false
	SWEP.AutoSwitchFrom		= false

end

SWEP.canThrow = true

-- Initialize Stuff
--
function SWEP:Initialize()

	self:SetHoldType( "melee" )

end

function SWEP:Equip(newOwner)
    self.canThrow = true

    util.PrecacheModel("models/weapons/c_crowbar.mdl")
    util.PrecacheModel("models/weapons/w_crowbar.mdl")

    self:SetModel("models/weapons/c_crowbar.mdl")
end


local globalEnt = nil

--throw the crowbar
function SWEP:PrimaryAttack()

    --if CLIENT then return end --only do this server sided
    if self.canThrow and self.Owner ~= nil then
        ply = self:GetOwner()

        ply:LagCompensation(true)

        self.Weapon:SendWeaponAnim(ACT_VM_MISSCENTER)
        ply:SetAnimation(PLAYER_ATTACK1)

        ply:EmitSound(self.ShootSound)

        timer.Simple(0.1, function()
            if SERVER and self.Owner:IsValid() and self.Owner:Alive() then
                local ent = ents.Create( "prop_physics" )

                if ( !IsValid( ent ) or self.Owner == nil) then return end

                ent:SetModel( "models/weapons/w_crowbar.mdl" )

                ent:SetPos( self.Owner:EyePos() - Vector(0,0,15) + ( self.Owner:GetAimVector() * 25 ) )

                local ang = self.Owner:EyeAngles()

                ang:RotateAroundAxis(self.Owner:GetAimVector():Angle():Up(), 180)

                ent:SetAngles( ang )
                ent:Spawn()
                
                -- For getting super when damaging
                ent.ownply = ply

                local phys = ent:GetPhysicsObject()

                if ( !IsValid( phys ) ) then ent:Remove() return end

                local velocity = self.Owner:GetAimVector()
                velocity = Vector(velocity.x * 2500, velocity.y * 2500, velocity.z * 2500)

                phys:SetVelocity(velocity)
                
                --remove the crowbar after 8 seconds
                timer.Simple(8, function()
                    if ent ~= nil then
                        ent:Remove()
                    end
                end)

                --remove the weapon from the player so we get the effect it was thrown
                self.Owner:StripWeapons()

                
            end
        end)

        self:GetOwner():LagCompensation(false)
        globalEnt = ent
        self.canThrow = false
    end
end

--override this to get rid of the default shooting, we don't actually need to put anything here besides the function
function SWEP:SecondaryAttack()
end

function SWEP:Tick()
    
end
/*if CLIENT then
    hook.Add("PreDrawHalos", "__PlayFighHt__Halo_DrAw__", function()
        if globalEnt ~= nil then

            local halodEntities = {}
            table.insert(halodEntities, 0, globalEnt)

            halo.Add(halodEntities, Color(229, 30, 30))
            
        else
            //print("bruh")
        end
    end)
end*/

--
-- Deploy - Allow lastinv
--
function SWEP:Deploy()

	return true

end
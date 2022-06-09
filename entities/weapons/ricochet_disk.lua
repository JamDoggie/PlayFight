AddCSLuaFile()

SWEP.ViewModel = Model( "models/weapons/ricochet/c_ricochet_disc.mdl" )
SWEP.WorldModel = Model( "models/weapons/ricochet/w_ricochet_disc.mdl" )


SWEP.Primary.ClipSize		= 5
SWEP.Primary.DefaultClip	= 5
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"

SWEP.Secondary.ClipSize		= 5
SWEP.Secondary.DefaultClip	= 5
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"

SWEP.PrintName	= "Ricochet Disk"

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

SWEP.usesLeft = 1

-- Initialize Stuff
--
function SWEP:Initialize()

	self:SetHoldType( "melee" )
    self:SetModel("models/weapons/ricochet/c_ricochet_disc.mdl")

end

function SWEP:Equip(newOwner)

    self.canThrow = true

    util.PrecacheModel("models/weapons/ricochet/c_ricochet_disc.mdl")
    util.PrecacheModel("models/weapons/ricochet/w_ricochet_disc.mdl")

    self:SetModel("models/weapons/ricochet/c_ricochet_disc.mdl")

    self.Weapon:SendWeaponAnim(ACT_SLAM_THROW_ND_DRAW)

    timer.Simple(0.4, function()
        self.Weapon:SendWeaponAnim(ACT_SLAM_THROW_ND_IDLE)
        print("idle")
    end)

    net.Start("playfight_client_playsound")
    net.WriteString("gunpickup2.wav")
    net.Send(self:GetOwner())
end

-- Throw the crowbar
function SWEP:PrimaryAttack()
    ply = self:GetOwner()

    ply:LagCompensation(true)

    if self.canThrow then
        self.Weapon:SendWeaponAnim(ACT_SLAM_THROW_THROW_ND)

        self.canThrow = false

        ply:SetAnimation(PLAYER_ATTACK1)

        timer.Simple(0.12, function()
            if self.Weapon ~= nil and self.Owner:IsValid() and self.Owner:Alive() then
                self.Weapon:SendWeaponAnim(ACT_SLAM_THROW_THROW_ND2)

                -- Throw the disk
                if SERVER then
                    self.usesLeft = self.usesLeft - 1

                    local disk = ents.Create("prop_physics")
                    disk:SetModel("models/weapons/ricochet/w_ricochet_disc.mdl" )

                    disk:SetPos( self.Owner:EyePos() - Vector(0,0,15) + ( self.Owner:GetAimVector() * 25 ) )

                    disk:Spawn()

                    disk.directionVector = Angle(0, ply:EyeAngles().y, ply:EyeAngles().r):Forward()

                    disk.posZ = disk:GetPos().z

                    disk.bounceIncrement = 7

                    disk.bounceDelay = 5

                    disk.canRemove = false

                    disk.owner = ply

                    timer.Create("playfight_ricochet_disk_dissapear_timer"..#playfight_ricochet_disks, disk.bounceDelay, 1, function()
                        if disk ~= nil and disk:IsValid() then
                            disk.canRemove = true
                        end
                    end)

                    local function physFunction(ent, data)

                        local outVector = disk.directionVector - (2 * disk.directionVector:Dot(data.HitNormal)) * data.HitNormal

                        disk.directionVector = Vector(outVector.x, outVector.y, 0);

                        disk.bounceIncrement = disk.bounceIncrement - 1

                        if SERVER then
                            disk:EmitSound("cbar_miss1.wav")
                        end

                        if disk.bounceIncrement <= 0 and disk.canRemove  then
                            disk:Remove()

                            disk:EmitSound("shatter.wav")
                        end

                        local diskDamage = 50

                        if data.HitEntity:IsValid() and data.HitEntity:IsPlayer() and data.HitEntity ~= disk.owner and playfight_player_can_hurt(disk.owner, data.HitEntity) then
                            disk:EmitSound("decap.wav")

                            local plyr = data.HitEntity

                            plyr:TakeDamage(diskDamage, disk.owner, disk)

                            plyr.dmgUsingDisk = plyr.dmgUsingDisk or 0
                            plyr.dmgUsingDisk = plyr.dmgUsingDisk + diskDamage

                            timer.Remove("playfight_ricochet_disk_dissapear_timer"..#playfight_ricochet_disks)
                            disk:Remove()
                        end

                        //print("normal")
                        //print(data.HitNormal) -- The normal
                        //print("direction")
                        //print(disk.directionVector) -- The direction of the disk
                        //print("newvec")
                        //print(outVector) -- output vector
                    end

                    disk:AddCallback("PhysicsCollide", physFunction)

                    table.insert(playfight_ricochet_disks, disk)

                    if self:IsValid() and self.Owner:IsValid() and self.Owner:Alive() and self.usesLeft <= 0 then
                        timer.Simple(0.2, function()
                            self:Remove()
                        end)
                    end

                    
                end
            
                timer.Simple(0.34, function()
                    if self.Weapon ~= nil then
                        self.Weapon:SendWeaponAnim(ACT_SLAM_THROW_ND_DRAW)
                        timer.Simple(0.34, function()
                            
                            print("idle")
                            self.canThrow = true
                        end)
                    end
                end)
            end
        end)
    end

    ply:LagCompensation(false)
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
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
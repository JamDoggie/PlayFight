-- Weapon balancing. Mainly just nerfing the 357 a bit.
function GM:ScalePlayerDamage(ply, hitgroup, dmg)
    if dmg:GetAttacker() ~= nil and dmg:GetAttacker():IsPlayer() and dmg:GetAttacker():GetActiveWeapon() ~= NULL then

        print (dmg:GetAttacker():GetActiveWeapon())

        if dmg:GetAttacker():GetActiveWeapon():GetClass() == "weapon_357" then
                dmg:ScaleDamage(0.50)
        end

        if dmg:GetAttacker():GetActiveWeapon():GetClass() == "weapon_shotgun" then
                dmg:ScaleDamage(1.0)
        end
    end
end

-- Disable fall damage.
function GM:GetFallDamage( ply, speed )
	return 0
end
playfight_ricochet_disks = playfight_ricochet_disks or {}

hook.Add("Tick", "__playfight_disk_velocity__", function()
    for k,v in next, playfight_ricochet_disks do

        if v ~= nil and v ~= NULL and v:GetPhysicsObject() ~= nil and v:GetPhysicsObject() ~= NULL and v:GetPhysicsObject():IsValid() and v.directionVector ~= nil then
            v:SetLagCompensated(true)

            local normalizedVector = v.directionVector:GetNormalized()

            v:GetPhysicsObject():SetVelocity(Vector(normalizedVector.x * 1200, normalizedVector.y * 1200, 10))

            //v:SetPos(Vector(v:GetPos().x, v:GetPos().y, v.posZ))

            v:GetPhysicsObject():SetAngles(Angle(0, 0, 0))
            v:SetAngles(Angle(0, 0, 0))
            
            
        end
    end
end)

hook.Add("EntityTakeDamage", "___playfight_ricochet_takedamage___", function(target, dmg)

    -- Detect if damage inflictor was a ricochet disk
    if dmg:GetAttacker().bounceIncrement ~= nil then
        return true
    end

end)
local netstring = "HANDOFFPUNCH"

local stats = {
    ["dmg"] = 25,
    ["range"] = 64
}

if SERVER then
    util.AddNetworkString(netstring)
    HandOff.StatusTable["punch_windup"] = function(ply)
        local tr = util.QuickTrace(ply:GetShootPos(),ply:EyeAngles():Forward()*stats.range,{ply,ply:GetActiveWeapon()})
        if tr.Hit and tr.Fraction<1 and IsValid(tr.Entity) then
            local bul = {
                ["Damage"] = stats.dmg,
                ["Src"] = tr.HitPos - tr.HitNormal * 4,
                ["Dir"] = tr.HitPos + tr.HitNormal * 4
            }
            ply:FireBullets(bul)
        end
    end
    concommand.Add("+punch", function(ply)
        if HandOff.Status ~= "idle" then return end
        HandOff.Status = "punch_windup"
        HandOff.StatusEnd = CurTime()+0.2
        net.Start(netstring)
        net.Send(ply)
    end)
else
    local punchTable = {
        ["model"] = "models/weapons/c_arms_animations.mdl",
        ["sequence"] = "fists_left",
        ["draw"] = false,
        ["left"] = true,
        ["blendin"] = true,
        ["blendout"] = true,
        ["loop"] = false,
        ["follow_vm"] = false,
        ["active"] = true
    }
    net.Receive(netstring, function()
        HandOff.UpdateCTable(punchTable)
        HandOff.Status = "punch_windup"
        HandOff.StatusEnd = CurTime()+0.2
    end)
end
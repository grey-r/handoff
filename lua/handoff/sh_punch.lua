local netstring = "HANDOFFPUNCH"

local stats = {
    ["dmg"] = 25,
    ["range"] = 64
}

local function cbf(a,b,c)
    if c then
        c:SetDamageType(DMG_CLUB)
    end
end

HandOff.StatusTable["punch_windup"] = function(ply)
    if not IsFirstTimePredicted() then return end
    local tr = util.QuickTrace(ply:GetShootPos(),ply:EyeAngles():Forward()*stats.range,{ply,ply:GetActiveWeapon()})
    if tr.Hit and tr.Fraction<1 then
        local bul = {
            ["Damage"] = stats.dmg,
            ["Src"] = tr.HitPos - tr.Normal * 4,
            ["Dir"] = tr.Normal * 8,
            ["Distance"] = 8,
            ["Callback"] = cbf
        }
        ply:FireBullets(bul)
    end
    HandOff.Status="punch"
    HandOff.StatusEnd=CurTime()+0.5
end

if SERVER then
    util.AddNetworkString(netstring)
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
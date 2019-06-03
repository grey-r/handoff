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

local punchTable = {
    ["model"] = "models/weapons/c_arms_animations.mdl",
    ["sequence"] = "fists_left",
    ["draw"] = false,
    ["left"] = true,
    ["blendin"] = true,
    ["blendout"] = true,
    ["loop"] = false,
    ["follow_vm"] = false,
    ["active"] = true, 
    ["events"] = {
        { ["time"] = 0.1, ["type"] = "sound", ["value"] = Sound("weapons/357_fire2.wav") },
        { ["time"] = 0.5, ["type"] = "lua", ["value"] = function() print("fuck") end }
    }
}

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
    ply.HandOffStatus="punch"
    ply.HandOffStatusEnd=CurTime()+0.5
end

if SERVER then
    util.AddNetworkString(netstring)
    concommand.Add("+punch", function(ply)
        if ply.HandOffStatus ~= "idle" then return end
        ply.HandOffStatus = "punch_windup"
        ply.HandOffStatusEnd = CurTime()+0.2
        net.Start(netstring)
        net.Send(ply)
        HandOff.UpdateCTable(ply,punchTable)
    end)
else
    net.Receive(netstring, function()
        local ply = LocalPlayer()
        HandOff.UpdateCTable(ply,punchTable)
        ply.HandOffStatus= "punch_windup"
        ply.HandOffStatusEnd = CurTime()+0.2
    end)
end
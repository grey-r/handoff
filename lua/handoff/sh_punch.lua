local netstring = "HANDOFFPUNCH"

if SERVER then
    util.AddNetworkString(netstring)
    concommand.Add("+punch", function(ply)
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
        HandOff.RequestCTable(punchTable)
    end)
end
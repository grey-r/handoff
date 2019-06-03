if SERVER then
    AddCSLuaFile()
end
HandOff = HandOff or {}
HandOff.StatusTable = HandOff.StatusTable or {
    --["test"] = function() print("status ended") end
}

HandOff.CTable = {
    ["model"] = "models/weapons/c_arms_animations.mdl",
    ["sequence"] = "fists_left",
    ["draw"] = false,
    ["left"] = true,
    ["blendin"] = true,
    ["blendout"] = true,
    ["loop"] = false,
    ["follow_vm"] = true,
    ["active"] = false,
    ["events"] = {
        --[[
            { ["time"] = 0.1, ["type"] = "lua", ["value"] = function( wep, viewmodel ) end, ["client"] = true, ["server"] = true},
            { ["time"] = 0.1, ["type"] = "sound", ["value"] = Sound("x") }
        ]]
    }
}

function HandOff.UpdateCTable(ply,t)
    if not ply.CTable then
        ply.CTable=table.Copy(HandOff.CTable)
    end
    local og_model = ply.CTable.model
    local og_seq = ply.CTable.sequence
    local og_act = ply.CTable.active
    table.Empty(ply.CTable.events)
    table.Merge(ply.CTable,table.Copy(t))
    if HandOff.Events then
        HandOff.Events.StartTime = CurTime()
    end
    if not CLIENT then return end
    if og_model ~= ply.CTable.model then
        HandOff.UpdateCMod()
    end
    if (og_seq ~= ply.CTable.sequence or og_actg ~= ply.CTable.active) and ply.CTable.active then
        HandOff.PlaySequence(ply.CTable.sequence)
    end
end

function HandOff.Update(ply)
    ply.HandOffStatus = ply.HandOffStatus or "idle"
    ply.HandOffStatusEnd = ply.HandOffStatusEnd or -1
    if ply.HandOffStatusEnd~=-1 and ply.HandOffStatusEnd<=CurTime() then
        local f = HandOff.StatusTable[ply.HandOffStatus]
        ply.HandOffStatusEnd=-1
        ply.HandOffStatus="idle"
        if f then
            f(ply)
        end
    end
end

hook.Add("PlayerTick","HandOff",HandOff.Update)
if game.SinglePlayer() and CLIENT then
    hook.Add("Think","HandOff",function()
        local ply = LocalPlayer()
        if IsValid(ply) then
            HandOff.Update(ply)
        end
    end)
end

local path = "handoff/framework/"
local flist = file.Find(path.."*.lua","LUA")

for _, filename in pairs(flist) do

    local typev = "SHARED"
    if filename:StartWith("cl_") then
        typev = "CLIENT"
    elseif filename:StartWith("sv_") then
        typev = "SERVER"
    end

    if SERVER and typev ~= "SERVER" then
        AddCSLuaFile( path.. filename )
    end

    if ( SERVER and typev ~= "CLIENT" ) or ( CLIENT and typev ~= "SERVER" ) then
        include( path..filename )
        --print("Initialized " .. filename .. " || " .. fileid .. "/" .. #flist )
    end

end

path = "handoff/modules/"
flist = file.Find(path.."*.lua","LUA")

for _, filename in pairs(flist) do

    local typev = "SHARED"
    if filename:StartWith("cl_") then
        typev = "CLIENT"
    elseif filename:StartWith("sv_") then
        typev = "SERVER"
    end

    if SERVER and typev ~= "SERVER" then
        AddCSLuaFile( path.. filename )
    end

    if ( SERVER and typev ~= "CLIENT" ) or ( CLIENT and typev ~= "SERVER" ) then
        include( path..filename )
        --print("Initialized " .. filename .. " || " .. fileid .. "/" .. #flist )
    end

end
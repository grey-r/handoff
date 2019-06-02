if SERVER then
    AddCSLuaFile()
end
HandOff = HandOff or {}
HandOff.StatusTable = HandOff.StatusTable or {
    --["test"] = function() print("status ended") end
}

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

local path = "handoff/"
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
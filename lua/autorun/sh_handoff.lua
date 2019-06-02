if SERVER then
    AddCSLuaFile()
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
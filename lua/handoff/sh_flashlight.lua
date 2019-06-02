local drawtable = {
    ["model"] = "models/weapons/yurie_underhell/c_flashlight_pg.mdl",
    ["sequence"] = "flashlight_draw",
    ["draw"] = true,
    ["left"] = true,
    ["blendin"] = true,
    ["blendout"] = false,
    ["loop"] = false,
    ["follow_vm"] = true,
    ["active"] = true
}

local idletable = {
    ["model"] = "models/weapons/yurie_underhell/c_flashlight_pg.mdl",
    ["sequence"] = "flashlight_idle",
    ["draw"] = true,
    ["left"] = true,
    ["blendin"] = false,
    ["blendout"] = false,
    ["loop"] = true,
    ["follow_vm"] = true,
    ["active"] = true
}

local holstertable = {
    ["model"] = "models/weapons/yurie_underhell/c_flashlight_pg.mdl",
    ["sequence"] = "flashlight_holster",
    ["draw"] = true,
    ["left"] = true,
    ["blendin"] = false,
    ["blendout"] = true,
    ["loop"] = false,
    ["follow_vm"] = true,
    ["active"] = true
}

HandOff.StatusTable["flashlight_draw"] = function(ply)
    if not (IsFirstTimePredicted() or game.SinglePlayer()) then return end
    HandOff.Status="flashlight_idle"
    HandOff.StatusEnd=CurTime()+1
    HandOff.UpdateCTable(idletable)
end
HandOff.StatusTable["flashlight_idle"] = function(ply)
    if not (IsFirstTimePredicted() or game.SinglePlayer()) then return end
    HandOff.Status="flashlight_idle"
    HandOff.StatusEnd=CurTime() + 1
    if HandOff.CTable.sequence ~= idletable.sequence then
        HandOff.UpdateCTable(idletable)
    end
end

if CLIENT then
    function HandOff.FlashlightOn()
        HandOff.UpdateCTable(drawtable)
        HandOff.Status = "flashlight_draw"
        HandOff.StatusEnd = CurTime()+0.1
    end
end
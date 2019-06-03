local netstring="HANDOFFFLASHLIGHT"

local drawtime = 0.15
local holstertime = 0.1

local drawtable = {
    ["model"] = "models/weapons/yurie_underhell/c_flashlight_pg.mdl",
    ["sequence"] = "flashlight_draw",
    ["draw"] = true,
    ["left"] = true,
    ["blendin"] = true,
    ["blendout"] = false,
    ["loop"] = false,
    ["follow_vm"] = false,
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
    ["follow_vm"] = false,
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
    ["follow_vm"] = false,
    ["active"] = true
}

local flashlight = {
    ["material"] = Material("effects/flashlight001"),
    ["distance"] = 12 * 50, -- default 50 feet
    ["attachment"] = 1,
    ["brightness"] = 1,
    ["fov"] = 70

}

HandOff.StatusTable["flashlight_draw"] = function(ply)
    if not (IsFirstTimePredicted() or game.SinglePlayer()) then return end
    ply.HandOffStatus="flashlight_idle"
    ply.HandOffStatusEnd=CurTime()+0.1
    HandOff.UpdateCTable(ply,idletable)
end
HandOff.StatusTable["flashlight_idle"] = function(ply)
    if not (IsFirstTimePredicted() or game.SinglePlayer()) then return end
    ply.HandOffStatus="flashlight_idle"
    ply.HandOffStatusEnd=CurTime() + 0.1
    if HandOff.CTable.sequence ~= idletable.sequence then
        HandOff.UpdateCTable(ply,idletable)
    end
end

local ignoreStatus = {
    ["flashlight_draw"] = true,
    ["flashlight_holster"] = true
}
local flashStatus = {
    ["flashlight_draw"] = true,
    ["flashlight_idle"] = true,
    ["flashlight_holster"] = true
}
if SERVER then
    util.AddNetworkString(netstring)
    net.Receive(netstring,function(l,ply)
        local cha=false
        if ply.HandOffStatus=="idle" then
            ply.HandOffStatus="flashlight_draw"
            ply.HandOffStatusEnd=CurTime()+drawtime
            cha=true
        elseif ply.HandOffStatus=="flashlight_idle" then
            ply.HandOffStatus="flashlight_holster"
            ply.HandOffStatusEnd=CurTime()+holstertime
            cha=true
        end
        if cha then
            net.Start(netstring)
            net.WriteEntity(ply)
            net.WriteString(ply.HandOffStatus)
            net.Broadcast()
        end
    end)
end
if CLIENT then
    hook.Add("StartCommand", "HandOffFlashlight", function(ply,cmd)
        if cmd:GetImpulse() == 100 then
            cmd:SetImpulse( 0 )
            net.Start(netstring)
            net.SendToServer()
        end
    end)
    net.Receive(netstring,function()
        local ply = net.ReadEntity()
        local s = net.ReadString()
        local active = (s=="flashlight_draw")
        if active then
            ply.HandOffStatus="flashlight_draw"
            ply.HandOffStatusEnd = CurTime()+drawtime
            if ply==LocalPlayer() then
                HandOff.UpdateCTable(ply,drawtable)
            end
        else
            ply.HandOffStatus="flashlight_holster"
            ply.HandOffStatusEnd = CurTime()+holstertime
            if ply==LocalPlayer() then
                HandOff.UpdateCTable(ply,holstertable)
            end
        end
    end)
    local function DrawFlashlight(ply)
        if flashStatus[ply.HandOffStatus] then
            local angpos
            local islocal = (ply==LocalPlayer()) and not ply:ShouldDrawLocalPlayer()
            if islocal and IsValid(HandOff.CMod) then
                HandOff.CMod:SetupBones()
                angpos = HandOff.CMod:GetAttachment(flashlight.attachment)
                if not angpos then return end
                angpos.Pos = angpos.Pos - angpos.Ang:Forward()
            else
                local p,a = ply:GetBonePosition(ply:LookupBone("ValveBiped.Bip01_R_Hand") or 1)
                angpos = {
                    ["Pos"] = p+a:Forward()*8,
                    ["Ang"] = a
                }
            end
            if angpos then
                if not IsValid(ply.HandOffFlashlightTex) then
                    local lamp = ProjectedTexture()
                    ply.HandOffFlashlightTex = lamp
                    lamp:SetTexture(flashlight.material:GetString("$basetexture"))
                    lamp:SetFarZ(flashlight.distance) -- How far the light should shine
                    lamp:SetFOV(flashlight.fov)
                    lamp:SetPos(angpos.Pos)
                    lamp:SetAngles(angpos.Ang)
                    lamp:SetBrightness(flashlight.brightness * (0.9  + 0.1 * math.max(math.sin(CurTime() * 120), math.cos(CurTime() * 40))))
                    lamp:SetNearZ(1)
                    lamp:SetColor(color_white)
                    lamp:SetEnableShadows(true)
                    lamp:Update()
                else
                    local lamp = ply.HandOffFlashlightTex
                    lamp:SetPos(angpos.Pos)
                    lamp:SetAngles(angpos.Ang)
                    lamp:SetBrightness(flashlight.brightness * (0.9  + 0.1 * math.max(math.sin(CurTime() * 120), math.cos(CurTime() * 40))))
                    lamp:Update()
                end
            end
        elseif IsValid(ply.HandOffFlashlightTex) then
            ply.HandOffFlashlightTex:Remove()
            ply.HandOffFlashlightTex = nil
        end
    end
    hook.Add("PostPlayerDraw","HandOffFlashlight",DrawFlashlight)
    hook.Add("PostDrawViewModel","HandOffFlashlight",function() end)
    hook.Add("PostDrawPlayerHands","HandOffFlashlight",function()
        DrawFlashlight(LocalPlayer())
    end)
end
HandOff = HandOff or {}
HandOff.VMod=nil
HandOff.CMod=nil
HandOff.ProxyModel = "models/weapons/v_hands.mdl"

local function LerpAngleFast(t,a1,a2)
	a1.p = math.ApproachAngle(a1.p, a2.p, math.AngleDifference(a2.p, a1.p) * t)
	a1.y = math.ApproachAngle(a1.y, a2.y, math.AngleDifference(a2.y, a1.y) * t)
    a1.r = math.ApproachAngle(a1.r, a2.r, math.AngleDifference(a2.r, a1.r) * t)
end

local rotAng = Angle(90,0,0)

function HandOff:CModCallback(boneCount)
    for i=0, boneCount-1 do
        self.BoneCache[i] = self:GetBoneMatrix(i)
    end
end

function HandOff:VModCallback(boneCount)
    if not IsValid(HandOff.CMod) then return end
    if not HandOff.VMod.HandOffBoneLUT then return end
    if not HandOff.VMod.HandOffParLUT then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local par = self:GetParent()
    local PIV = IsValid(par) and par.BoneCache
    if PIV then
        par:SetupBones()
    end

    local bin,bout,fac
    bin = ply.CTable.blendin
    bout = ply.CTable.blendout
    fac = ply.CTable.active and 1 or 0
    if bin then
        if not isnumber(bin) then
            bin = 0.2 / HandOff.CMod:SequenceDuration() --0.2 seconds blend
        end
        fac=fac*(1-math.Clamp(bin-HandOff.CMod:GetCycle(),0,bin)/bin)
    end
    if bout then
        if not isnumber(bout) then
            bout = 0.2 / HandOff.CMod:SequenceDuration() --0.2 seconds blend
        end
        fac=fac*(1-math.Clamp(bout-(1-HandOff.CMod:GetCycle()),0,bout)/bout)
    end

    for i=0, boneCount-1 do
        local mymat = self:GetBoneMatrix(i)
        if mymat then
            if self.HandOffParLUT[i] and PIV then
                local m = par.BoneCache[self.HandOffParLUT[i]]
                if m then
                    mymat:SetTranslation(m:GetTranslation())
                    mymat:SetAngles(m:GetAngles())
                end
            end
            if self.HandOffBoneLUT[i] then
                local m = HandOff.CMod.BoneCache[self.HandOffBoneLUT[i]]
                if m then
                    if fac==1 then
                        mymat:SetTranslation(m:GetTranslation())
                        mymat:SetAngles(m:GetAngles())
                    else
                        mymat:SetTranslation(LerpVector(fac,mymat:GetTranslation(),m:GetTranslation()))
                        local a1 = mymat:GetAngles()
                        local a2 = m:GetAngles()
                        LerpAngleFast(fac,a1,a2)
                        mymat:SetAngles(a1)
                    end
                end
            end
            self:SetBoneMatrix(i,mymat)
        end
    end
end

function HandOff.UpdateVMod()
    local hands=LocalPlayer():GetHands()
    if not IsValid(HandOff.VMod) then
        HandOff.VMod=ClientsideModel(HandOff.ProxyModel,RENDERGROUP_VIEWMODEL)
        HandOff.VMod:SetNoDraw(true)
        HandOff.VMod:DrawShadow(false)
    end
    if IsValid(hands) then
        local handpar = hands:GetParent()
        if IsValid(handpar) then
            HandOff.VMod:SetParent(handpar)
        else
            HandOff.VMod:SetParent(LocalPlayer():GetViewModel())
        end
    end
    local par = HandOff.VMod:GetParent()
    if IsValid(par) then
        if par.HOBBCB then
            par:RemoveCallback("BuildBonePositions",par.HOBBCB)
            par.HOBBCB = nil
        end
        par.BoneCache = {}
        par.HOBBCB = par:AddCallback("BuildBonePositions", HandOff.CModCallback)
    end
    HandOff.VMod.HandOffBoneLUT = {}
    HandOff.VMod.HandOffParLUT = {}
    if HandOff.VMod.HOBBCB then
        HandOff.VMod:RemoveCallback("BuildBonePositions",HandOff.VMod.HOBBCB)
        HandOff.VMod.HOBBCB = nil
    end
    HandOff.VMod.HOBBCB = HandOff.VMod:AddCallback("BuildBonePositions", HandOff.VModCallback)
    HandOff.UpdateLUT()
    return HandOff.VMod
end

function HandOff.UpdateCMod()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if IsValid(HandOff.CMod) then
        HandOff.CMod:Remove()
    end
    if not ply.CTable.model then return end
    if ply.CTable.model=="" then return end
    HandOff.CMod=ClientsideModel(ply.CTable.model,RENDERGROUP_VIEWMODEL)
    HandOff.CMod.HOBBCB = HandOff.CMod:AddCallback("BuildBonePositions", HandOff.CModCallback)
    HandOff.CMod:SetNoDraw(true)
    HandOff.CMod:DrawShadow(ply.CTable.draw)
    if IsValid(HandOff.VMod) and ply.CTable.follow_vm then
        HandOff.CMod:SetParent(HandOff.VMod)
        HandOff.CMod:SetLocalPos(vector_origin)
        HandOff.CMod:SetLocalAngles(angle_zero)
    end
    HandOff.CMod.AutomaticFrameAdvance=false
    HandOff.CMod.BoneCache={}
    HandOff.CMod:ResetSequence(1)
    HandOff.CMod:SetCycle(0.99)
    HandOff.UpdateLUT()
    return HandOff.CMod
end

function HandOff.UpdateLUT()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not IsValid(HandOff.CMod) then return end
    if not IsValid(HandOff.VMod) then return end
    table.Empty(HandOff.VMod.HandOffBoneLUT)
    table.Empty(HandOff.VMod.HandOffParLUT)
    local par = HandOff.VMod:GetParent()
    if not IsValid(par) then return end
    local bc = HandOff.VMod:GetBoneCount()
    for i=0, bc-1 do
        local bn = HandOff.VMod:GetBoneName(i)
        if not ( ply.CTable.left and not string.find(string.lower(bn),"l_") ) then
            local bid = HandOff.CMod:LookupBone(bn)
            HandOff.VMod.HandOffBoneLUT[i]=bid
        end
        if IsValid(par) then
            local bid = par:LookupBone(bn)
            HandOff.VMod.HandOffParLUT[i]=bid
        end
    end
    return HandOff.VMod.HandOffBoneLUT
end

function HandOff.PlaySequence(seq)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not IsValid(HandOff.CMod) then return end
    local ogseq=seq
    if type(seq)=="string" then
        seq=HandOff.CMod:LookupSequence(seq)
    end
    if seq then
        HandOff.CMod:ResetSequence(seq)
        ply.CTable.sequence = ogseq
        ply.CTable.active = true
    end
    HandOff.CMod:SetCycle(0)
end

local oldvm=""
local oldpar

local HANDOFF_OVR = false
hook.Add("PreDrawPlayerHands","zzz_handoff",function(hands,vm,ply,wep,...)
    if not ply.CTable then
        ply.CTable=table.Copy(HandOff.CTable)
    end
    if not IsValid(hands) then return end
    if not HANDOFF_OVR then
        HANDOFF_OVR = true
        if IsValid(wep) then
            hook.Call("PreDrawPlayerHands",GM or GAMEMODE,hands,vm,ply,wep,...)
        end
        HANDOFF_OVR = false
    end
    if not IsValid(HandOff.VMod) then
        HandOff.UpdateVMod()
    else
        if IsValid(vm) and ( vm:GetModel()~=oldvm or vm:GetParent()~=oldpar ) then
            oldvm=vm:GetModel()
            oldpar=vm:GetParent()
            HandOff.UpdateVMod()
        end
        HandOff.VMod:SetLocalPos(vector_origin)
        HandOff.VMod:SetLocalAngles(angle_zero)
        if hands:GetParent()~=HandOff.VMod then
            HandOff.VMod:SetParent(hands:GetParent())
            HandOff.UpdateVMod()
            hands:SetParent(HandOff.VMod)
        end
    end
    if not IsValid(HandOff.CMod) then
        HandOff.UpdateCMod()
    else
        if ply.CTable.follow_vm then
            HandOff.CMod:SetParent(HandOff.VMod)
            HandOff.CMod:SetLocalPos(vector_origin)
            HandOff.CMod:SetLocalAngles(angle_zero)
        else
            HandOff.CMod:SetPos(EyePos())
            HandOff.CMod:SetAngles(EyeAngles())
        end
        HandOff.CMod:FrameAdvance(FrameTime())
        if ply.CTable.active and HandOff.CMod:GetCycle() > 0.99 then
            if ply.CTable.loop then
                HandOff.CMod:SetCycle(0)
            else
                ply.CTable.active = false
            end
        end
        HandOff.CMod:SetupBones()
        HandOff.VMod:SetupBones()
        if ply.CTable.draw and ply.CTable.active then
            HandOff.CMod:DrawModel()
        end
    end
    return false
end)
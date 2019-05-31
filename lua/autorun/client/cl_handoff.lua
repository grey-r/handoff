HandOff = HandOff or {}
HandOff.VMod=nil
HandOff.CMod=nil
HandOff.CTable = {
    ["model"] = "models/weapons/c_arms_animations.mdl",
    ["sequence"] = "fists_left",
    ["draw"] = false,
    ["left"] = true,
    ["blendin"] = true,
    ["blendout"] = true
}

local rotAng = Angle(90,0,0)

function HandOff:CModCallback(boneCount)
    for i=0, boneCount-1 do
        self.BoneCache[i] = self:GetBoneMatrix(i)
    end
end
function HandOff:VModCallback(boneCount)
    if not IsValid(HandOff.CMod) then return end
    if not HandOff.VMod.HandOffBoneLUT then return end
    HandOff.CMod:SetupBones()
    local bin,bout,fac
    bin = HandOff.CTable.blendin
    bout = HandOff.CTable.blendout
    fac = 1
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
    for k,v in pairs(HandOff.VMod.HandOffBoneLUT) do
        local m = HandOff.CMod.BoneCache[v]
        local mymat=self:GetBoneMatrix(k)
        if m and mymat then
            if fac==1 then
                mymat:SetTranslation(m:GetTranslation())
                mymat:SetAngles(m:GetAngles())
                self:SetBoneMatrix(k,mymat)
            else
                mymat:SetTranslation(LerpVector(fac,mymat:GetTranslation(),m:GetTranslation()))
                local a1 = mymat:GetAngles()
                a1:Normalize()
                local a2 = m:GetAngles()
                a2:Normalize()
                mymat:SetAngles(LerpAngle(fac,a1,a2))
                self:SetBoneMatrix(k,mymat)
            end
        end
    end
end

function HandOff.UpdateVMod()
    if not IsValid(LocalPlayer()) then HandOff.VMod = nil return end
    if not IsValid(LocalPlayer():GetHands()) then HandOff.VMod = nil return end
    HandOff.VMod=LocalPlayer():GetHands()
    local par = HandOff.VMod:GetParent()
    while IsValid(par) and par:LookupBone("ValveBiped.Bip01_L_Hand") and ( HandOff.VMod:IsEffectActive(EF_BONEMERGE) or HandOff.VMod:IsEffectActive(EF_BONEMERGE_FASTCULL) ) do
        HandOff.VMod = par
        par = HandOff.VMod:GetParent()
    end
    if HandOff.VMod.CB then
        HandOff.VMod:RemoveCallback("BuildBonePositions", HandOff.VMod.CB)
        HandOff.VMod.CB = nil
    end
    HandOff.VMod.CB = HandOff.VMod:AddCallback("BuildBonePositions", HandOff.VModCallback)
    HandOff.VMod.HandOffBoneLUT = {}
    HandOff.UpdateLUT()
    return HandOff.VMod
end

function HandOff.UpdateCMod()
    if IsValid(HandOff.CMod) then
        HandOff.CMod:Remove()
    end
    if not HandOff.CTable.model then return end
    if HandOff.CTable.model=="" then return end
    HandOff.CMod=ClientsideModel(HandOff.CTable.model,RENDERGROUP_VIEWMODEL)
    HandOff.CMod.CB = HandOff.CMod:AddCallback("BuildBonePositions", HandOff.CModCallback)
    HandOff.CMod:SetNoDraw(not HandOff.CTable.draw)
    HandOff.CMod:DrawShadow(HandOff.CTable.draw)
    if IsValid(HandOff.VMod) then
        HandOff.CMod:SetParent(HandOff.VMod)
        HandOff.CMod:SetLocalPos(vector_origin)
        HandOff.CMod:SetLocalAngles(angle_zero)
    end
    HandOff.CMod.AutomaticFrameAdvance=false
    HandOff.CMod.BoneCache={}
    local s = HandOff.CMod:LookupSequence(HandOff.CTable.sequence)
    if s and s~=-1 then
        HandOff.CMod:ResetSequence(s)
    end
    HandOff.UpdateLUT()
    return HandOff.CMod
end

function HandOff.UpdateLUT()
    if not IsValid(HandOff.CMod) then return end
    if not IsValid(HandOff.VMod) then return end
    table.Empty(HandOff.VMod.HandOffBoneLUT)
    local bnm = false
    if HandOff.VMod:IsEffectActive(EF_BONEMERGE) or HandOff.VMod:IsEffectActive(EF_BONEMERGE_FASTCULL) then bnm=true end
    local par = HandOff.VMod:GetParent()
    if bnm and not IsValid(par) then
        bnm = false
    end
    if bnm then print(par) end
    local bc = HandOff.VMod:GetBoneCount()
    for i=0, bc-1 do
        local bn = HandOff.VMod:GetBoneName(i)
        if (not HandOff.VMod:BoneHasFlag(i,BONE_PHYSICALLY_SIMULATED)) and (not HandOff.VMod:BoneHasFlag(i,BONE_PHYSICS_PROCEDURAL))
        and (not HandOff.VMod:BoneHasFlag(i,BONE_ALWAYS_PROCEDURAL)) and not ( HandOff.CTable.left and not string.find(string.lower(bn),"l_") ) then
            local bid = HandOff.CMod:LookupBone(bn)
            if not ( bnm and par:LookupBone(bn) and par:BoneHasFlag(par:LookupBone(bn), BONE_USED_BY_BONE_MERGE)) then
                HandOff.VMod.HandOffBoneLUT[i]=bid
            end
        end
    end
    return HandOff.VMod.HandOffBoneLUT
end

function HandOff.PlaySequence(seq)
    if not IsValid(HandOff.CMod) then return end
    if type(seq)=="string" then
        seq=HandOff.CMod:LookupSequence(seq)
    end
    if seq then
        HandOff.CMod:ResetSequence(seq)
    end
    HandOff.CMod:SetCycle(0)
end

hook.Add("OnViewModelChanged","handoff",function(vm,old,new)
    HandOff.UpdateVMod()
end)

local oldvm=""
local oldpar
hook.Add("PreRender","handoff",function()
    if not IsValid(HandOff.VMod) then
        HandOff.UpdateVMod()
    else
        local vm=LocalPlayer():GetViewModel()
        if IsValid(vm) and ( vm:GetModel()~=oldvm or vm:GetParent()~=oldpar ) then
            oldvm=vm:GetModel()
            oldpar=vm:GetParent()
            HandOff.UpdateVMod()
        end
    end
    if not IsValid(HandOff.CMod) then
        HandOff.UpdateCMod()
    else
        HandOff.CMod:FrameAdvance(FrameTime())
    end
end)
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
    if not HandOff.VMod.HandOffParLUT then return end
    local par = self:GetParent()
    local PIV = IsValid(par) and par.BoneCache
    if PIV then
        par:SetupBones()
    end
    for i=0, boneCount-1 do
        local mymat = self:GetBoneMatrix(i)
        if self.HandOffBoneLUT[i] then
            local m = HandOff.CMod.BoneCache[self.HandOffBoneLUT[i]]
            if m then
                mymat:SetTranslation(m:GetTranslation())
                mymat:SetAngles(m:GetAngles())
                self:SetBoneMatrix(i,mymat)
            end
        elseif self.HandOffParLUT[i] and PIV then
            local m = par.BoneCache[self.HandOffParLUT[i]]
            if m then
                mymat:SetTranslation(m:GetTranslation())
                mymat:SetAngles(m:GetAngles())
                self:SetBoneMatrix(i,mymat)
            end
        else
            local parMat = self:GetBoneMatrix(self:GetBoneParent(i))
            if parMat then
                if self.HOLocalBones and self.HOLocalBones[i] then
                    local t = self.HOLocalBones[i] 
                    local wPos, wAng = LocalToWorld( t.pos, t.ang, parMat:GetTranslation(), parMat:GetAngles() )
                    mymat:SetTranslation(wPos)
                    mymat:SetAngles(wAng)
                    self:SetBoneMatrix(i,mymat)
                else
                    self:SetBoneMatrix(i,parMat)
                end
            end
        end
    end
    --[[
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
    ]]--
end

function HandOff:CacheLocalBones()
    HandOff.VMod:SetModel(HandOff.VMod:GetModel())
    HandOff.VMod:ResetSequence(0)
    HandOff.VMod:SetCycle(0)
    HandOff.VMod:SetupBones()
    self.HOLocalBones = {}
    local bc = self:GetBoneCount()
    for i=0, bc-1 do
        local par = self:GetBoneParent(i)
        if par and par>=0 then
            local parMat = self:GetBoneMatrix(par)
            local boneMat = self:GetBoneMatrix(i)
            if parMat and boneMat then
                local parPos = parMat:GetTranslation()
                local bonePos = boneMat:GetTranslation()
                local parAng = parMat:GetAngles()
                local boneAng = boneMat:GetAngles()
                local lPos, lAng = WorldToLocal( bonePos, boneAng, parPos, parAng )
                self.HOLocalBones[i] = {
                    ["pos"] = lPos,
                    ["ang"] = lAng
                }
            end
        end
    end
end

function HandOff.UpdateVMod()
    if not IsValid(LocalPlayer()) then HandOff.VMod = nil return end
    if not IsValid(LocalPlayer():GetHands()) then HandOff.VMod = nil return end
    HandOff.VMod=LocalPlayer():GetHands()
    if not IsValid(HandOff.VMod) then return end
    if HandOff.VMod:IsEffectActive(EF_BONEMERGE_FASTCULL) then
        HandOff.VMod:RemoveEffects(EF_BONEMERGE_FASTCULL)
    end
    if HandOff.VMod:IsEffectActive(EF_BONEMERGE) then
        HandOff.VMod:RemoveEffects(EF_BONEMERGE)
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
    HandOff.CacheLocalBones(HandOff.VMod)
    HandOff.VMod.HOBBCB = HandOff.VMod:AddCallback("BuildBonePositions", HandOff.VModCallback)
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
    HandOff.CMod.HOBBCB = HandOff.CMod:AddCallback("BuildBonePositions", HandOff.CModCallback)
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
    table.Empty(HandOff.VMod.HandOffParLUT)
    local par = HandOff.VMod:GetParent()
    if not IsValid(par) then return end
    local bc = HandOff.VMod:GetBoneCount()
    for i=0, bc-1 do
        local bn = HandOff.VMod:GetBoneName(i)
        --if (not string.find(string.lower(bn),"ulna")) and (not string.find(string.lower(bn),"wrist")) then
            if not ( HandOff.CTable.left and not string.find(string.lower(bn),"l_") ) then
                local bid = HandOff.CMod:LookupBone(bn)
                HandOff.VMod.HandOffBoneLUT[i]=bid
            end
            if IsValid(par) then
                local bid = par:LookupBone(bn)
                HandOff.VMod.HandOffParLUT[i]=bid
            end
        --end
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

local oldvm=""
local oldpar
hook.Add("PreDrawPlayerHands","handoff",function()
    if not IsValid(HandOff.VMod) then
        HandOff.UpdateVMod()
    else
        local vm=LocalPlayer():GetViewModel()
        if IsValid(vm) and ( vm:GetModel()~=oldvm or vm:GetParent()~=oldpar ) then
            oldvm=vm:GetModel()
            oldpar=vm:GetParent()
            timer.Simple(0, HandOff.UpdateVMod)
        end
        HandOff.VMod:SetLocalPos(vector_origin)
        HandOff.VMod:SetLocalAngles(angle_zero)
    end
    if not IsValid(HandOff.CMod) then
        HandOff.UpdateCMod()
    else
        HandOff.CMod:FrameAdvance(FrameTime())
        HandOff.CMod:SetupBones()
    end
end)
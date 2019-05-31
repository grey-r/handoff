HandOff = HandOff or {}
HandOff.VMod=nil
HandOff.CMod=nil
HandOff.CTable = {
    ["model"] = "models/weapons/c_arms_animations.mdl",
    ["sequence"] = "fists_left",
    ["draw"] = false,
    ["left"] = true
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
    for k,v in pairs(HandOff.VMod.HandOffBoneLUT) do
        local m = HandOff.CMod.BoneCache[v]
        if m then
            self:SetBoneMatrix(k,m)
        end
    end
end

function HandOff.UpdateVMod()
    if not IsValid(LocalPlayer()) then HandOff.VMod = nil return end
    if not IsValid(LocalPlayer():GetHands()) then HandOff.VMod = nil return end
    HandOff.VMod=LocalPlayer():GetHands()
    local par = HandOff.VMod:GetParent()
    while IsValid(par) and par:LookupBone("ValveBiped.Bip01_L_UpperArm") and HandOff.VMod:IsEffectActive(EF_BONEMERGE) do
        HandOff.VMod = par
        par = HandOff.VMod:GetParent()
    end
    HandOff.VMod.LUppArmBone = HandOff.VMod:LookupBone("ValveBiped.Bip01_L_UpperArm")
    if HandOff.VMod.CB then
        HandOff.VMod:RemoveCallback("BuildBonePositions", HandOff.VMod.CB)
        HandOff.VMod.CB = nil
    end
    HandOff.VMod.CB = HandOff.VMod:AddCallback("BuildBonePositions", HandOff.VModCallback)
    HandOff.VMod.HandOffBoneLUT = HandOff.VMod.HandOffBoneLUT or {}
    HandOff.UpdateLUT()
    return HandOff.VMod
end

function HandOff.UpdateCMod()
    if IsValid(HandOff.CMod) then
        HandOff.CMod:Remove()
    end
    HandOff.CMod=ClientsideModel(HandOff.CTable.model)
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
    local bc = HandOff.VMod:GetBoneCount()
    for i=0, bc-1 do
        local bn = HandOff.VMod:GetBoneName(i)
        if not ( HandOff.CTable.left and not string.find(string.lower(bn),"l_") ) then
            local bid = HandOff.CMod:LookupBone(bn)
            HandOff.VMod.HandOffBoneLUT[i]=bid
        end
    end
end

hook.Add("OnViewModelChanged","handoff",function(vm,old,new)
    HandOff.UpdateVMod()
end)

local oldvm=""
hook.Add("PreRender","handoff",function()
    if not IsValid(HandOff.VMod) then
        HandOff.UpdateVMod()
    else
        local vm=LocalPlayer():GetViewModel()
        if IsValid(vm) and vm:GetModel()~=oldvm then
            oldvm=vm:GetModel()
            HandOff.UpdateVMod()
        end
    end
    if not IsValid(HandOff.CMod) then
        HandOff.UpdateCMod()
    else
        --HandOff.CMod:SetPos(EyePos())
        --HandOff.CMod:SetAngles(EyeAngles())
        HandOff.CMod:FrameAdvance(FrameTime())
        if HandOff.CMod:GetCycle()>0.9 then
            HandOff.CMod:SetCycle(0)
        end
    end
end)
HandOff = HandOff or {}
HandOff.VMod=nil

local rotAng = Angle(90,0,0)

function HandOff:VModCallback(boneCount)
    local rmat = self:GetBoneMatrix(0)
    rmat:Scale(vector_origin)
    self:SetBoneMatrix(0,rmat)
    for i=0, boneCount-1 do
        local mat = self:GetBoneMatrix(i)
        if mat then
            mat:Scale(vector_origin)
            mat:SetTranslation(rmat:GetTranslation())
            self:SetBoneMatrix(i,mat)
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
    return HandOff.VMod
end

hook.Add("OnViewModelChanged","handoff",function(vm,old,new)
    HandOff.UpdateVMod()
end)
hook.Add("PreRender","handoff",function()
    if not IsValid(HandOff.VMod) then
        HandOff.UpdateVMod()
    end

end)
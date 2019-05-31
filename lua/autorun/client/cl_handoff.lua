HandOff = HandOff or {}
HandOff.EntMod=nil

hook.Add("OnViewModelChanged","handoff",function(vm,old,new)
    HandOff.EntMod=nil
end)
hook.Add("PreRender","handoff",function()
    if not IsValid(HandOff.EntMod) then
        if not IsValid(LocalPlayer()) then return end
        if not IsValid(LocalPlayer():GetHands()) then return end
        HandOff.EntMod=LocalPlayer():GetHands()
        while IsValid(HandOff.EntMod:GetParent()) and HandOff.EntMod:IsEffectActive(EF_BONEMERGE) do
            HandOff.EntMod = HandOff.EntMod:GetParent()
        end
    end
end)
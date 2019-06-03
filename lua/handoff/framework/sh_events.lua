local sp = game.SinglePlayer()
local l_CT = CurTime

HandOff.Events = HandOff.Events or {}
HandOff.Events.StartTime = -1

local function EmitSoundSafe(snd)
	timer.Simple(0,function()
		if IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetViewModel()) and snd then LocalPlayer():GetViewModel():EmitSound(snd) end
	end)
end

if SERVER then
    util.AddNetworkString("HandOffSoundEvent")
else
    net.Receive("HandOffSoundEvent", function(length, ply)
        local ent = net.ReadEntity()
        local snd = net.ReadString()

        if IsValid(ent) and snd and snd ~= "" then
            ent:EmitSound(snd)
        end
    end)
end

function HandOff.ResetEvents(ply)
	if IsFirstTimePredicted() or sp then
		HandOff.Events.StartTime = l_CT()
		for _, v in pairs(ply.CTable.events) do
			v.called = false
		end
	end
end

local seq_old, mdl_old, act_old
function HandOff.ProcessEvents(ply)
    if not IsValid(ply) then return end
    local vm = ply:GetViewModel()
    if not IsValid(vm) then return end
	if HandOff.Events.StartTime < 0 then return end
	local evtbl = ply.CTable.events

    if not ply.CTable.active then return end
	if not evtbl then return end
    if #evtbl==0 then return end

    for _, v in pairs(evtbl) do
		if v.called or l_CT() < HandOff.Events.StartTime + v.time then continue end
		v.called = true

		if v.client == nil then
			v.client = true
		end

		if v.type == "lua" then
			if v.server == nil then
				v.server = true
			end

			if (v.client and CLIENT and (not v.client_predictedonly or ply == LocalPlayer())) or (v.server and SERVER) and v.value then
				v.value(ply, vm)
			end
        elseif v.type == "snd" or v.type == "sound" then
			if v.server == nil then
				v.server = false
			end

			if SERVER then
				if v.client then
					net.Start("HandOffSoundEvent")
					net.WriteEntity(vm)
                    net.WriteString(v.value or "")

                    if sp then
						net.Broadcast()
					else
						net.SendOmit(ply)
					end
				elseif v.server and v.value and v.value ~= "" then
					vm:EmitSound(v.value)
				end
			elseif v.client and ply == LocalPlayer() and ( not sp ) and v.value and v.value ~= "" then
				if v.time <= 0.01 then
					EmitSoundSafe(v.value)
				else
					vm:EmitSound(v.value)
				end
			end
		end
	end
end

hook.Add("PlayerTick","HandOffEvents",HandOff.ProcessEvents)
if game.SinglePlayer() and CLIENT then
    hook.Add("Think","HandOffEvents",function()
        local ply = LocalPlayer()
        if IsValid(ply) then
            HandOff.ProcessEvents(ply)
        end
    end)
end
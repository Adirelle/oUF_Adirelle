--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

oUF:Factory(function()

	local frames = {}

	local function Spawn(style, unit, ...)
		oUF:SetActiveStyle(style)
		local realUnit = unit:lower()
		local frame = oUF:Spawn(realUnit, "oUF_Adirelle_"..unit)
		frames[frame] = unit
		if select('#', ...) > 0 then
			return frame, Spawn(style, ...)
		else
			return frame
		end
	end

	local player, pet = Spawn("Adirelle_Single", "Player", "Pet")
	local target, focus = Spawn("Adirelle_Single_Right", "Target", "Focus")
	local targettarget = Spawn("Adirelle_Single_Health", "TargetTarget")

	player:SetPoint('BOTTOMRIGHT', UIParent, "BOTTOM", -250, 180)
	pet:SetPoint('BOTTOM', player, "TOP", 0, 15)
	pet:SetHeight(40)
	target:SetPoint('BOTTOMLEFT', UIParent, "BOTTOM", 250, 180)
	targettarget:SetPoint('BOTTOM', target, "TOP", 0, 15)
	focus:SetPoint('BOTTOM', targettarget, "TOP", 0, 15)

	for frame, unit in next, frames do
		RegisterMovable(frame, unit, unit.." frame")
	end
	frames = nil
end)


--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

oUF:Factory(function()
	oUF:SetActiveStyle("Adirelle_Single_Right")
	local anchor, gap = oUF_Adirelle_Focus, 30
	for index = 1, MAX_BOSS_FRAMES do
		local unit = "Boss"..index
		local frame = oUF:Spawn(unit:lower(), "oUF_Adirelle_"..unit)
		frame:SetPoint("BOTTOM", anchor, "TOP", 0, gap)
		anchor, gap = frame, 15
		RegisterMovable(frame, unit, unit.." frame")
	end
end)

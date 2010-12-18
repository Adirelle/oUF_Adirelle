--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
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

	local boss1, boss2, boss3, boss4 = Spawn("Adirelle_Single_Right", "Boss1", "Boss2", "Boss3", "Boss4")

	boss1:SetPoint("BOTTOM", oUF_Adirelle_Focus, "TOP", 0, -30)
	boss2:SetPoint("BOTTOM", boss1, "TOP", 0, -15)
	boss3:SetPoint("BOTTOM", boss2, "TOP", 0, -15)
	boss4:SetPoint("BOTTOM", boss3, "TOP", 0, -15)

	for frame, unit in next, frames do
		RegisterMovable(frame, unit, unit.." frame")
	end
	frames = nil
end)


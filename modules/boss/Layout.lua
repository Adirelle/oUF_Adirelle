--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF_Adirelle = oUF_Adirelle
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle namespace")

oUF_Adirelle.oUF:Factory(function()

	local anchor = oUF_Adirelle.CreatePseudoHeader("oUF_Adirelle_Bosses", "bosses", "Boss frames", 190, 47*4+15*3, "BOTTOM", oUF_Adirelle_Focus, "TOP", 0, 30)

	function anchor:ShouldEnable()
		local _, iType = IsInInstance()
		return iType == "raid" or iType == "party"
	end
	anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
	anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')

	oUF:SetActiveStyle("Adirelle_Single_Right")
	for index = 1, MAX_BOSS_FRAMES do
		local frame = oUF:Spawn("boss"..index, "oUF_Adirelle_Boss"..index)
		frame:SetParent(anchor)
		frame:SetPoint("BOTTOM", anchor, "BOTTOM", 0, (47+15)*(index-1))
		anchor:AddFrame(frame)
	end

end)

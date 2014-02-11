--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

oUF_Adirelle.oUF:Factory(function()
	--<GLOBALS
	local _G = _G
	local IsInInstance = _G.IsInInstance
	--GLOBALS>

	local offset = 250+max(0, GetScreenWidth()-1280)/5

	local anchor = oUF_Adirelle.CreatePseudoHeader("oUF_Adirelle_Bosses", "boss", "Boss frames", 190, 47*4+15*3, 'BOTTOMLEFT', _G.UIParent, 'BOTTOM', offset, 385)

	function anchor:ShouldEnable()
		local _, iType = IsInInstance()
		return iType == "raid" or iType == "party"
	end
	anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
	anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')

	oUF:SetActiveStyle("Adirelle_Single_Right")
	for index = 1, _G.MAX_BOSS_FRAMES do
		local frame = oUF:Spawn("boss"..index, "oUF_Adirelle_Boss"..index)
		frame:SetParent(anchor)
		frame:SetPoint("BOTTOM", anchor, "BOTTOM", 0, (47+15)*(index-1))
		anchor:AddFrame(frame)
	end

end)

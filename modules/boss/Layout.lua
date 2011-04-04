--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF_Adirelle = oUF_Adirelle
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle namespace")

oUF_Adirelle.oUF:Factory(function()

	local anchor = CreateFrame("Frame", "oUF_Adirelle_Bosses", UIParent, "SecureFrameTemplate")
	anchor.Debug = oUF_Adirelle.Debug
	anchor:SetSize(190, 47*4+15*3)
	anchor:SetPoint("BOTTOM", oUF_Adirelle_Focus, "TOP", 0, 30)
	
	oUF:SetActiveStyle("Adirelle_Single_Right")
	local frames = {}
	for index = 1, MAX_BOSS_FRAMES do
		local frame = oUF:Spawn("boss"..index, "oUF_Adirelle_Boss"..index)
		frame:SetParent(anchor)
		frame:SetPoint("BOTTOM", anchor, "BOTTOM", 0, (47+15)*(index-1))
		frames[index] = frame
	end
	
	function anchor:Enable()
		self:Debug('Enable')
		self:Show()
		for i, frame in ipairs(frames) do
			frame:Enable()
		end
	end
	
	function anchor:Disable()
		self:Debug('Disable')
		for i, frame in ipairs(frames) do
			frame:Disable()
		end
		self:Hide()
	end
	
	function anchor:Update()
		local _, iType = IsInInstance()
		if self:GetEnabledSetting() and (iType == "raid" or iType == "party ") then
			self:Enable()
		else
			self:Disable()
		end
	end
	
	oUF_Adirelle.RegisterMovable(anchor, "bosses", "Boss frames")

	anchor:SetScript('OnEvent', anchor.Update)
	anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
	anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	anchor:Update()	
end)

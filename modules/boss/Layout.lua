--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

oUF_Adirelle.oUF:Factory(function()
	local oUF, RegisterMovable = oUF_Adirelle.oUF, oUF_Adirelle.RegisterMovable

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
		self:Show()
		for i, frame in ipairs(frames) do
			frame:Enable()
		end
	end
	function anchor:Disable()
		for i, frame in ipairs(frames) do
			frame:Disable()
		end
		self:Hide()
	end
	RegisterMovable(anchor, "bosses", "Boss frames")
end)

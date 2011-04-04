--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF_Adirelle = oUF_Adirelle
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in "..parent.." namespace")

oUF:Factory(function()
	local frames = {}
	
	local anchor = CreateFrame("Frame", "oUF_Adirelle_Arena", UIParent, "SecureFrameTemplate")
	anchor.Debug = oUF_Adirelle.Debug
	anchor:SetSize(190, 5*(47+40)-15)
	anchor:SetPoint("BOTTOM", oUF_Adirelle_Focus, "TOP", 0, 30)
	
	function anchor:Enable()
		self:Show()
		for i, frame in pairs(frames) do
			frame:Enable()
		end
	end

	function anchor:Disable()
		for i, frame in pairs(frames) do
			frame:Disable()
		end
		self:Hide()
	end
	
	function anchor:Update()
		if self:GetEnabledSetting() and select(2, IsInInstance()) == "arena" then
			self:Enable()
		else
			self:Disable()
		end
	end

	local function ArenaUnit_Enable(self)
		RegisterUnitWatch(self, true)
	end

	local function ArenaUnit_Disable(self)
		UnregisterUnitWatch(self)
		self:SetAttribute('state-unitexists', false)
		self:Hide()
	end
	
	local ArenaUnit_OnAttributeChanged = [=[
		if name == "state-unitexists" then
			if value then
				if not self:IsShown() then
					self:Show()
				else
					control:CallMethod("UpdateAllElements", "OnUnitExists")
				end
			end
		end
	]=]

	for index = 1, 5 do
		oUF:SetActiveStyle("Adirelle_Single_Right")
		local frame = oUF:Spawn("arena"..index, "oUF_Adirelle_Arena"..index)
		frame:SetParent(anchor)
		frame:SetPoint("BOTTOM", anchor, "BOTTOM", 0, (index-1) * (40+47))
		frame.Enable, frame.Disable = ArenaUnit_Enable, ArenaUnit_Disable
		SecureHandlerWrapScript(frame, "OnAttributeChanged", frame, ArenaUnit_OnAttributeChanged)
		tinsert(frames, frame)

		oUF:SetActiveStyle("Adirelle_Single_Health")	
		local petFrame = oUF:Spawn("arenapet"..index, "oUF_Adirelle_ArenaPet"..index)
		petFrame:SetParent(anchor)
		petFrame:SetPoint("BOTTOM", frame, "TOP", 0 ,5)
		tinsert(frames, petFrame)
	end
	
	-- Initialize
	oUF_Adirelle.RegisterMovable(anchor, "arenas", "Arena enemy frames")	
	anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
	anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	anchor:SetScript('OnEvent', anchor.Update)	
	anchor:Update()

	-- Prevent loading of Blizzard arena frames
	_G.Arena_LoadUI = function() end
	if _G.ArenaEnemyFrames then
		_G.ArenaEnemyFrames:Hide()
		_G.ArenaEnemyFrames.Show = _G.ArenaEnemyFrames.Hide
	end
end)

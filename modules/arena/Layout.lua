--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

oUF:Factory(function()
	--<GLOBALS
	local _G = _G
	local IsInInstance = _G.IsInInstance
	local RegisterUnitWatch = _G.RegisterUnitWatch
	local SecureHandlerWrapScript = _G.SecureHandlerWrapScript
	local select = _G.select
	local UnregisterUnitWatch = _G.UnregisterUnitWatch
	--GLOBALS>

	local offset = 250+max(0, GetScreenWidth()-1280)/5

	local anchor = oUF_Adirelle.CreatePseudoHeader("oUF_Adirelle_Arena", "arena", "Arena enemy frames", 190, 5*(47+40)-15, 'BOTTOMLEFT', _G.UIParent, 'BOTTOM', offset, 385)

	function anchor:ShouldEnable()
		return select(2, IsInInstance()) == "arena"
	end
	anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
	anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')

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
		anchor:AddFrame(frame)

		oUF:SetActiveStyle("Adirelle_Single_Health")
		local petFrame = oUF:Spawn("arenapet"..index, "oUF_Adirelle_ArenaPet"..index)
		petFrame:SetParent(anchor)
		petFrame:SetPoint("BOTTOM", frame, "TOP", 0 ,5)
		anchor:AddFrame(frame)
	end

	-- Prevent loading of Blizzard arena frames
	_G.Arena_LoadUI = function() end
	if _G.ArenaEnemyFrames then
		_G.ArenaEnemyFrames:Hide()
		_G.ArenaEnemyFrames.Show = _G.ArenaEnemyFrames.Hide
	end
end)

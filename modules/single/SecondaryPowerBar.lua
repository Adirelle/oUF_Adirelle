--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

if oUF_Adirelle.SingleStyle then return end

--<GLOBALS
local _G = _G
local abs = _G.abs
local CreateFrame = _G.CreateFrame
local GetRuneType = _G.GetRuneType
local unpack = _G.unpack
--GLOBALS>

local GAP = private.GAP

local playerClass = oUF_Adirelle.playerClass

if playerClass == 'DEATHKNIGHT' then
	-- Runes
	local function UpdateRuneColor(rune)
		local color = oUF.colors.runes[GetRuneType(rune.index) or false]
		if color then
			rune:SetStatusBarColor(unpack(color))
		end
	end

	private.SetupSecondaryPowerBar = function(self)
		local runeBar = private.SpawnDiscreteBar(self, 6, true)
		self.RuneBar = runeBar
		runeBar:SetMinMaxValues(0, 6)
		runeBar:SetValue(6)
		for i = 1, 6 do
			runeBar[i].UpdateRuneColor = UpdateRuneColor
		end
		return runeBar
	end

elseif playerClass == "SHAMAN" then
	-- Totems
	private.SetupSecondaryPowerBar = function(self)
		local MAX_TOTEMS, SHAMAN_TOTEM_PRIORITIES = _G.MAX_TOTEMS, _G.SHAMAN_TOTEM_PRIORITIES
		local bar = private.SpawnDiscreteBar(self, MAX_TOTEMS, true)
		for i = 1, MAX_TOTEMS do
			local totemType = SHAMAN_TOTEM_PRIORITIES[i]
			bar[i].totemType = totemType
			bar[i]:SetStatusBarColor(unpack(oUF.colors.totems[totemType], 1, 3))
		end
		self.TotemBar = bar
		return bar
	end

elseif playerClass == 'MONK' then
	-- Stagger bar
	private.SetupSecondaryPowerBar = function(self)
		local bar = private.SpawnStatusBar(self)
		self.Stagger = bar
		return bar
	end
end

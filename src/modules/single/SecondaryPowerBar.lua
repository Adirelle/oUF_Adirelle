--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]=]

local _, private = ...

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

if oUF_Adirelle.SingleStyle then
	return
end

--<GLOBALS
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local playerClass = assert(oUF_Adirelle.playerClass)

if playerClass == "DEATHKNIGHT" then
	-- Runes
	private.SetupSecondaryPowerBar = function(self)
		local runeBar = self:SpawnDiscreteBar("rune", 6, true)
		self.RuneBar = runeBar
		runeBar:SetMinMaxValues(0, 6)
		runeBar:SetValue(6)
		for i = 1, 6 do
			runeBar[i]:SetStatusBarColor(unpack(oUF.colors.runes))
		end
		return runeBar
	end

elseif playerClass == "SHAMAN" then
	-- Totems
	private.SetupSecondaryPowerBar = function(self)
		local MAX_TOTEMS, SHAMAN_TOTEM_PRIORITIES = _G.MAX_TOTEMS, _G.SHAMAN_TOTEM_PRIORITIES
		local bar = self:SpawnDiscreteBar("totem", MAX_TOTEMS, true)
		for i = 1, MAX_TOTEMS do
			local totemType = SHAMAN_TOTEM_PRIORITIES[i]
			bar[i].totemType = totemType
			bar[i]:SetStatusBarColor(unpack(oUF.colors.totems[totemType], 1, 3))
		end
		self.TotemBar = bar
		return bar
	end

elseif playerClass == "MONK" then
	-- Stagger bar
	private.SetupSecondaryPowerBar = function(self)
		local bar = self:SpawnStatusBar("stagger")
		self.Stagger = bar
		return bar
	end
end

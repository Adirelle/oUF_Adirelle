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

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local GetThreatStatusColor = assert(_G.GetThreatStatusColor, "_G.GetThreatStatusColor is undefined")
local gsub = assert(_G.gsub, "_G.gsub is undefined")
local UnitAffectingCombat = assert(_G.UnitAffectingCombat, "_G.UnitAffectingCombat is undefined")
local UnitCanAttack = assert(_G.UnitCanAttack, "_G.UnitCanAttack is undefined")
local UnitIsPlayer = assert(_G.UnitIsPlayer, "_G.UnitIsPlayer is undefined")
local UnitIsUnit = assert(_G.UnitIsUnit, "_G.UnitIsUnit is undefined")
local UnitThreatSituation = assert(_G.UnitThreatSituation, "_G.UnitThreatSituation is undefined")
--GLOBALS>

local Update = function(self, _, unit)
	if unit ~= self.unit then
		return
	end
	unit = unit or self.unit

	local threat = self.SmartThreat
	if threat.PreUpdate then
		threat:PreUpdate(unit)
	end

	local status
	if UnitCanAttack(unit, "player") then
		if UnitIsPlayer(unit) then
			if UnitAffectingCombat(unit) and UnitIsUnit(gsub(unit, "(%d+)$", "target%1"), "player") then
				status = 3
			end
		else
			status = UnitThreatSituation("player", unit)
		end
	else
		status = UnitThreatSituation(unit)
	end

	if status and status > 0 then
		local r, g, b = GetThreatStatusColor(status)
		threat:SetVertexColor(r, g, b)
		threat:Show()
	else
		threat:Hide()
	end

	if threat.PostUpdate then
		return threat:PostUpdate(unit, status)
	end
end

local Path = function(self, ...)
	return (self.SmartThreat.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self)
	local threat = self.SmartThreat
	if threat then
		threat.__owner = self
		threat.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		self:RegisterEvent("UNIT_TARGET", Path)
		threat:Hide()

		return true
	end
end

local Disable = function(self)
	local threat = self.SmartThreat
	if threat then
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		self:UnregisterEvent("UNIT_TARGET", Path)
		threat:Hide()
	end
end

oUF:AddElement("SmartThreat", Path, Enable, Disable)

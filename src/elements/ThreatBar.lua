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

Elements handled: .ThreatBar
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local ForceUpdate = assert(_G.ForceUpdate)
local UnitCanAttack = assert(_G.UnitCanAttack)
local UnitDetailedThreatSituation = assert(_G.UnitDetailedThreatSituation)
local UnitIsUnit = assert(_G.UnitIsUnit)
local unpack = assert(_G.unpack)
--GLOBALS>

local function Update(self, event, unit)
	local playerUnit, mobUnit = "player", self.unit
	local bar = self.ThreatBar
	if not UnitCanAttack(playerUnit, mobUnit) and UnitCanAttack(self.unit, "target") then
		playerUnit, mobUnit = self.unit, "target"
	end
	if UnitIsUnit(playerUnit, mobUnit) or not UnitCanAttack(playerUnit, mobUnit) then
		bar:Hide()
		return
	end

	local isTanking, status, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation(playerUnit, mobUnit)
	if status then
		bar:SetValue(rawPercent)
		if status > 0 then
			bar:SetStatusBarColor(unpack(self.colors.threat[status], 1, 3))
		else
			bar:SetStatusBarColor(0, 1, 0)
		end
		bar:Show()
	else
		bar:Hide()
	end
	if bar.PostUpdate then
		bar:PostUpdate(event, unit, bar, isTanking, status, scaledPercent, rawPercent, threatValue)
	end
end

local function Enable(self)
	local bar = self.ThreatBar
	if bar then
		bar:Hide()

		bar.__owner = self
		bar = ForceUpdate
		self:RegisterEvent("UNIT_PET", Update)
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)

		return true
	end
end

local function Disable(self)
	if self.ThreatBar then
		self:UnregisterEvent("UNIT_PET", Update)
		self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		self.ThreatBar:Hide()
	end
end

oUF:AddElement("ThreatBar", Update, Enable, Disable)

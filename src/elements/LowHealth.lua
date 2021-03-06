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
local UnitCanAssist = assert(_G.UnitCanAssist, "_G.UnitCanAssist is undefined")
local UnitGetIncomingHeals = assert(_G.UnitGetIncomingHeals, "_G.UnitGetIncomingHeals is undefined")
local UnitGetTotalAbsorbs = assert(_G.UnitGetTotalAbsorbs, "_G.UnitGetTotalAbsorbs is undefined")
local UnitGetTotalHealAbsorbs = assert(_G.UnitGetTotalHealAbsorbs, "_G.UnitGetTotalHealAbsorbs is undefined")
local UnitHealth = assert(_G.UnitHealth, "_G.UnitHealth is undefined")
local UnitHealthMax = assert(_G.UnitHealthMax, "_G.UnitHealthMax is undefined")
local UnitIsConnected = assert(_G.UnitIsConnected, "_G.UnitIsConnected is undefined")
local UnitIsDeadOrGhost = assert(_G.UnitIsDeadOrGhost, "_G.UnitIsDeadOrGhost is undefined")
--GLOBALS>

local mmax = assert(_G.math.max)

local function Update(self, _, unit)
	if (unit and unit ~= self.unit) then
		return
	end
	unit = self.unit
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) then
		local health = UnitHealth(unit)
		local virtualHealth = mmax(
			health + (UnitGetTotalAbsorbs(unit) or 0),
			health - (UnitGetTotalHealAbsorbs(unit) or 0) + (UnitGetIncomingHeals(unit) or 0)
		)
		local threshold = self.LowHealth.threshold
		local actualThreshold = (threshold < 0) and -threshold * UnitHealthMax(unit) or threshold
		return self.LowHealth:SetShown(virtualHealth <= actualThreshold)
	end
	self.LowHealth:Hide()
end

local function Path(self, ...)
	return (self.LowHealth.Update or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local lowHealth = self.LowHealth
	if lowHealth then
		lowHealth:Hide()
		lowHealth.__owner, lowHealth.ForceUpdate = self, ForceUpdate
		if not lowHealth.threshold then
			lowHealth.threshold = -0.15
		end
		self:RegisterEvent("UNIT_HEALTH", Path)
		self:RegisterEvent("UNIT_MAXHEALTH", Path)
		self:RegisterEvent("UNIT_CONNECTION", Path)
		self:RegisterEvent("UNIT_TARGETABLE_CHANGED", Path)
		self:RegisterEvent("UNIT_HEAL_PREDICTION", Path)
		self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Path)
		self:RegisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Path)
		return true
	end
end

local function Disable(self)
	if self.LowHealth then
		self.LowHealth:Hide()
		self:UnregisterEvent("UNIT_HEALTH", Path)
		self:UnregisterEvent("UNIT_MAXHEALTH", Path)
		self:UnregisterEvent("UNIT_CONNECTION", Path)
		self:UnregisterEvent("UNIT_TARGETABLE_CHANGED", Path)
		self:UnregisterEvent("UNIT_HEAL_PREDICTION", Path)
		self:UnregisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", Path)
		self:UnregisterEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", Path)
	end
end

oUF:AddElement("LowHealth", Path, Enable, Disable)

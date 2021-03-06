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

Elements handled: .Border
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local IsInInstance = assert(_G.IsInInstance, "_G.IsInInstance is undefined")
local select = assert(_G.select, "_G.select is undefined")
local UnitAffectingCombat = assert(_G.UnitAffectingCombat, "_G.UnitAffectingCombat is undefined")
local UnitExists = assert(_G.UnitExists, "_G.UnitExists is undefined")
local UnitIsDeadOrGhost = assert(_G.UnitIsDeadOrGhost, "_G.UnitIsDeadOrGhost is undefined")
local UnitIsUnit = assert(_G.UnitIsUnit, "_G.UnitIsUnit is undefined")
local UnitPower = assert(_G.UnitPower, "_G.UnitPower is undefined")
local UnitPowerMax = assert(_G.UnitPowerMax, "_G.UnitPowerMax is undefined")
local UnitPowerType = assert(_G.UnitPowerType, "_G.UnitPowerType is undefined")
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local SPELL_POWER_MANA = _G.Enum.PowerType.Mana

oUF.colors.border = {
	target = { 1.0, 1.0, 1.0 },
	focus = { 1.0, 0.8, 0.0 },
	black = { 0.0, 0.0, 0.0 },
	lowMana = oUF.colors.power.MANA,
}

local function Update(self, _, unit)
	if unit and unit ~= self.unit then
		return
	end
	unit = self.unit
	local border = self.Border
	local color
	if border.blackByDefault then
		color = oUF.colors.border.black
	end
	if unit and UnitExists(unit) then
		if self.unit ~= "target" and not border.noTarget and UnitIsUnit("target", unit) then
			color = oUF.colors.border.target
		elseif self.unit ~= "focus" and not border.noFocus and UnitIsUnit("focus", unit) then
			color = oUF.colors.border.focus
		elseif not UnitIsDeadOrGhost(unit) and border.manaThreshold then
			local manaCur, manaMax = UnitPower(unit, SPELL_POWER_MANA), UnitPowerMax(unit, SPELL_POWER_MANA)
			if manaMax > 0 and manaCur / manaMax < border.manaThreshold then
				color = oUF.colors.border.lowMana
			end
		end
	end
	if color then
		border:SetColor(unpack(color))
		border:Show()
	else
		border:Hide()
	end
	return true
end

local function PowerUpdate(self, event, unit, power)
	if power == "MANA" and unit == self.unit then
		return Update(self, event)
	end
end

local function TogglePowerUpdates(self, event, unit)
	if unit and unit ~= self.unit then
		return
	end
	local border = self.Border
	local manaThreshold
	if UnitPowerType(self.unit) == SPELL_POWER_MANA then
		if UnitAffectingCombat(self.unit) then
			manaThreshold = border.inCombatManaLevel
		elseif select(2, IsInInstance()) == "raid" then
			manaThreshold = border.oocInRaidManaLevel
		else
			manaThreshold = border.oocManaLevel
		end
	end
	if border.manaThreshold == manaThreshold then
		return
	end
	border.manaThreshold = manaThreshold
	if manaThreshold then
		self:RegisterEvent("UNIT_POWER_UPDATE", PowerUpdate)
		self:RegisterEvent("UNIT_MAXPOWER", PowerUpdate)
	else
		self:UnregisterEvent("UNIT_POWER_UPDATE", PowerUpdate)
		self:UnregisterEvent("UNIT_MAXPOWER", PowerUpdate)
	end
	return Update(self, event)
end

local function ForceUpdate(self, event)
	return TogglePowerUpdates(self, event) or Update(self, event)
end

local function Element_ForceUpdate(element, event)
	return ForceUpdate(element.__owner, event)
end

local function Enable(self)
	local border = self.Border
	if border then
		border.inCombatManaLevel = border.inCombatManaLevel or 0.3
		border.oocInRaidManaLevel = border.oocInRaidManaLevel or 0.9
		border.oocManaLevel = border.oocManaLevel or 0.6
		border.__owner, border.ForceUpdate = self, Element_ForceUpdate
		self:RegisterEvent("UNIT_DISPLAYPOWER", TogglePowerUpdates)
		self:RegisterEvent("UNIT_FLAGS", TogglePowerUpdates)
		if not border.noTarget then
			self:RegisterEvent("PLAYER_TARGET_CHANGED", ForceUpdate, true)
		end
		if not border.noFocus then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED", ForceUpdate, true)
		end
		self.Border:Hide()
		return true
	end
end

local function Disable(self)
	local border = self.Border
	if border then
		border.hasMana, border.manaThreshold = nil, nil

		self:UnregisterEvent("UNIT_POWER_UPDATE", PowerUpdate)
		self:UnregisterEvent("UNIT_MAXPOWER", PowerUpdate)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", TogglePowerUpdates)
		self:UnregisterEvent("UNIT_FLAGS", TogglePowerUpdates)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", ForceUpdate)
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED", ForceUpdate)
		border:Hide()
	end
end

oUF:AddElement("Border", ForceUpdate, Enable, Disable)

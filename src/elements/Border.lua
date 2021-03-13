--[=[
Adirelle's oUF layout
(c) 2009-2016 Adirelle (adirelle@gmail.com)

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

local _G = _G
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

local IsInInstance = _G.IsInInstance
local select = _G.select
local SPELL_POWER_MANA = _G.Enum.PowerType.Mana
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitExists = _G.UnitExists
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsUnit = _G.UnitIsUnit
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local unpack = _G.unpack

oUF.colors.border = {
	target = { 1.0, 1.0, 1.0 },
	focus = { 1.0, 0.8, 0.0 },
	black = { 0.0, 0.0, 0.0 },
	combat = { 1.0, 0.5, 0.0 },
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
		if border.combatTimer > 0 then
			color = oUF.colors.border.combat
		elseif self.unit ~= "target" and not border.noTarget and UnitIsUnit("target", unit) then
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

local function OnUpdate(border, elapsed)
	if border.combatTimer < elapsed then
		border.combatTimer = 0
		border:SetAlpha(1.0)
		border:SetScript("OnUpdate", nil)
		return Update(border.__owner, "OnUpdate")
	end
	border.combatTimer = border.combatTimer - elapsed
	local x = math.fmod(border.combatTimer, 0.5)
	if x >= 0.25 then
		border:SetAlpha(4 * x - 1)
	else
		border:SetAlpha(1 - 4 * x)
	end
end

local function FlagUpdate(self, event, unit)
	if unit and unit ~= self.unit then
		return
	end
	local updated = TogglePowerUpdates(self, event, unit)
	local border = self.Border
	if border.noCombat then
		return updated
	end
	local inCombat = UnitAffectingCombat(self.unit)
	if inCombat and not border.inCombat then
		border.inCombat, border.combatTimer = true, 3
		border:SetScript("OnUpdate", OnUpdate)
	elseif not inCombat and border.inCombat then
		border.inCombat, border.combatTimer = false, 0
		border:SetScript("OnUpdate", nil)
	else
		return updated
	end
	OnUpdate(border, 0)
	return Update(self, event) or updated
end

local function ForceUpdate(self, event)
	return FlagUpdate(self, event) or Update(self, event)
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
		border.combatTimer = 0
		border.__owner, border.ForceUpdate = self, Element_ForceUpdate
		self:RegisterEvent("UNIT_DISPLAYPOWER", TogglePowerUpdates)
		self:RegisterEvent("UNIT_FLAGS", FlagUpdate)
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

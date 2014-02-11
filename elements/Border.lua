 --[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .Border
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local IsInInstance = _G.IsInInstance
local select = _G.select
local SPELL_POWER_MANA = _G.SPELL_POWER_MANA
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitExists = _G.UnitExists
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsUnit = _G.UnitIsUnit
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local unpack = _G.unpack
--GLOBALS>

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = self.unit
	local border = self.Border
	local r, g, b
	if border.blackByDefault then
		r, g, b = 0, 0, 0
	end
	if unit and UnitExists(unit) then
		if not border.noTarget and UnitIsUnit('target', unit) then
			r, g, b = 1, 1, 1
		elseif not UnitIsDeadOrGhost(unit) and border.manaThreshold and UnitPower(unit, SPELL_POWER_MANA) / UnitPowerMax(unit, SPELL_POWER_MANA) <= border.manaThreshold then
			r, g, b = unpack(oUF.colors.power.MANA)
		end
	end
	if b then
		border:SetColor(r, g, b)
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
	if unit and unit ~= self.unit then return end
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
	if border.manaThreshold == manaThreshold then return end
	border.manaThreshold = manaThreshold
	if manaThreshold then
		self:RegisterEvent("UNIT_POWER", PowerUpdate)
		self:RegisterEvent("UNIT_MAXPOWER", PowerUpdate)
	else
		self:UnregisterEvent("UNIT_POWER", PowerUpdate)
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
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		self.Border:Hide()
		return true
	end
end

local function Disable(self)
	local border = self.Border
	if border then
		border.hasMana, border.manaThreshold = nil, nil

		self:UnregisterEvent("UNIT_POWER", PowerUpdate)
		self:UnregisterEvent("UNIT_MAXPOWER", PowerUpdate)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", TogglePowerUpdates)
		self:UnregisterEvent("UNIT_FLAGS", TogglePowerUpdates)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		border:Hide()
	end
end

oUF:AddElement('Border', ForceUpdate, Enable, Disable)


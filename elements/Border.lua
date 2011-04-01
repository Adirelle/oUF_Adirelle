 --[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .Border	
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local UnitExists = UnitExists
local UnitIsUnit = UnitIsUnit
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsAffectingCombat = UnitIsAffectingCombat
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local IsInInstance = IsInInstance

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
		elseif not UnitIsDeadOrGhost(unit) and border.hasMana and UnitPower(unit, SPELL_POWER_MANA) / UnitPowerMax(unit, SPELL_POWER_MANA) <= border.manaThreshold then
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
	local hasMana = UnitPowerType(self.unit) == SPELL_POWER_MANA
	local manaThreshold = hasMana and (UnitAffectingCombat(self.unit) and 0.3 or select(2, IsInInstance()) == "raid" and 0.9 or 0.6) 
	if border.hasMana == hasMana and border.manaThreshold == manaThreshold then return end
	border.hasMana, border.manaThreshold = hasMana, manaThreshold
	if hasMana then
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

local function Enable(self)
	if self.Border then
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


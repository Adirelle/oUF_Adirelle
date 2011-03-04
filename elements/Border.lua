 --[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .Border	
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local UnitIsUnit = UnitIsUnit
local UnitPowerType = UnitPowerType
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax

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
		elseif not UnitIsDeadOrGhost(unit) and UnitPowerType(unit) == SPELL_POWER_MANA and UnitPower(unit, SPELL_POWER_MANA) / UnitPowerMax(unit, SPELL_POWER_MANA) < 0.25 then
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
	if power == "MANA" then
		return Update(self, event, unit)
	end
end

local function TogglePowerUpdates(self, event, unit)
	if not unit or unit == self.unit then
		if UnitPowerType(unit) == SPELL_POWER_MANA then
			self:RegisterEvent("UNIT_POWER", PowerUpdate)
			self:RegisterEvent("UNIT_MAXPOWER", PowerUpdate)
		else
			self:UnregisterEvent("UNIT_POWER", PowerUpdate)
			self:UnregisterEvent("UNIT_MAXPOWER", PowerUpdate)
		end
		return Update(self, event, unit)
	end
end

local function FullUpdate(self, event)
	if not TogglePowerUpdates(self, event, self.unit) then
		return Update(self, event, self.unit)
	end
end

local function Enable(self)
	if self.Border then
		self:RegisterEvent("UNIT_DISPLAYPOWER", TogglePowerUpdates)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)			
		self.Border:Hide()
		return true
	end
end

local function Disable(self)
	local border = self.Border
	if border then
		self:UnregisterEvent("UNIT_POWER", PowerUpdate)
		self:UnregisterEvent("UNIT_MAXPOWER", PowerUpdate)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", TogglePowerUpdates)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)			
		border:Hide()
	end
end

oUF:AddElement('Border', FullUpdate, Enable, Disable)


--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local max = _G.math.max
local UnitCanAssist = _G.UnitCanAssist
local UnitGetIncomingHeals = _G.UnitGetIncomingHeals
local UnitGetTotalAbsorbs = _G.UnitGetTotalAbsorbs
local UnitGetTotalHealAbsorbs = _G.UnitGetTotalHealAbsorbs
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
--GLOBALS>

local function Update(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	unit = self.unit
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) then
		local health = UnitHealth(unit)
		local virtualHealth = max(
			health + (UnitGetTotalAbsorbs(unit) or 0),
			health - (UnitGetTotalHealAbsorbs(unit) or 0) + (UnitGetIncomingHeals(unit) or 0)
		)
		local threshold = self.LowHealth.threshold
		local actualThreshold = (threshold < 0) and (-threshold * UnitHealthMax(unit)) or threshold
		return self.LowHealth:SetShown(virtualHealth <= actualThreshold)
	end
	self.LowHealth:Hide()
end

local function Path(self, ...)
	return (self.LowHealth.Update or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
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
		self:RegisterEvent("UNIT_HEALTH_FREQUENT", Path)
		self:RegisterEvent("UNIT_MAXHEALTH", Path)
		self:RegisterEvent("UNIT_CONNECTION", Path)
		self:RegisterEvent("UNIT_TARGETABLE_CHANGED", Path)
		self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
		self:RegisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
		return true
	end
end

local function Disable(self)
	if self.LowHealth then
		self.LowHealth:Hide()
		self:UnregisterEvent("UNIT_HEALTH", Path)
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT", Path)
		self:UnregisterEvent("UNIT_MAXHEALTH", Path)
		self:UnregisterEvent("UNIT_CONNECTION", Path)
		self:UnregisterEvent("UNIT_TARGETABLE_CHANGED", Path)
		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:UnregisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
		self:UnregisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
	end
end

oUF:AddElement('LowHealth', Path, Enable, Disable)


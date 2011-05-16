--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local UnitCanAssist = _G.UnitCanAssist
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local floor, pairs = _G.floor, _G.pairs

local function Update(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	unit = self.unit
	local threshold = self.LowHealth.threshold
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) then
		local health = UnitHealth(unit)
		if threshold < 0 then
			if health / UnitHealthMax(unit) < -threshold then
				return self.LowHealth:Show()
			end
		elseif health < threshold then
			return self.LowHealth:Show()
		end
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
	end
end

oUF:AddElement('LowHealth', Path, Enable, Disable)


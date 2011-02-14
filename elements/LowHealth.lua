--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local objects = {}
local threshold -- positive = flat amount, negative = percent, nil = disabled

local function Update(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	unit = self.unit
	local visible
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		local health = UnitHealth(unit)
		if threshold < 0 then
			visible = floor(health / UnitHealthMax(unit)) < -threshold
		else
			visible =  health < threshold
		end
	end
	if visible then
		self.LowHealth:Show()
	else
		self.LowHealth:Hide()
	end
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
		if not objects[self] then
			lowHealth.__owner, lowHealth.ForceUpdate = self, ForceUpdate
			objects[self] = true
		end
		if threshold then
			self:RegisterEvent("UNIT_HEALTH_FREQUENT", Path)
			self:RegisterEvent("UNIT_MAXHEALTH", Path)
			self:RegisterEvent("UNIT_CONNECTION", Path)
			return true
		end
	end
end

local function Disable(self)
	if self.LowHealth then
		self.LowHealth:Hide()
		self:UnregisterEvent("UNIT_HEALTH_FREQUENT", Path)
		self:UnregisterEvent("UNIT_MAXHEALTH", Path)
		self:UnregisterEvent("UNIT_CONNECTION", Path)
	end
end

oUF:AddElement('LowHealth', Path, Enable, Disable)

_G.SLASH_OUFALOWHEALTH1 = "/oufa_health"
_G.SLASH_OUFALOWHEALTH2 = "/oufah"
_G.SlashCmdList.OUFALOWHEALTH = function(arg)
	arg = strtrim(arg or "")
	local newThreshold
	local percent = strmatch(arg, "^(%d+)%s*%%$")
	if percent then
		newThreshold = -tonumber(percent)
		print("oUF_Adirelle LowHealth: threshold set to "..percent.."%")
	else
		local flat, thousands = strmatch(arg, "^(%d+)%s*([kK]?)$")
		if flat then
			newThreshold = thousands ~= "" and (1000*tonumber(flat)) or tonumber(flat)
			print("oUF_Adirelle LowHealth: threshold set to "..newThreshold)
		else
			print("oUF_Adirelle LowHealth: disabled")
		end
	end
	if newThreshold ~= threshold then
		threshold = newThreshold
		if threshold then
			for frame in pairs(objects) do
				frame:EnableElement('LowHealth')
				frame.LowHealth:ForceUpdate('Setting')
			end
		else
			for frame in pairs(objects) do
				frame:DisableElement('LowHealth')
			end
		end
	end
end


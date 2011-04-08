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
local floor, format, pairs, print = _G.floor, _G.format, _G.pairs, _G.print
local strlower, strmatch, strtrim, tonumber = _G.strlower, _G.sstrmatch, _G.sstrtrim, _G.stonumber

local objects = {}
local threshold -- positive = flat amount, negative = percent, nil = disabled

local function Update(self, event, unit)
	if (unit and unit ~= self.unit) or not threshold then return end
	unit = self.unit
	local visible
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAssist("player", unit) then
		local health = UnitHealth(unit)
		if threshold < 0 then
			visible = floor(100 * health / UnitHealthMax(unit)) < -threshold
		else
			visible = health < threshold
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
			self:RegisterEvent("UNIT_HEALTH", Path)
			self:RegisterEvent("UNIT_HEALTH_FREQUENT", Path)
			self:RegisterEvent("UNIT_MAXHEALTH", Path)
			self:RegisterEvent("UNIT_CONNECTION", Path)
			self:RegisterEvent("UNIT_TARGETABLE_CHANGED", Path)
			return true
		end
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

local function PrintThreshold()
	local msg
	if not threshold then
		msg = "disabled"
	elseif threshold < 0 then 
		msg = format("threshold set to %d%%", -threshold)
	elseif threshold > 0 then 
		msg = format("threshold set to %d", threshold)
	end
	print("|cff33ff99oUF_Adirelle LowHealth:|r "..msg..".")
end

local db

local function SetThreshold(newThreshold, stealth)
	if newThreshold == 0 then
		newThreshold = nil
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
	if not stealth then
		db.LowHealthThreshold = newThreshold
		PrintThreshold()
	end
end

oUF_Adirelle.RegisterVariableLoadedCallback(function(dbRef)
	db = dbRef
	return SetThreshold(db.LowHealthThreshold, true)
end)

_G.SLASH_OUFALOWHEALTH1 = "/oufa_health"
_G.SLASH_OUFALOWHEALTH2 = "/oufah"
_G.SlashCmdList.OUFALOWHEALTH = function(arg)
	arg = strlower(strtrim(arg or ""))
	local percent = tonumber(strmatch(arg, "^(%d+)%s*%%$"))
	if percent then
		if percent >= 0 and percent < 100 then
			return SetThreshold(-percent)
		end
	else
		local flat, thousands = strmatch(arg, "^(%d+)%s*(k?)$")
		flat = tonumber(flat)
		if flat and flat >= 0 then
			if thousands ~= "" then
				flat = flat * 1000
			end
			return SetThreshold(flat)
		end
	end
	if arg == "" then
		PrintThreshold()
	else
		print("|cff33ff99oUF_Adirelle LowHealth usage:|r")
		print("- /oufa_health 54321: set health threshold to 54321.")
		print("- /oufa_health 123k: set health threshold to 123000.")
		print("- /oufa_health 10%: set health threshold to 10% of total health.")
		print("- /oufa_health 0: disable this.")
		print("- /oufa_health: show the current health threshold.")
		print("- /oufa_health help|?|usage: show this help.")
		print("Also work with /oufah.")
	end
end

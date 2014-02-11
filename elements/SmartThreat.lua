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
local GetThreatStatusColor = _G.GetThreatStatusColor
local gsub = _G.gsub
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitCanAttack = _G.UnitCanAttack
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsUnit = _G.UnitIsUnit
local UnitThreatSituation = _G.UnitThreatSituation
--GLOBALS>

local Update = function(self, event, unit)
	if unit ~= self.unit then return end

	local threat = self.SmartThreat
	if threat.PreUpdate then threat:PreUpdate(unit) end

	unit = unit or self.unit
	local status
	if UnitCanAttack(unit, "player") then
		if UnitIsPlayer(unit) then
			if UnitAffectingCombat(unit) and UnitIsUnit(gsub(unit, "(%d+)$", "target%1"), "player") then
				status = 3
			end
		else
			status = UnitThreatSituation("player", unit)
		end
	else
		status = UnitThreatSituation(unit)
	end

	if status and status > 0 then
		local r, g, b = GetThreatStatusColor(status)
		threat:SetVertexColor(r, g, b)
		threat:Show()
	else
		threat:Hide()
	end

	if threat.PostUpdate  then
		return threat:PostUpdate(unit, status)
	end
end

local Path = function(self, ...)
	return (self.SmartThreat.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local threat = self.SmartThreat
	if threat  then
		threat.__owner = self
		threat.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		self:RegisterEvent("UNIT_TARGET", Path)
		threat:Hide()

		return true
	end
end

local Disable = function(self)
	local threat = self.SmartThreat
	if threat then
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		self:UnregisterEvent("UNIT_TARGET", Path)
		threat:Hide()
	end
end

oUF:AddElement('SmartThreat', Path, Enable, Disable)

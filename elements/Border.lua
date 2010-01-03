 --[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .Border	
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local UnitThreatSituation = UnitThreatSituation
local GetThreatStatusColor = GetThreatStatusColor
local UnitIsUnit = UnitIsUnit
local UnitPowerType = UnitPowerType
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax

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
		elseif not UnitIsDeadOrGhost(unit) then
			local threat = UnitThreatSituation(unit)
			if threat and threat > 0 then
				r, g, b = GetThreatStatusColor(threat)
			elseif UnitPowerType(unit) == 0 and UnitMana(unit) / UnitManaMax(unit) < 0.25 then
				r, g, b = unpack(oUF.colors.power.MANA)
			end
		end
	end
	if b then
		border:SetColor(r, g, b)
		border:Show()
	else
		border:Hide()
	end
end

local function Enable(self)
	if self.Border then
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		self:RegisterEvent("UNIT_MANA", Update)
		self:RegisterEvent("UNIT_MAXMANA", Update)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)			
		self.Border:Hide()
		return true
	end
end

local function Disable(self)
	local border = self.Border
	if border then
		self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		self:UnregisterEvent("UNIT_MANA", Update)
		self:UnregisterEvent("UNIT_MAXMANA", Update)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)			
		border:Hide()
	end
end

oUF:AddElement('Border', Update, Enable, Disable)


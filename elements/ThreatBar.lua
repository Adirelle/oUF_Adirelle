--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .ThreatBar
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local GetRealNumPartyMembers = _G.GetRealNumPartyMembers
local GetRealNumRaidMembers = _G.GetRealNumRaidMembers
local UnitDetailedThreatSituation = _G.UnitDetailedThreatSituation
local GetThreatStatusColor = _G.GetThreatStatusColor

local function Update(self, event, unit)
	if unit and (unit ~= self.unit and unit ~= "player") then return end
	local bar = self.ThreatBar
	if GetRealNumPartyMembers() == 0 and GetRealNumRaidMembers() == 0 then return bar:Hide() end
	local isTanking, status, scaledPercent, rawPercent, threatValue = UnitDetailedThreatSituation("player", self.unit)
	if status then
		bar:SetValue(scaledPercent)
		if status > 0 then
			bar:SetStatusBarColor(GetThreatStatusColor(status))
		else
			bar:SetStatusBarColor(0, 1, 0)
		end
		bar:Show()
	else
		bar:Hide()
	end
	if bar.PostUpdate then
		bar.PostUpdate(self, event, unit, bar, isTanking, status, scaledPercent, rawPercent, threatValue)
	end
end

local function Enable(self)
	if self.ThreatBar then
		self:RegisterEvent("PARTY_MEMBERS_CHANGED", Update)
		self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		self.ThreatBar:Hide()
		return true
	end
end

local function Disable(self)
	if self.ThreatBar then
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED", Update)
		self:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		self.ThreatBar:Hide()
	end
end

oUF:AddElement('ThreatBar', Update, Enable, Disable)

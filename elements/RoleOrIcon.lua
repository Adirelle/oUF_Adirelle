--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .RoleIcon
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local Debug = ns.Debug

local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local GetPartyAssignment = GetPartyAssignment
local UnitInRaid = UnitInRaid
local UnitInParty = UnitInParty
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetRealNumRaidMembers = GetRealNumRaidMembers
local GetRealNumPartyMembers = GetRealNumPartyMembers

local LibGuessRole = ns.GetLib('LibGuessRole-1.0')

local function GetRole(unit, noDamager)
	if not UnitIsPlayer(unit) then
		Debug('Ignoring not-unit', unit)
		return
	end

	-- Check assigned raid roles
	if GetRealNumRaidMembers() > 0 and UnitInRaid(unit) then
		Debug('GetPartyAssignment for ', unit, ': MAINASSIST=', GetPartyAssignment("MAINASSIST", unit), "MAINTANK=", GetPartyAssignment("MAINTANK", unit))
		if GetPartyAssignment("MAINASSIST", unit) then
			return [[Interface\GroupFrame\UI-Group-MainAssistIcon]]
		elseif GetPartyAssignment("MAINTANK", unit) then
			return [[Interface\GroupFrame\UI-Group-MainTankIcon]]
		end

	-- Check assigned LFD roles
	elseif GetRealNumPartyMembers() > 0 and UnitInParty(unit) then
		local isTank, isHealer, isDamager = UnitGroupRolesAssigned(unit)
		Debug('UnitGroupRolesAssigned', unit, ':', isTank and "tank", isHealer and "healer", isDamager and "damager")
		if isTank then
			return [[Interface\LFGFrame\LFGRole]], 0.5, 0.75
		elseif isHealer then
			return [[Interface\LFGFrame\LFGRole]], 0.75, 1
		elseif isDamager then
			if noDamager then
				return
			else
				return [[Interface\LFGFrame\LFGRole]], 0.25, 0.5
			end
		end
	end

	-- Fallback on LibGuessRole
	local role, level = LibGuessRole:GetUnitRole(unit)
	Debug('LibGuessRole:GetUnitRole for', unit, ':', role, level)
	if role == LibGuessRole.ROLE_TANK then
		return [[Interface\LFGFrame\LFGRole_BW]], 0.5, 0.75, 1, 0.82, 0
	elseif role == LibGuessRole.ROLE_HEALER then
		return [[Interface\LFGFrame\LFGRole_BW]], 0.75, 1, 1, 0.82, 0
	elseif role and not noDamager then
		return [[Interface\LFGFrame\LFGRole_BW]], 0.25, 0.5, 1, 0.82, 0
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local icon = self.RoleIcon
	unit = self.unit

	-- Check raid target icons
	local raidTarget = not icon.noRaidTarget and GetRaidTargetIndex(unit)
	if raidTarget then
		icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		icon:SetVertexColor(1, 1, 1, 1)
		SetRaidTargetIconTexture(icon, raidTarget)
		return icon:Show()
	end

	local texture, x0, x1, r, g, b = GetRole(unit, icon.noDamager)
	if texture then
		icon:SetTexture(texture)
		icon:SetVertexColor(r or 1, g or 1, b or 1, 1)
		icon:SetTexCoord(x0 or 0, x1 or 1, 0, 1)
		icon:Show()
	else
		icon:Hide()
	end
end

local function RoleChanged(self, event, guid)
	if self.unit and UnitGUID(self.unit) == guid then
		return Update(self, event)
	end
end

local function Enable(self)
	if self.RoleIcon then
		self:RegisterEvent('PARTY_MEMBERS_CHANGED', Update)
		self:RegisterEvent("RAID_TARGET_UPDATE", Update)
		self:RegisterEvent('RAID_ROSTER_UPDATE', Update)
		self:RegisterEvent('LFG_ROLE_UPDATE', Update)
		LibGuessRole.RegisterCallback(self, "LibGuessRole_RoleChanged", RoleChanged, self)
		self.RoleIcon:Hide()
		return true
	end
end

local function Disable(self)
	if self.RoleIcon then
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', Update)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Update)
		self:UnregisterEvent('LFG_ROLE_UPDATE', Update)
		self:UnregisterEvent('RAID_ROSTER_UPDATE', Update)
		LibGuessRole.UnregisterCallback(self, "LibGuessRole_RoleChanged")
		self.RoleIcon:Hide()
	end
end

oUF:AddElement('RoleIcon', Update, Enable, Disable)


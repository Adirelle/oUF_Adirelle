--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .RoleIcon
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local Debug = ns.Debug

local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local UnitInRaid = UnitInRaid
local UnitIsPlayer = UnitIsPlayer
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetRealNumRaidMembers = GetRealNumRaidMembers

local LibGuessRole = ns.GetLib('LibGuessRole-1.0')
local ROLE_TANK, ROLE_HEALER = LibGuessRole.ROLE_TANK, LibGuessRole.ROLE_HEALER

local function GetRole(unit, noDamager)
	if not UnitIsPlayer(unit) then return end

	-- Check assigned raid roles
	local raidId = GetRealNumRaidMembers() > 0 and UnitInRaid(unit)
	if raidId then
		local role = select(10, GetRaidRosterInfo(raidId))
		--Debug('Role from GetRaidRosterInfo for ', unit, ':', role)
		if role and role ~= "NONE" and (not noDamager or role ~= "DAMAGER") then
			return "Interface\\GroupFrame\\UI-Group-"..role.."Icon"
		end
	end

	-- Check assigned roles
	local role = UnitGroupRolesAssigned(unit)
	if role and role ~= "NONE" then
		--Debug('Role from UnitGroupRolesAssigned for ', unit, ':', role)
		if noDamager and role == "DAMAGER" then
			return
		end
		return [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]], GetTexCoordsForRoleSmallCircle(role)
	end

	-- Fallback on LibGuessRole
	local role, level = LibGuessRole:GetUnitRole(unit)
	if role then
		--Debug('LibGuessRole:GetUnitRole for', unit, ':', role, level)
		local index = (role == ROLE_TANK and 3) or (role == ROLE_HEALER and 4) or (not noDamager and 2)
		if index then
			return [[Interface\LFGFrame\LFGRole_BW]], (index-1)/4, index/4, 0, 1, 1, 0.82, 0
		end
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local icon = self.RoleIcon

	-- Check raid target icons
	local raidTarget = not icon.noRaidTarget and GetRaidTargetIndex(self.unit)
	if raidTarget then
		icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		icon:SetVertexColor(1, 1, 1, 1)
		SetRaidTargetIconTexture(icon, raidTarget)
		return icon:Show()
	end

	-- Check role
	local texture, x0, x1, y0, y1, r, g, b = GetRole(self.unit, icon.noDamager)
	if texture then
		icon:SetTexture(texture)
		icon:SetVertexColor(r or 1, g or 1, b or 1, 1)
		icon:SetTexCoord(x0 or 0, x1 or 1, y0 or 0, y1 or 1)
		icon:Show()
	else
		icon:Hide()
	end
end

local function Path(self, ...)
	return (self.RoleIcon.Update or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function RoleChanged(self, event, guid)
	if self.unit and UnitGUID(self.unit) == guid then
		return Path(self, event)
	end
end

local function Enable(self)
	if self.RoleIcon then
		self:RegisterEvent('PARTY_MEMBERS_CHANGED', Path)
		self:RegisterEvent("RAID_TARGET_UPDATE", Path)
		self:RegisterEvent('RAID_ROSTER_UPDATE', Path)
		self:RegisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		LibGuessRole.RegisterCallback(self, "LibGuessRole_RoleChanged", RoleChanged, self)
		self.RoleIcon:Hide()
		return true
	end
end

local function Disable(self)
	local icon = self.RoleIcon
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', Path)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Path)
		self:UnregisterEvent('LFG_ROLE_UPDATE', Path)
		self:UnregisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		LibGuessRole.UnregisterCallback(self, "LibGuessRole_RoleChanged")
		icon:Hide()
	end
end

oUF:AddElement('RoleIcon', Path, Enable, Disable)


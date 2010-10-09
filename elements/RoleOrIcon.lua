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
local UnitInRaid = UnitInRaid
local UnitIsPlayer = UnitIsPlayer
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetRealNumRaidMembers = GetRealNumRaidMembers

local LibGuessRole = ns.GetLib('LibGuessRole-1.0')

local function GetRole(unit, noDamager)
	if not UnitIsPlayer(unit) then
		Debug('Ignoring not-unit', unit)
		return
	end

	-- Check assigned raid roles
	local raidId = GetRealNumRaidMembers() > 0 and UnitInRaid(unit)
	if raidId then
		local role = select(10, GetRaidRosterInfo(raidId))
		if role and role ~= "NONE" and (not noDamager or role ~= "DAMAGER") then
			return "Interface\\GroupFrame\\UI-Group-"..role.."Icon"
		end
	end

	-- Check assigned roles
	local role = UnitGroupRolesAssigned(unit)
	Debug('UnitGroupRolesAssigned', unit, ':', role)
	if role and role ~= "NONE" then
		if noDamager and role == "DAMAGER" then
			return
		end
		return [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]], GetTexCoordsForRoleSmallCircle(role)
	end

	-- Fallback on LibGuessRole
	local role, level = LibGuessRole:GetUnitRole(unit)
	Debug('LibGuessRole:GetUnitRole for', unit, ':', role, level)
	if role == LibGuessRole.ROLE_TANK then
		return [[Interface\LFGFrame\LFGRole_BW]], 0.5, 0.75, 0, 1, 1, 0.82, 0
	elseif role == LibGuessRole.ROLE_HEALER then
		return [[Interface\LFGFrame\LFGRole_BW]], 0.75, 1, 0, 1, 1, 0.82, 0
	elseif role and not noDamager then
		return [[Interface\LFGFrame\LFGRole_BW]], 0.25, 0.5, 0, 1, 1, 0.82, 0
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

	-- Check role
	local texture, x0, x1, y0, y1 r, g, b = GetRole(unit, icon.noDamager)
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

oUF:AddElement('RoleIcon', Update, Enable, Disable)


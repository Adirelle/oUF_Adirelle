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

local function GetRole(unit, noDamager, noCircle)
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
	local role = UnitIsUnit(unit, "player") and ns.GetPlayerRole() or UnitGroupRolesAssigned(unit)
	if role and role ~= "NONE" then
		--Debug('Role from UnitGroupRolesAssigned for ', unit, ':', role)
		if noDamager and role == "DAMAGER" then
			return
		end
		if noCircle then
			local x0, x1, y0, y1 = GetTexCoordsForRoleSmall(role)
			return [[Interface\LFGFrame\LFGRole_bw]], x0, x1, y0, y1, 1, 0.82, 0
		else
			return [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]], GetTexCoordsForRoleSmallCircle(role)
		end
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local icon = self.RoleIcon

	-- Quest mobs
	if UnitIsQuestBoss(self.unit) then
		icon:SetTexture([[Interface\TargetingFrame\PortraitQuestBadge]])
		icon:SetVertexColor(1, 1, 1, 1)
		icon:SetTexCoord(0, 1, 0, 1)
		return icon:Show()
	end

	-- Check raid target icons
	local raidTarget = not icon.noRaidTarget and GetRaidTargetIndex(self.unit)
	if raidTarget then
		icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		icon:SetVertexColor(1, 1, 1, 1)
		SetRaidTargetIconTexture(icon, raidTarget)
		return icon:Show()
	end

	-- Check role
	local texture, x0, x1, y0, y1, r, g, b = GetRole(self.unit, icon.noDamager, icon.noCircle)
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

local icons

local function PlayerRoleUpdated()
	for icon in pairs(icons) do
		if UnitIsUnit(icon.__owner.unit or "none", "player") then
			Update(icon.__owner, 'PlayerRoleUpdated')
		end
	end
end


local function Enable(self)
	local icon = self.RoleIcon
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		if not icons then
			icons = { [icon] = true }
			ns.RegisterPlayerRoleCallback(PlayerRoleUpdated)
		else
			icons[icon] = true
		end
		self:RegisterEvent('PARTY_MEMBERS_CHANGED', Path)
		self:RegisterEvent("RAID_TARGET_UPDATE", Path)
		self:RegisterEvent('RAID_ROSTER_UPDATE', Path)
		self:RegisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)
		icon:Hide()
		return true
	end
end

local function Disable(self)
	local icon = self.RoleIcon
	if icon then
		icons[icon] = nil
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', Path)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Path)
		self:UnregisterEvent('LFG_ROLE_UPDATE', Path)
		self:UnregisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)
		icon:Hide()
	end
end

oUF:AddElement('RoleIcon', Path, Enable, Disable)


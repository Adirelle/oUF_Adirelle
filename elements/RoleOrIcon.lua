--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .RoleIcon
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local GetRaidRosterInfo = _G.GetRaidRosterInfo
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local IsInRaid = _G.IsInRaid
local GetTexCoordsForRoleSmall = _G.GetTexCoordsForRoleSmall
local GetTexCoordsForRoleSmallCircle = _G.GetTexCoordsForRoleSmallCircle
local select = _G.select
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitInRaid = _G.UnitInRaid
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsQuestBoss = _G.UnitIsQuestBoss
local UnitIsUnit = _G.UnitIsUnit
--GLOBALS>

local Debug = oUF_Adirelle.Debug
local GetPlayerRole = oUF_Adirelle.GetPlayerRole

local function GetRole(unit, noDamager, noCircle)
	if not UnitIsPlayer(unit) then return end

	-- Check assigned raid roles
	local raidId = IsInRaid() and UnitInRaid(unit)
	if raidId then
		local role = select(10, GetRaidRosterInfo(raidId))
		--Debug('Role from GetRaidRosterInfo for ', unit, ':', role)
		if role and role ~= "NONE" and (not noDamager or role ~= "DAMAGER") then
			return "Interface\\GroupFrame\\UI-Group-"..role.."Icon"
		end
	end

	-- Check assigned roles
	local role = UnitIsUnit(unit, "player") and GetPlayerRole() or UnitGroupRolesAssigned(unit)
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

local function OnPlayerRoleChanged(self, event)
	return Path(self, event, "player")
end

local function Enable(self)
	local icon = self.RoleIcon
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		self:RegisterMessage('OnPlayerRoleChanged', OnPlayerRoleChanged)
		self:RegisterEvent("RAID_TARGET_UPDATE", Path)
		self:RegisterEvent('LFG_ROLE_UPDATE', Path)
		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path)
		self:RegisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)
		self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', Path)
		icon:Hide()
		return true
	end
end

local function Disable(self)
	local icon = self.RoleIcon
	if icon then
		icon:Hide()
		self:UnregisterMessage('OnPlayerRoleChanged', OnPlayerRoleChanged)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Path)
		self:UnregisterEvent('LFG_ROLE_UPDATE', Path)
		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
		self:UnregisterEvent('PLAYER_ROLES_ASSIGNED', Path)
		self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)
		self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED', Path)
	end
end

oUF:AddElement('RoleIcon', Path, Enable, Disable)


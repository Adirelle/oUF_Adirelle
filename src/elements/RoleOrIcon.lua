--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Elements handled: .RoleIcon
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local GetRaidRosterInfo = assert(_G.GetRaidRosterInfo, "_G.GetRaidRosterInfo is undefined")
local GetRaidTargetIndex = assert(_G.GetRaidTargetIndex, "_G.GetRaidTargetIndex is undefined")
local GetTexCoordsForRoleSmall = assert(_G.GetTexCoordsForRoleSmall, "_G.GetTexCoordsForRoleSmall is undefined")
local GetTexCoordsForRoleSmallCircle = assert(_G.GetTexCoordsForRoleSmallCircle, "_G.GetTexCoordsForRoleSmallCircle is undefined")
local IsInRaid = assert(_G.IsInRaid, "_G.IsInRaid is undefined")
local select = assert(_G.select, "_G.select is undefined")
local SetRaidTargetIconTexture = assert(_G.SetRaidTargetIconTexture, "_G.SetRaidTargetIconTexture is undefined")
local UnitGroupRolesAssigned = assert(_G.UnitGroupRolesAssigned, "_G.UnitGroupRolesAssigned is undefined")
local UnitInRaid = assert(_G.UnitInRaid, "_G.UnitInRaid is undefined")
local UnitIsPlayer = assert(_G.UnitIsPlayer, "_G.UnitIsPlayer is undefined")
local UnitIsQuestBoss = assert(_G.UnitIsQuestBoss, "_G.UnitIsQuestBoss is undefined")
local UnitIsUnit = assert(_G.UnitIsUnit, "_G.UnitIsUnit is undefined")
--GLOBALS>

local GetPlayerRole = assert(oUF_Adirelle.GetPlayerRole)

local function AcceptAllRole(role)
	return role and role ~= "NONE"
end

local function AcceptNoDamager(role)
	return role ~= "DAMAGER" and AcceptAllRole(role)
end

local function GetUnitRole(unit, accept)
	-- Check assigned raid roles
	local raidId = IsInRaid() and UnitInRaid(unit)
	if raidId then
		local role = select(12, GetRaidRosterInfo(raidId))
		if accept(role) then
			return role, true
		end
	end
	local role = UnitGroupRolesAssigned(unit)
	if accept(role) then
		return role, false
	end
	if UnitIsUnit(unit, "player") then
		role = GetPlayerRole()
		return accept(role) and role, false
	end
	return
end

local function GetRoleTexture(unit, noDamager, noCircle)
	if not UnitIsPlayer(unit) then
		return
	end
	local role, inRaid = GetUnitRole(unit, noDamager and AcceptNoDamager or AcceptAllRole)
	if not role then
		return
	end
	if inRaid then
		return "Interface\\GroupFrame\\UI-Group-" .. role .. "Icon"
	end
	if noCircle then
		local x0, x1, y0, y1 = GetTexCoordsForRoleSmall(role)
		return [[Interface\LFGFrame\LFGRole_bw]], x0, x1, y0, y1, 1, 0.82, 0
	else
		return [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]], GetTexCoordsForRoleSmallCircle(role)
	end
end

local function Update(self, _, unit)
	if unit and unit ~= self.unit then
		return
	end
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
	local texture, x0, x1, y0, y1, r, g, b = GetRoleTexture(self.unit, icon.noDamager, icon.noCircle)
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
	return Path(element.__owner, "ForceUpdate")
end

local function OnPlayerRoleChanged(self, event)
	return Path(self, event, "player")
end

local function Enable(self)
	local icon = self.RoleIcon
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		self:RegisterMessage("OnPlayerRoleChanged", OnPlayerRoleChanged)
		self:RegisterEvent("RAID_TARGET_UPDATE", Path, true)
		self:RegisterEvent("LFG_ROLE_UPDATE", Path, true)
		self:RegisterEvent("GROUP_ROSTER_UPDATE", Path, true)
		self:RegisterEvent("PLAYER_ROLES_ASSIGNED", Path, true)
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Path)
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", Path, true)
		icon:Hide()
		return true
	end
end

local function Disable(self)
	local icon = self.RoleIcon
	if icon then
		icon:Hide()
		self:UnregisterMessage("OnPlayerRoleChanged", OnPlayerRoleChanged)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Path)
		self:UnregisterEvent("LFG_ROLE_UPDATE", Path)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", Path)
		self:UnregisterEvent("PLAYER_ROLES_ASSIGNED", Path)
		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", Path)
		self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED", Path)
	end
end

oUF:AddElement("RoleIcon", Path, Enable, Disable)

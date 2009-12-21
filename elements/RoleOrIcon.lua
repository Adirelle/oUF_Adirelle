--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .RoleIcon
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local GetRaidTargetIndex = GetRaidTargetIndex
local SetRaidTargetIconTexture = SetRaidTargetIconTexture
local GetRealNumRaidMembers = GetRealNumRaidMembers
local GetRealNumPartyMembers = GetRealNumPartyMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetNumRaidMembers = GetNumRaidMembers
local UnitInRaid = UnitInRaid
local UnitIsUnit = UnitIsUnit
local strmatch = string.match

local groupType

local GetGroupRole, RoleUpdated, Update
local lgt, lgtVer = LibStub('LibGroupTalents-1.0', true)
if lgt then
	oUF.Debug("RoleOrIcon using LibGroupTalents-1.0", lgtVer)
	function GetGroupRole(unit)
		local role = lgt:GetUnitRole(unit)
		return (role == 'caster' or role == 'melee') and "damage" or role
	end
	
	function RoleUpdated(self, event, guid, unit, ...)
		if unit == self.unit then
			oUF.Debug(self, event, guid, unit, ...)
			return Update(self, event, unit)
		end
	end
else
	oUF.Debug("RoleOrIcon using built-in UnitGroupRolesAssigned()")
	local UnitInParty, UnitGroupRolesAssigned = UnitInParty, UnitGroupRolesAssigned
	function GetGroupRole(unit)
		if groupType == "party" and UnitInParty(unit) then
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(unit)
			return (isTank and "tank") or (isHealer and "healer") or (isDamage and "damage")
		end
	end
end

local ROLE_ICON_INDEXES = {
--	damage = 1,
	tank = 2,
	healer = 3,
}

function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local icon = self.RoleIcon
	unit = self.unit
	
	-- Check raid target icons
	local raidTarget = GetRaidTargetIndex(unit)
	if raidTarget then
		icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
		icon:SetVertexColor(1, 1, 1, 1)
		SetRaidTargetIconTexture(icon, raidTarget)
		return icon:Show()
	end

	-- Only players may have a role in the group
	if UnitIsPlayer(unit) then

		-- Check assigned raid roles
		if groupType == "raid" and UnitInRaid(unit) then
			local index = tonumber(strmatch(unit, "raid(%d+)"))
			local role
			if index then
				role = select(10, GetRaidRosterInfo(index))
			else
				for index = 1, GetNumRaidMembers() do
					if UnitIsUnit('raid'..index, unit) then
						role = select(10, GetRaidRosterInfo(index))
						break
					end
				end
			end
			if role then
				if role == "MAINASSIST" then
					icon:SetTexture([[Interface\GroupFrame\UI-Group-MainAssistIcon]])
				elseif role == "MAINTANK" then
					icon:SetTexture([[Interface\GroupFrame\UI-Group-MainTankIcon]])
				end
				icon:SetTexCoord(0, 1, 0, 1)
				icon:SetVertexcolor(1, 1, 1, 1)
				return icon:Show()
			end
		end

		-- Check LFG role or LibGroupTalents roles
		if groupType ~= "solo" then
			local index = ROLE_ICON_INDEXES[GetGroupRole(unit) or "none"]
			if index then
				icon:SetTexture([[Interface\LFGFrame\LFGRole_BW]])
				icon:SetTexCoord((1+index*16)/64, (15+index*16)/64, 1/16, 15/16)
				icon:SetVertexColor(1, 0.82, 0, 1)
				return icon:Show()
			end
		end
		
	end

	-- Nothing to show
	return icon:Hide()
end

local function GetGroupType()
	if GetRealNumRaidMembers() > 0 then
		return "raid"
	elseif GetRealNumPartyMembers() > 0 then
		return "party"
	else
		return "solo"
	end
end

local function UpdateEvents(self, ...)
	local newGroupType = GetGroupType()
	if newGroupType ~= groupType then
		if groupType == "raid" then
			self:UnregisterEvent('RAID_ROSTER_UPDATE', Update)
		elseif groupType == "party" then
			if not lgt then
				self:UnregisterEvent('LFG_ROLE_UPDATE', Update)
			end
		end
		groupType = newGroupType
		if groupType == "raid" then
			self:RegisterEvent('RAID_ROSTER_UPDATE', Update)
		elseif groupType == "party" then
			if not lgt then
				self:RegisterEvent('LFG_ROLE_UPDATE', Update)
			end
		end
	end
	return Update(self, ...)
end

local function Enable(self)
	if self.RoleIcon then
		self:RegisterEvent('PARTY_MEMBERS_CHANGED', UpdateEvents)
		self:RegisterEvent("RAID_TARGET_UPDATE", Update)
		if lgt then
			lgt.RegisterCallback(self, 'LibGroupTalents_RoleChange', RoleUpdated, self)
		end
		self.RoleIcon:Hide()
		return true
	end
end

local function Disable(self)
	if self.RoleIcon then
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', UpdateEvents)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Update)
		self:UnregisterEvent('LFG_ROLE_UPDATE', Update)
		self:UnregisterEvent('RAID_ROSTER_UPDATE', Update)
		if lgt then
			lgt.UnregisterCallback(self, 'LibGroupTalents_RoleChange')
		end
		self.RoleIcon:Hide()
	end
end

oUF:AddElement('RoleIcon', UpdateEvents, Enable, Disable)


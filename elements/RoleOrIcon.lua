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
local InCombatLockdown = InCombatLockdown
local strmatch = string.match

local groupType

local GetGroupRole, RoleUpdated, Update
local lgt, lgtVer = LibStub('LibGroupTalents-1.0', true)
if lgt then
	oUF.Debug("Using LibGroupTalents-1.0", lgtVer)
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
	local UnitInParty, UnitGroupRolesAssigned = UnitInParty, UnitGroupRolesAssigned
	function GetGroupRole(unit)
		if groupType == "party" and UnitInParty(unit) then
			local isTank, isHealer, isDamage = UnitGroupRolesAssigned(unit)
			return (isTank and "tank") or (isHealer and "healer") or (isDamage and "damage")
		end
	end
end

function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local icon = self.RoleIcon
	local index = GetRaidTargetIndex(self.unit)	
	local texture, x0, x1, y0, y1, r, g, b = nil, 0, 1, 0, 1, 1, 1, 1
	
	if index then
		texture = [[Interface\TargetingFrame\UI-RaidTargetingIcons]]
		x0 = nil
		SetRaidTargetIconTexture(icon, index)		

	elseif groupType == "raid" and UnitInRaid(self.unit) then
		local index = tonumber(strmatch(self.unit, "raid(%d+)"))
		local role
		if index then
			role = select(10, GetRaidRosterInfo(index))
		else
			for index = 1, GetNumRaidMembers() do
				if UnitIsUnit('raid'..index, self.unit) then
					role = select(10, GetRaidRosterInfo(index))
					break
				end
			end
		end
		if role == "MAINASSIST" then
			texture = [[Interface\GroupFrame\UI-Group-MainAssistIcon]]
		elseif role == "MAINTANK" then
			texture = [[Interface\GroupFrame\UI-Group-MainTankIcon]]
		end

	--[[elseif event == 'PLAYER_REGEN_DISABLED' or InCombatLockdown() then
		-- NOOP]]

	else
		local role = GetGroupRole(self.unit)
		local num
		if role == "tank" then
			num,r,g,b = 2, 0.3, 1, 1
		elseif role == "healer" then
			num,r,g,b = 3, 1, 0.3, 0.3
		--[[elseif role == "damage" then
			num,r,g,b = 1, 1, 1, 0.3]]
		end
		if num then
			texture, x0, x1, y0, y1 = [[Interface\LFGFrame\LFGRole_BW]], (1+num*16)/64, (15+num*16)/64, 1/16, 15/16
		end
	end
	
	if texture then
		icon:SetTexture(texture)
		if x0 then
			icon:SetTexCoord(x0, x1, y0, y1)
		end
		icon:SetVertexColor(r, g, b)
		icon:Show()
	else
		icon:Hide()
	end
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
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Update)
		self:RegisterEvent('PLAYER_REGEN_DISABLED', Update)
		if lgt then
			lgt.RegisterCallback(self, 'LibGroupTalents_RoleChange', RoleUpdated)
		end
		
		self.RoleIcon:Hide()
		return true
	end
end

local function Disable(self)
	if self.RoleIcon then
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', UpdateEvents)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Update)
		self:UnregisterEvent('PLAYER_REGEN_DISABLED', Update)
		self:UnregisterEvent('LFG_ROLE_UPDATE', Update)
		self:UnregisterEvent('RAID_ROSTER_UPDATE', Update)				
		if lgt then		
			lgt.UnregisterCallback(self, 'LibGroupTalents_RoleChange')
		end
		self.RoleIcon:Hide()
	end
end

oUF:AddElement('RoleIcon', UpdateEvents, Enable, Disable)


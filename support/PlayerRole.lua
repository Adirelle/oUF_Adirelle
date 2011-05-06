--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local CreateFrame = _G.CreateFrame
local GetPrimaryTalentTree, GetTalentInfo, GetTalentTreeRoles = _G.GetPrimaryTalentTree, _G.GetTalentInfo, _G.GetTalentTreeRoles
local UnitClass, UnitGroupRolesAssigned, UnitSetRole = _G.UnitClass, _G.UnitGroupRolesAssigned, _G.UnitSetRole
local GetNumRaidMembers = _G.GetNumRaidMembers
local select, pairs, pcall, geterrorhandler = _G.select, _G.pairs, _G.pcall, _G.geterrorhandler

local Debug = oUF_Adirelle.Debug

local current
local inRaid

local function UpdatePlayerRole(event)
	local primaryTree = GetPrimaryTalentTree()
	if not primaryTree then return end
	local role
	if select(2, UnitClass("player")) == "DRUID" and primaryTree == 2 then
		-- Feral druid
		if select(5, GetTalentInfo(2, 20)) > 0 then -- Natural Reaction
			role = "TANK"
		else
			role = "DAMAGER"
		end
	else
		-- All others
		role = GetTalentTreeRoles(primaryTree)
	end
	if role and role ~= "NONE" then
		if role ~= current then
			Debug("Player role changed from", current, "to", role)
			oUF_Adirelle:SendMessage("OnPlayerRoleChanged", role)
		end
		if inRaid and UnitGroupRolesAssigned("player") ~= role then
			Debug("Setting raid role to", role, "on", event)
			UnitSetRole("player", role)
		end
	end
	return current
end

-- Event handling

local frame = CreateFrame("Frame")
frame:SetScript('OnEvent', function(self, event, ...) return self[event](self, event, ...) end)

function frame:PLAYER_ALIVE()
	-- Unregister and free this method
	self:UnregisterEvent('PLAYER_ALIVE')
	self.PLAYER_ALIVE = nil

	self:RegisterEvent('RAID_ROSTER_UPDATE')
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	return self:RAID_ROSTER_UPDATE()
end

function frame:RAID_ROSTER_UPDATE()
	local newInRaid = GetNumRaidMembers() > 0
	if newInRaid ~= inRaid then
		inRaid = newInRaid
		UpdatePlayerRole()
	end
end

frame.ACTIVE_TALENT_GROUP_CHANGED = UpdatePlayerRole
frame.PLAYER_REGEN_DISABLED = UpdatePlayerRole

if GetPrimaryTalentTree() then
	frame:PLAYER_ALIVE()
else
	frame:RegisterEvent('PLAYER_ALIVE')
end

-- "Public" API
function oUF_Adirelle.GetPlayerRole()
	return current or UpdatePlayerRole()
end


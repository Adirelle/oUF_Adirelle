--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local GetNumRaidMembers = _G.GetNumRaidMembers
local GetPrimaryTalentTree = _G.GetPrimaryTalentTree
local GetTalentInfo = _G.GetTalentInfo
local GetTalentTreeRoles = _G.GetTalentTreeRoles
local select = _G.select
local UnitClass = _G.UnitClass
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitSetRole = _G.UnitSetRole
--GLOBALS>

local Debug = oUF_Adirelle.Debug

local current
local inRaid

local function UpdatePlayerRole(event)
	local spec = GetSpecialization()
	if not spec then return end
	local role = GetSpecializationRole(spec)
	if role and role ~= "NONE" then
		if role ~= current then
			Debug("Player role changed from", current, "to", role)
			current = role
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

local function GROUP_ROSTER_UPDATE(self)
	local newInRaid = IsInRaid()
	if newInRaid ~= inRaid then
		inRaid = newInRaid
		UpdatePlayerRole()
	end
end

local function PLAYER_ALIVE(self)
	self:UnregisterEvent('PLAYER_ALIVE', PLAYER_ALIVE)
	PLAYER_ALIVE = nil

	self:RegisterEvent('GROUP_ROSTER_UPDATE', GROUP_ROSTER_UPDATE)
	self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', UpdatePlayerRole)
	self:RegisterEvent('PLAYER_REGEN_DISABLED', UpdatePlayerRole)
	return GROUP_ROSTER_UPDATE(self)
end

if GetSpecialization() then
	PLAYER_ALIVE(oUF_Adirelle)
else
	oUF_Adirelle:RegisterEvent('PLAYER_ALIVE', PLAYER_ALIVE)
end

-- "Public" API
function oUF_Adirelle.GetPlayerRole()
	return current or UpdatePlayerRole()
end


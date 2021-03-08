--[=[
Adirelle's oUF layout
(c) 2009-2016 Adirelle (adirelle@gmail.com)

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
--]=]

local _G = _G
local oUF_Adirelle = _G.oUF_Adirelle

local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitSetRole = _G.UnitSetRole
local GetSpecialization = _G.GetSpecialization
local GetSpecializationRole = _G.GetSpecializationRole
local IsInRaid = _G.IsInRaid

local Debug = oUF_Adirelle.Debug

local current
local inRaid

local function UpdatePlayerRole(event)
	local spec = GetSpecialization()
	if not spec then
		return
	end
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

local function GROUP_ROSTER_UPDATE()
	local newInRaid = IsInRaid()
	if newInRaid ~= inRaid then
		inRaid = newInRaid
		UpdatePlayerRole()
	end
end

local function PLAYER_ALIVE(self)
	self:UnregisterEvent("PLAYER_ALIVE", PLAYER_ALIVE)
	PLAYER_ALIVE = nil

	self:RegisterEvent("GROUP_ROSTER_UPDATE", GROUP_ROSTER_UPDATE)
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", UpdatePlayerRole)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", UpdatePlayerRole)
	return GROUP_ROSTER_UPDATE(self)
end

if GetSpecialization() then
	PLAYER_ALIVE(oUF_Adirelle)
else
	oUF_Adirelle:RegisterEvent("PLAYER_ALIVE", PLAYER_ALIVE)
end

-- "Public" API
function oUF_Adirelle.GetPlayerRole()
	return current or UpdatePlayerRole()
end

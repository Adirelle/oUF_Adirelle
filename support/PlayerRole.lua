--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local _G, parent, ns = _G, ...
setfenv(1, ns)

local current
local inRaid
local callbacks = {}

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
			oUF:Debug("Player role changed from", current, "to", role)
			current = role
			for callback in pairs(callbacks) do
				local ok, msg = pcall(callback, role)
				if not ok then geterrorhandler()(msg) end
			end
		end
		if inRaid and UnitGroupRolesAssigned("player") ~= role then
			oUF:Debug("Setting raid role to", role, "on", event)
			UnitSetRole("player", role)
		end
	end
	return current
end

function GetPlayerRole()
	return current or UpdatePlayerRole()
end

-- Register callbacks

function RegisterPlayerRoleCallback(callback)
	callbacks[callback] = true
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


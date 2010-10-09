--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local _G, parent, ns = _G, ...
setfenv(1, ns)

-- DOC:
-- talentGroup = GetActiveTalentGroup(inspect, pet)
-- talentTree = GetPrimaryTalentTree(inspect, pet, talentGroup)
-- role1, role2 = GetTalentTreeRoles(talentTree, inspect, pet)

function GetPlayerRole()
	local talentGroup = GetActiveTalentGroup(false,false)
	if not talentGroup then return end
	local primaryTree = GetPrimaryTalentTree(false, false, talentGroup)
	if not primaryTree then return end
	local role1, role2 = GetTalentTreeRoles(primaryTree, false, false)
	if role1 == "HEALER" or role2 == "HEALER" then
		return "healer"
	elseif role1 == "TANK" or role2 == "TANK" then
		return "tank"
	else
		return "melee"
	end
end

local frame, callbacks, current

local function OnEvent()
	local role = GetPlayerRole()
	if role ~= current then
		current = role
		for callback in pairs(callbacks) do
			pcall(callback)
		end
	end
end

function RegisterPlayerRoleCallback(callback)
	if not frame then
		frame, callbacks = CreateFrame("Frame"), {}
		frame:SetScript('OnEvent', OnEvent)
		frame:RegisterEvent("PLAYER_TALENT_UPDATE")
		frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		frame:RegisterEvent("PLAYER_ALIVE")
	end
	callbacks[callback] = true
end


--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local _G, parent, ns = _G, ...
setfenv(1, ns)

local GuessRole = GetLib('LibGuessRole-1.0')

local roleMap = {
	[GuessRole.ROLE_MELEE] = 'damager',
	[GuessRole.ROLE_CASTER] = 'damager',
	[GuessRole.ROLE_TANK] = 'tank',
	[GuessRole.ROLE_HEALER] = 'healer',
}
function GetPlayerRole() 
	return roleMap[GuessRole:GetUnitRole('player') or false] or "unknown"
end
function RegisterPlayerRoleCallback(callback)
	GuessRole.RegisterCallback(tostring(callback), "LibGuessRole_RoleChanged", function(event, guid)
		if UnitGUID("player") == guid then
			return callback()	
		end
	end)
end


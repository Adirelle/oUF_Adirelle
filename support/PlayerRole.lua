--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local _G, parent, ns = _G, ...
setfenv(1, ns)

-- Simple cases
if playerClass == "MAGE" or playerClass == "WARLOCK" or playerClass == "ROGUE" or playerClass == "HUNTER" then
	function GetPlayerRole() return "damager" end
	function RegisterPlayerRoleCallback() end
	return
end

-- If we have LibGroupTalents, use it
local GroupTalents = GetLib('LibGroupTalents-1.0')
if GroupTalents then
	local roleMap = { melee = 'damager', caster = 'damager', tank = 'tank', healer = 'healer' }
	function GetPlayerRole() 
		return roleMap[GroupTalents:GetUnitRole('player') or false] or "unknown"
	end
	function RegisterPlayerRoleCallback(callback)
		GroupTalents.RegisterCallback(tostring(callback), "LibGroupTalents_RoleChange", function(event, guid, unit, ...)
			if unit == "player" then return callback() end
		end)
	end
	return
end

--------------------------------------------------------------------------------
-- Home-made implementation
--------------------------------------------------------------------------------

-- Other case: the role depends on talents, so guess it and update when talents change
local currentRole = "unknown"
local callbacks = {}

-- "Public" API
function GetPlayerRole() return currentRole end
function RegisterPlayerRoleCallback(callback)	tinsert(callbacks, callback) end

local roleBySpec
-- Role can be guessed from main spec
if playerClass == "PALADIN" then
	roleBySpec = { "healer", "tank", "damager" }
elseif playerClass == "SHAMAN" then
	roleBySpec = { "damager", "damager", "healer" }
elseif playerClass == "PRIEST" then
	roleBySpec = { "healer", "healer", "damager" }
elseif playerClass == "WARRIOR" then
	roleBySpec = { "damager", "damager", "tank" }
else
	-- For druids and death knights we need to check some talents
	local function HasTalent(tab, index)
		local _, _, _, _, rank, maxRank = GetTalentInfo(tab, index)
		return rank and maxRank and rank == maxRank
	end
	
	if playerClass == "DRUID" then
		roleBySpec = {
			"damager",
			function()
				-- Consider feral as tank if she/he has Natural Reaction, Survival of the Fittest and Protector of the Pack
				return HasTalent(2, 16) and HasTalent(2, 18) and  HasTalent(2, 22) and "tank" or "damager"
			end,
			"healer",
		}
	elseif playerClass == "DEATHKNIGHT" then
		roleBySpec = function()
			-- Consider death knight as tank if she/he has at least two of the three tanking talents
			local num = (HasTalent(1,3) and 1 or 0) + (HasTalent(2,3) and 1 or 0) + (HasTalent(3,3) and 1 or 0)
			return num >= 2 and "tank" or "damager"
		end
	end
	
end

local GuessRole
if type(roleBySpec) == "function" then
	GuessRole = roleBySpec
else
	GuessRole = function()
		-- Guess the main spec
		local first = select(3, GetTalentTabInfo(1)) or 0
		local second = select(3, GetTalentTabInfo(2)) or 0
		local third = select(3, GetTalentTabInfo(3)) or 0
		local mainSpec
		if first > second and first > third then
			mainSpec = 1
		elseif second > first and second > third then
			mainSpec = 2
		elseif third > first and third > second then
			mainSpec = 3
		else
			Debug('Could not guess main spec', first, second, third)
			return "unknown"
		end
		
		-- Guess the role from main spec
		local role = roleBySpec[mainSpec]
		return type(role) == "function" and role() or role
	end
end

local function UpdateRole(self, event, ...)
	local role = GuessRole()
	if role == "unknown" then
		return false
	end
	if role ~= currentRole then
		local oldRole = currentRole
		currentRole = role
		Debug("UpdateRole", oldRole, '=>', role)
		for _, callback in pairs(callbacks) do
			local ok, msg = pcall(callback)
			if not ok then
				geterrorhandler()(msg)
			end
		end
	end
	return true
end

-- Wait for the first PLAYER_ALIVE event to update
-- Then update on every ACTIVE_TALENT_GROUP_CHANGED and PLAYER_TALENT_UPDATE
local frame = CreateFrame("Frame")
if not UpdateRole(self, "OnLoad") then
	frame:SetScript('OnEvent', function(self, event, ...)
		self:UnregisterEvent('PLAYER_ALIVE')
		self:SetScript('OnEvent', UpdateRole)
		return UpdateRole(self, event, ...)
	end)
	frame:RegisterEvent('PLAYER_ALIVE')
else
	frame:SetScript('OnEvent', UpdateRole)
end
frame:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
frame:RegisterEvent('PLAYER_TALENT_UPDATE')

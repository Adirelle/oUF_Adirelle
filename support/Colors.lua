--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local wipe, pairs, type = _G.wipe, _G.pairs, _G.type

-- Recolor mana
oUF.colors.power.MANA = { 0.3, 0.5, 1.0 }

if oUF_Adirelle.playerClass == "DEATHKNIGHT" then
	-- Rune colors
	oUF.colors.runes = {
		[1] = { 1.0, 0.0, 0.0 },
		[2] = { 0.0, 0.5, 0.0 },
		[3] = { 0.0, 1.0, 1.0 },
		[4] = { 0.8, 0.1, 1.0 },
	}
elseif oUF_Adirelle.playerClass == "SHAMAN" then
	-- Totem colors
	oUF.colors.totems = {
		[_G.FIRE_TOTEM_SLOT]  = { 1.0, 0.3, 0.0 },
		[_G.EARTH_TOTEM_SLOT] = { 0.3, 1.0, 0.2 },
		[_G.WATER_TOTEM_SLOT] = { 0.3, 0.2, 1.0 },
		[_G.AIR_TOTEM_SLOT]   = { 0.2, 0.8, 1.0 },	
	}
end

oUF.colors.incomingHeal = {
	self = { 0, 1, 0, 0.5 },
	others = { 0.5, 0, 1, 0.5 },
}

oUF.colors.lowHealth = { 1, 0, 0, 0.4 }

oUF.colors.outOfRange = { 0.4, 0.4, 0.4 }

oUF.colors.vehicle = {
	name = { 0.4, 0.8, 0.2 },
	background = { 0.2, 0.6, 0 },
}

oUF.colors.charmed = {
	name = { 1, 0.6, 0.3 },
	background =  { 1, 0, 0 },
}

local profile

local function DeepCopy(from, to, merge, defaults)
	if not merge then
		wipe(to)
	end
	for k, v in pairs(from) do
		if type(v) == "table" then
			if type(to[k]) ~= "table" then
				to[k] = {}
			end
			DeepCopy(v, to[k], merge, defaults and defaults[k])
		elseif defaults and defaults[k] == v then
			to[k] = nil
		else
			to[k] = v
		end
	end
end

local DEFAULTS

local function SaveColors()
	if not profile.colors then
		profile.colors = {}
	end
	DeepCopy(oUF.colors, profile.colors, false, DEFAULTS)
end
	
oUF_Adirelle.RegisterVariableLoadedCallback(function(_, newProfile, force, event)
	if not DEFAULTS then
		DEFAULTS = {}
		DeepCopy(oUF.colors, DEFAULTS)
		oUF_Adirelle.themeDB.RegisterCallback(addonName.."_colors", "OnDatabaseShutdown", SaveColors)
		oUF_Adirelle.themeDB.RegisterCallback(addonName.."_colors", "OnProfileShutdown", SaveColors)
	end
	if force or profile ~= newProfile then
		-- Update the upvalue
		profile = newProfile
		-- Copy the colors
		DeepCopy(profile.colors or DEFAULTS, oUF.colors, true)
	end
end)



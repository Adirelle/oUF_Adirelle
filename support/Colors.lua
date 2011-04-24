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

-- Rune colors
oUF.colors.runes = {
	[1] = { 1.0, 0.0, 0.0 },
	[2] = { 0.0, 0.5, 0.0 },
	[3] = { 0.0, 1.0, 1.0 },
	[4] = { 0.8, 0.1, 1.0 },
}

-- Totem colors
oUF.colors.totems = {
	[_G.FIRE_TOTEM_SLOT]  = { 1.0, 0.3, 0.0 },
	[_G.EARTH_TOTEM_SLOT] = { 0.3, 1.0, 0.2 },
	[_G.WATER_TOTEM_SLOT] = { 0.3, 0.2, 1.0 },
	[_G.AIR_TOTEM_SLOT]   = { 0.2, 0.8, 1.0 },	
}

oUF.colors.incomingHeal = {
	self = { 0, 1, 0, 0.5 },
	others = { 0.5, 0, 1, 0.5 },
}

oUF.colors.lowHealth = { 1, 0, 0, 0.4 }

local callbacks = {}
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

local DEFAULTS = {} 

local function SaveColors()
	if not profile.colors then
		profile.colors = {}
	end
	DeepCopy(oUF.colors, profile.colors, false, DEFAULTS)
end

function oUF_Adirelle.ColorsChanged()
	-- Update the frames	
	for frame, callback in pairs(callbacks) do
		if type(callback) == "string" then
			frame[callback](frame)
		else
			callback(frame)
		end
	end
end
	
oUF_Adirelle.RegisterVariableLoadedCallback(function(newProfile, first)
	if first then
		DeepCopy(oUF.colors, DEFAULTS)
		oUF_Adirelle.db.RegisterCallback(callbacks, "OnDatabaseShutdown", SaveColors)
		oUF_Adirelle.db.RegisterCallback(callbacks, "OnProfileShutdown", SaveColors)
	end
	
	-- Update the upvalue
	profile = newProfile

	-- Copy the colors
	DeepCopy(profile.colors or DEFAULTS, oUF.colors, true)
	
	return oUF_Adirelle.ColorsChanged()
end)

oUF:RegisterMetaFunction("RegisterColor", function(self, frame, func)
	callbacks[frame] = func
end)


--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

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

local addonName = ...

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local pairs = assert(_G.pairs, "_G.pairs is undefined")
local type = assert(_G.type, "_G.type is undefined")
local unpack = assert(_G.unpack, "_G.unpack is undefined")
local wipe = assert(_G.wipe, "_G.wipe is undefined")
--GLOBALS>

local Config = assert(oUF_Adirelle.Config)

-- Use the HCY color gradient by default
oUF.useHCYColorGradient = true

-- Recolor mana
oUF.colors.power.MANA = { 0.3, 0.5, 1.0 }

if oUF_Adirelle.playerClass == "DEATHKNIGHT" then
	-- Rune colors
	oUF.colors.runes = { 0.8, 0.1, 1 }
elseif oUF_Adirelle.playerClass == "SHAMAN" then
	-- Totem colors
	oUF.colors.totems = {
		[_G.FIRE_TOTEM_SLOT] = { 1.0, 0.3, 0.0 },
		[_G.EARTH_TOTEM_SLOT] = { 0.3, 1.0, 0.2 },
		[_G.WATER_TOTEM_SLOT] = { 0.3, 0.2, 1.0 },
		[_G.AIR_TOTEM_SLOT] = { 0.2, 0.8, 1.0 },
	}
end

oUF.colors.healthPrediction = {
	self = { 0, 1, 0, 0.5 },
	others = { 0, 0.6, 0, 0.5 },
	absorb = { 1, 1, 0.8, 0.5 },
	healAbsorb = { 0.5, 0, 0, 0.5 },
}

oUF.colors.lowHealth = { 1, 0, 0, 0.4 }

oUF.colors.vehicle = {
	name = { 0.4, 0.8, 0.2 },
	background = { 0.2, 0.6, 0 },
}

oUF.colors.charmed = {
	name = { 1, 0.6, 0.3 },
	background = { 1, 0, 0 },
}

oUF.colors.castbar = {
	failed = { 0.7, 0.0, 0.0 },
	notInterruptible = { 0.7, 0.7, 0.7 },
	channeling = { 0.0, 0.7, 1.0 },
	casting = { 1.0, 0.7, 0.0 },
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

oUF_Adirelle:RegisterMessage("OnSettingsModified", function(_, _, _, newProfile)
	if not DEFAULTS then
		DEFAULTS = {}
		DeepCopy(oUF.colors, DEFAULTS)
		oUF_Adirelle.themeDB.RegisterCallback(addonName .. "_colors", "OnDatabaseShutdown", SaveColors)
		oUF_Adirelle.themeDB.RegisterCallback(addonName .. "_colors", "OnProfileShutdown", SaveColors)
	end
	if profile ~= newProfile then
		-- Update the upvalue
		profile = newProfile
		-- Copy the colors
		DeepCopy(profile.colors or DEFAULTS, oUF.colors, true)
	end
end)

local function resolveColorKey(key)
	if type(key) == "table" then
		return oUF.colors[key[1]][key[2]]
	end
	return oUF.colors[key]
end

function Config:GetColor(key)
	local color = resolveColorKey(key)
	return unpack(color, 1, color[4] ~= nil and 4 or 3)
end

function Config:SetColor(key, r, g, b, a)
	local color = resolveColorKey(key)
	if color[1] == r and color[2] == g and color[3] == b and color[4] == a then
		return false
	end
	color[1], color[2], color[3], color[4] = r, g, b, a
	oUF_Adirelle:SendMessage("OnColorsModified", key)
	return true
end

oUF:RegisterMetaFunction("RegisterColor", function(self, target, key, callback)
	if not callback then
		callback = assert(
			target.SetColorTexture
				or target.SetStatusBarColor
				or target.SetTextColor
				or target.SetVertexColor
				or target.SetColor,
			"RegisterColor: either provide a callback or a target with either SetColorTexture, SetStatusBarColor, SetTextColor, SetVertexColor or SetColor"
		)
	end
	local function actualCallback(_, _, updatedKey)
		if updatedKey and updatedKey ~= key then
			return
		end
		callback(target, Config:GetColor(key))
		if target.ForceUpdate then
			target:ForceUpdate()
		elseif target.UpdateAllElements then
			target:UpdateAllElements()
		elseif target.__owner then
			target.__owner:UpdateAllElements()
		end
	end
	self:RegisterMessage("OnSettingsModified", actualCallback)
	self:RegisterMessage("OnColorsModified", actualCallback)
	actualCallback()
end)

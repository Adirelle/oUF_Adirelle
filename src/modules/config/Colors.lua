--[=[
Adirelle's oUF layout
(c) 2011-2021 Adirelle (adirelle@gmail.com)

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
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

local unpack = _G.unpack

local Config = oUF_Adirelle.Config

local function SetColor(info, r, g, b, a)
	info.arg[1], info.arg[2], info.arg[3] = r, g, b
	if info.option.hasAlpha then
		info.arg[4] = a
	end
	-- Update
end

local function GetColor(info)
	return unpack(info.arg, 1, info.option.hasAlpha and 4 or 3)
end

local labels = {
	power = _G,
	class = _G.LOCALIZED_CLASS_NAMES_MALE,
	healthPrediction = { self = "Self", others = "Others'", absorb = "Shields", healAbsorb = "Heal absorption" },
	selection = {
		[0] = "Hostile",
		[1] = "Unfriendly",
		[2] = "Neutral",
		[3] = "Friendly",
		[4] = "Player",
		[5] = "Player",
		[6] = "Party",
		[7] = "Party (War Mode On)",
		[8] = "Friend",
		[9] = "Dead",
		[10] = "Commentator Team 1",
		[11] = "Commentator Team 2",
		[12] = "Self",
		[13] = "Friendly (Battleground)",
	},
	threat = {
		[0] = "Low on threat",
		[1] = "Risk of taking aggro",
		[2] = "Risk of loosing aggro",
		[3] = "Tanking",
	},
}
-- "FACTION_STANDING_LABEL%d"

local function BuildSingleColor(name, color)
	return {
		name = name,
		type = "color",
		arg = color,
		hasAlpha = type(color[4]) == "number",
		get = GetColor,
		set = SetColor,
	}
end

-- Build a group of color options from a table of colors
local function BuildColorGroup(groupkey, name, colors)
	if not colors then
		return
	end
	local group = { name = name, type = "group", inline = true, args = {} }
	local thisLabels = labels[groupkey] or {}
	for key, color in pairs(colors) do
		local label = thisLabels[key]
		if not thisLabels or label then
			group.args[tostring(key)] = BuildSingleColor(label, color)
		end
	end
	return next(group.args) and group
end

-- Build a group of color options from a table of colors
local function BuildColorEntry(key, value)
	local arg
	if type(value[1]) == "number" then
		arg = BuildSingleColor("Color", value)
	else
		arg = BuildColorGroup(key, "Colors", value)
	end
	if arg then
		arg.order = 15
	end
	return arg
end

Config:RegisterBuilder(function(_, _, merge)
	for key, value in next, oUF.colors do
		local entry = BuildColorEntry(key, value)
		if entry then
			merge("theme", key, { color = entry })
		end
	end
end)

--[[
		-- The base color
		colorArgs = {
			reaction = BuildColorGroup("Reaction", oUF.colors.reaction, "FACTION_STANDING_LABEL%d"),

			health = BuildColorArg("Health", oUF.colors.health),
			disconnected = BuildColorArg("Disconnected player", oUF.colors.disconnected),
			tapped = BuildColorArg("Tapped mob", oUF.colors.tapped),
			outOfRange = BuildColorArg("Out of range", oUF.colors.outOfRange, true),
			lowHealth = BuildColorArg("Low health warning", oUF.colors.lowHealth, true),
			),
			group = {
				name = "Group member status",
				type = "group",
				inline = true,
				hidden = IsRaidStyleUnused,
				args = {
					vehicle = BuildColorGroup("In vehicle", oUF.colors.vehicle, { name = "Name", background = "Background" }),
					charmed = BuildColorGroup("Charmed", oUF.colors.charmed, { name = "Name", background = "Background" }),
				},
			},
		}

		-- Set up the conditions to show some color options
		colorArgs.reaction.hidden = function()
			return IsSingleStyleUnused()
				or not (themeDB.profile.Health.colorReaction or themeDB.profile.Power.colorReaction)
		end
		colorArgs.selection.hidden = function()
			return IsSingleStyleUnused() or not themeDB.profile.Health.colorSelection
		end
		colorArgs.threat.hidden = function()
			return IsSingleStyleUnused() or not themeDB.profile.Health.colorThreat
		end
		colorArgs.tapped.hidden = function()
			return IsSingleStyleUnused()
				or not (themeDB.profile.Health.colorTapping or themeDB.profile.Power.colorTapping)
		end
		colorArgs.power.hidden = function()
			return IsSingleStyleUnused() or not themeDB.profile.Power.colorPower
		end
		colorArgs.lowHealth.hidden = IsElementDisabled.LowHealth
		colorArgs.healthPrediction.hidden = IsElementDisabled.HealthPrediction
		colorArgs.outOfRange.hidden = IsElementDisabled.XRange

		-- Class-specific colors
		if oUF_Adirelle.playerClass == "DEATHKNIGHT" then
			local runes = BuildColorArg("Runes", oUF.colors.runes)
			runes.hidden = IsElementDisabled.RuneBar
			colorArgs.runes = runes
		elseif oUF_Adirelle.playerClass == "SHAMAN" then
			local totems = BuildColorGroup("Totems", oUF.colors.totems, {
				[_G.FIRE_TOTEM_SLOT] = "Fire",
				[_G.EARTH_TOTEM_SLOT] = "Earth",
				[_G.WATER_TOTEM_SLOT] = "Water",
				[_G.AIR_TOTEM_SLOT] = "Air",
			})
			totems.hidden = IsElementDisabled.TotemBar
			colorArgs.totems = totems
		end
--]]

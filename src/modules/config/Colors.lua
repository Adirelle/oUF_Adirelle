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

--<GLOBALS
local next = _G.next
local select = _G.select
local tostring = _G.tostring
local type = _G.type
--GLOBALS>

local Config = oUF_Adirelle.Config

local labels = {
	power = _G,
	class = _G.LOCALIZED_CLASS_NAMES_MALE,
	healthPrediction = {
		self = "Self",
		others = "Others'",
		absorb = "Shields",
		healAbsorb = "Heal absorption",
	},
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
	castbar = {
		failed = "Interrupted / failed",
		notInterruptible = "Not interruptible",
		channeling = "Channeling",
		casting = "Casting",
	},
	totems = {
		[_G.FIRE_TOTEM_SLOT] = "Fire",
		[_G.EARTH_TOTEM_SLOT] = "Earth",
		[_G.WATER_TOTEM_SLOT] = "Water",
		[_G.AIR_TOTEM_SLOT] = "Air",
	},
	border = {
		target = "Current target",
		focus = "Current focus",
		combat = "Combat flash",
		lowMana = "Low mana warning",
	},
}
-- "FACTION_STANDING_LABEL%d"

local relocate = {
	healthPrediction = "health",
	lowHealth = "health",
	smooth = "health",
	tapped = "misc",
	disconnected = "misc",
	selection = "misc",
	outOfRange = "misc",
	class = "info",
}

local function SetColor(info, r, g, b, a)
	return Config:SetColor(info.arg, r, g, b, a)
end

local function GetColor(info)
	return Config:GetColor(info.arg)
end

local function HasAlpha(info)
	return select(4, GetColor(info)) ~= nil
end

Config:RegisterBuilder(function(_, _, merge)

	local function addColor(path, key, name, colorKey)
		merge("theme", path, {
			colors = {
				name = "Colors",
				type = "group",
				inline = true,
				args = {
					[tostring(key)] = {
						name = Config:GetLabel(name),
						type = "color",
						arg = colorKey,
						hasAlpha = HasAlpha,
						get = GetColor,
						set = SetColor,
					},
				},
			},
		})
	end

	for key, value in next, oUF.colors do
		local path = relocate[key] or key
		if type(value[1]) == "number" then
			addColor(path, key, key, key)
		else
			local thisLabels = labels[key] or {}
			for subKey in next, value do
				local label = thisLabels[subKey]
				if label then
					addColor(path, subKey, label, { key, subKey })
				end
			end
		end
	end
end)

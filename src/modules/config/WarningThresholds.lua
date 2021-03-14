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

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)

--<GLOBALS
--GLOBALS>

local Config = assert(oUF_Adirelle.Config)
local SettingsModified = assert(oUF_Adirelle.SettingsModified)

Config:RegisterBuilder(function(_, _, merge)
	local themeDB = oUF_Adirelle.themeDB

	merge("theme", "health", {
		lowHealth = {
			name = "Low health threshold",
			type = "group",
			inline = true,
			order = -10,
			get = function(info)
				return themeDB.profile.LowHealth[info[#info]]
			end,
			set = function(info, value)
				themeDB.profile.LowHealth[info[#info]] = value
				SettingsModified("OnThemeModified")
			end,
			args = {
				isPercent = {
					name = "Percentage of max health",
					type = "toggle",
					order = 20,
				},
				percent = {
					name = "Threshold",
					type = "range",
					order = 30,
					isPercent = true,
					min = 0.05,
					max = 0.95,
					step = 0.01,
					bigStep = 0.05,
					hidden = function()
						return not themeDB.profile.LowHealth.isPercent
					end,
				},
				amount = {
					name = "Threshold",
					type = "range",
					order = 30,
					min = 1000,
					max = 200000,
					step = 100,
					bigStep = 1000,
					hidden = function()
						return themeDB.profile.LowHealth.isPercent
					end,
				},
			},
		},
	})

	merge("theme", "power", {
		lowMana = {
			name = "Low mana threshold",
			type = "group",
			inline = true,
			order = -10,
			get = function(info)
				return themeDB.profile.Border[info[#info]]
			end,
			set = function(info, value)
				themeDB.profile.Border[info[#info]] = value
				SettingsModified("OnThemeModified")
			end,
			args = {
				_manaDesc = {
					type = "description",
					order = 210,
					name = "These thresholds are used to display the blue border around units" .. " that are considered \"out of mana\".",
				},
				inCombatManaLevel = {
					name = "In combat",
					type = "range",
					order = 220,
					isPercent = true,
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.05,
				},
				oocInRaidManaLevel = {
					name = "Out of combat in raid instances",
					type = "range",
					order = 230,
					isPercent = true,
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.05,
				},
				oocManaLevel = {
					name = "Out of combat",
					type = "range",
					order = 240,
					isPercent = true,
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.05,
				},
			},
		},
	})
end)

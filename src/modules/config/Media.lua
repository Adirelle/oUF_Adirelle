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
local oUF_Adirelle = _G.oUF_Adirelle

local next = _G.next

local Config = oUF_Adirelle.Config
local themeDB = oUF_Adirelle.themeDB

local SharedMedia = oUF_Adirelle.GetLib("LibSharedMedia-3.0")
local FONT = SharedMedia.MediaType.FONT
local STATUSBAR = SharedMedia.MediaType.STATUSBAR

local function GetFontValues()
	return SharedMedia:HashTable(FONT)
end

Config:RegisterBuilder(function(self, _, merge)
	for key in next, self.fonts do
		local key = key -- luacheck: ignore
		merge("theme", key, {
			font = {
				name = "Text",
				type = "group",
				order = 20,
				inline = true,
				get = function(info)
					return themeDB.profile.fonts[key][info[#info]]
				end,
				set = function(info, value)
					if themeDB.profile.fonts[key][info[#info]] ~= value then
						themeDB.profile.fonts[key][info[#info]] = value
						oUF_Adirelle:SendMessage("SetFont", key)
					end
				end,
				args = {
					name = {
						name = "Font",
						type = "select",
						dialogControl = "LSM30_Font",
						values = GetFontValues,
						width = "double",
						order = 10,
					},
					scale = {
						name = "Scale",
						type = "range",
						isPercent = true,
						min = 0.05,
						max = 2.0,
						step = 0.05,
						order = 20,
					},
					flags = {
						name = "Outline",
						type = "select",
						values = {
							[""] = "None",
							["DEFAULT"] = "Default",
							["OUTLINE"] = "Thin",
							["THICKOUTLINE"] = "Thick",
						},
						order = 30,
					},
				},
			},
		})
	end
end)

local function GetStatusBarValues()
	return SharedMedia:HashTable(STATUSBAR)
end

Config:RegisterBuilder(function(self, _, merge)
	for key in next, self.statusBars do
		local key = key -- luacheck: ignore
		merge("theme", key, {
			statusbar = {
				name = "Texture",
				type = "select",
				order = 10,
				dialogControl = "LSM30_Statusbar",
				values = GetStatusBarValues,
				get = function()
					return themeDB.profile.statusBars[key]
				end,
				set = function(_, value)
					if value ~= themeDB.profile.statusBars[key] then
						themeDB.profile.statusBars[key] = value
						oUF_Adirelle:SendMessage("SetStatusBar", key)
					end
				end,
			},
		})
	end
end)

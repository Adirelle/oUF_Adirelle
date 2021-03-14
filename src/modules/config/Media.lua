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
local next = assert(_G.next)
--GLOBALS>

local Config = assert(oUF_Adirelle.Config)
local themeDB = assert(oUF_Adirelle.themeDB)

local SharedMedia = oUF_Adirelle.GetLib("LibSharedMedia-3.0")
local FONT = assert(SharedMedia.MediaType.FONT)
local STATUSBAR = assert(SharedMedia.MediaType.STATUSBAR)

local relocate = {
	raid = "info",
	name = "info",
	nameplate = "info",
	level = "info",
	soul_shards = "power",
}

local function GetFontValues()
	return SharedMedia:HashTable(FONT)
end

local function BuildFontGroup(key, label)
	return {
		[key .. "Font"] = {
			name = label and Config:GetLabel(label) or "Text",
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
	}
end

Config:RegisterBuilder(function(self, _, merge)
	for key in next, self.fonts do
		local path, label = relocate[key] or key, relocate[key] and key
		merge("theme", path, BuildFontGroup(key, label))
	end
end)

local function GetStatusBarValues()
	return SharedMedia:HashTable(STATUSBAR)
end

local function BuildStatusBarSelector(key, label)
	return {
		[key .. "StatusBar"] = {
			name = label and Config:GetLabel(label) or "Texture",
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
	}
end

Config:RegisterBuilder(function(self, _, merge)
	for key in next, self.statusBars do
		local path, label = relocate[key] or key, relocate[key] and key
		merge("theme", path, BuildStatusBarSelector(key, label))
	end
end)

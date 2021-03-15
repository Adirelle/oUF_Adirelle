--[=[
Adirelle's oUF layout
(c) 2021 Adirelle (adirelle@gmail.com)

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
local format = assert(_G.format)
local table = assert(_G.table)
local tinsert = assert(_G.tinsert)
--GLOBALS>

local Config = assert(oUF_Adirelle.Config)

Config:RegisterBuilder(function(_, _, merge)
	local libs = {}
	for major, minor in oUF_Adirelle:ListLibraries() do
		tinsert(libs, format("%s.%s", major, minor))
	end
	table.sort(libs)

	merge({
		about = {
			name = "About",
			type = "group",
			cmdHidden = true,
			order = -1,
			args = {
				_oufa = {
					name = "oUF_Adirelle",
					type = "header",
					order = 0,
				},
				version = {
					name = "Version: " .. oUF_Adirelle.VERSION,
					type = "description",
					width = "full",
					order = 10,
				},
				sources = {
					name = "Sources:",
					type = "input",
					width = "full",
					get = function()
						return "https://github.com/Adirelle/oUF_Adirelle"
					end,
					order = 12,
				},
				issues = {
					name = "Please report issues to:",
					type = "input",
					width = "full",
					get = function()
						return "https://github.com/Adirelle/oUF_Adirelle/issues"
					end,
					order = 14,
				},
				_libs = {
					name = "Libraries",
					type = "header",
					order = 20,
				},
				libraries = {
					name = table.concat(libs, "\n"),
					type = "description",
					width = "full",
					order = 30,
				},
			},
		},
	})
end)

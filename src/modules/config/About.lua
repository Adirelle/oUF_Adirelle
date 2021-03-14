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
local table = assert(_G.table)
local tinsert = assert(_G.tinsert)
--GLOBALS>

local Config = assert(oUF_Adirelle.Config)

Config:RegisterBuilder(function(_, _, merge)
	local libs = {}
	for major, minor in oUF_Adirelle:ListLibraries() do
		tinsert(libs, major .. " " .. minor)
	end
	table.sort(libs)

	merge({
		about = {
			name = "About",
			type = "group",
			order = -1,
			args = {
				oufa = {
					name = "oUF_Adirelle " .. oUF_Adirelle.VERSION,
					type = "description",
					width = "full",
					order = 0,
				},
				libraries = {
					name = table.concat(libs, "\n"),
					type = "description",
					width = "full",
					order = 10,
				},
			},
		},
	})
end)

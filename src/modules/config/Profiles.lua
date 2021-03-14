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

--<GLOBALS
local LibStub = _G.LibStub
--GLOBALS>

local ADO = LibStub("AceDBOptions-3.0")
local LDS = LibStub("LibDualSpec-1.0")

local Config = oUF_Adirelle.Config

local function BuildProfileOption(db)
	local options = ADO:GetOptionsTable(db)
	LDS:EnhanceOptions(options, db)
	options.order = -1
	return options
end

-- Create the profile options of the layout
local layoutDBOptions = BuildProfileOption(oUF_Adirelle.layoutDB)
layoutDBOptions.disabled = Config.IsLockedDown

local themeDBOptions = BuildProfileOption(oUF_Adirelle.themeDB)

-- Create the profile options of the theme

Config:RegisterBuilder(function(_, _, merge)
	merge("layout", { profiles = layoutDBOptions })
	merge("theme", { profiles = themeDBOptions })
end)

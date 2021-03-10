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

local LibStub = _G.LibStub
local tinsert = _G.tinsert
local xpcall = _G.xpcall
local geterrorhandler = _G.geterrorhandler

local Config = oUF_Adirelle.Config

local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

local Build
do
	local builders = {}

	function Build()
		local opts = {
			name = "oUF_Adirelle " .. oUF_Adirelle.VERSION,
			type = "group",
			childGroups = "tab",
			args = {},
		}

		local function merge(newOpts)
			opts.args = newOpts
		end

		local eh = geterrorhandler()
		for _, builder in next, builders do
			xpcall(function()
				builder(Config, opts.args, merge)
			end, eh)
		end
		return opts
	end

	function Config:RegisterBuilder(builder)
		tinsert(builders, builder)
	end
end

local function Update()
	ACR:NotifyChange("oUF_Adirelle")
end

oUF_Adirelle:RegisterEvent("PLAYER_REGEN_DISABLED", Update)
oUF_Adirelle:RegisterEvent("PLAYER_REGEN_ENABLED", Update)

do
	local options

	local function GetOptions()
		if not options then
			options = Build()
		end
		return options
	end

	function Config:Reset()
		options = nil
		Update()
	end

	AC:RegisterOptionsTable("oUF_Adirelle", GetOptions)
end

function Config:Open(...)
	ACD:SelectGroup("oUF_Adirelle", ...)
	ACD:Open("oUF_Adirelle")
end

function Config:Close()
	return ACD:Close("oUF_Adirelle")
end

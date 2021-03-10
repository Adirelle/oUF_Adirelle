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

local geterrorhandler = _G.geterrorhandler
local LibStub = _G.LibStub
local strformat = _G.strformat
local tinsert = _G.tinsert
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitName = _G.UnitName
local xpcall = _G.xpcall

local Config = oUF_Adirelle.Config

local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

Config.playerName = UnitName("player")

function Config:SettingsModified(...)
	return oUF_Adirelle.SettingsModified(...)
end

function Config:IsLockedDown()
	return UnitAffectingCombat("player")
end

local Build
do
	local builders = {}

	local labels = {
		health = "Health bar",
		power = "Power bar",
		altpower = "Special resources",
		soul_shards = "Soul shards",
		threat = "Threat bar",
		xp = "Experience bar",
		castbar = "Casting bar",
		nameplate = "Nameplate",
		raid = "Teammate name",
		name = "Unit name",
		number = "Amount",
		level = "Character level",
		stack = "(De)buff stacks",
		timer = "timer",
	}

	local function MergeArgs(path, target, source)
		for key, value in next, source do
			local thisPath = path .. "." .. key
			if target[key] then
				if target[key].type == "group" and value.type == "group" then
					oUF_Adirelle:Debug("Merge groups", thisPath)
					target[key].args = MergeArgs(thisPath, target[key].args, value.args)
				else
					error(strformat(
						"MergeArgs: [%s] cannot overwrite %s with %",
						thisPath,
						target[key].type,
						value.type
					))
				end
			else
				oUF_Adirelle:Debug("Set", value.type, thisPath)
				target[key] = value
			end
		end
		return target
	end

	local function MergeIn(path, target, item, ...)
		if type(item) == "table" then
			return MergeArgs(path, target, item)
		end
		if type(item) ~= "string" then
			error(
				"MergeIn: [" .. path .. "]: expected item to be a table or a string, got a " .. type(item)
			)
		end
		path = path .. "." .. item
		if not target[item] then
			oUF_Adirelle:Debug("Create group", path)
			target[item] = { name = labels[item] or item, type = "group", args = {} }
		elseif target[item].type ~= "group" then
			error("MergeIn: [" .. path .. "]: expected a group, got a ", target[item].type)
		end
		target[item].args = MergeIn(path, target[item].args, ...)
		return target
	end

	function Build()
		local opts = {}

		local function merge(...)
			opts = MergeIn("", opts, ...)
		end

		local eh = geterrorhandler()
		for _, builder in next, builders do
			xpcall(function()
				builder(Config, opts, merge)
			end, eh)
		end

		return {
			name = "oUF_Adirelle " .. oUF_Adirelle.VERSION,
			type = "group",
			childGroups = "tab",
			args = opts,
		}
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

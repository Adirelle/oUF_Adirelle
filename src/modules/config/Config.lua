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
local error = assert(_G.error)
local format = assert(_G.format)
local geterrorhandler = assert(_G.geterrorhandler)
local next = assert(_G.next)
local tinsert = assert(_G.tinsert)
local type = assert(_G.type)
local UnitAffectingCombat = assert(_G.UnitAffectingCombat)
local UnitName = assert(_G.UnitName)
local xpcall = assert(_G.xpcall)
--GLOBALS>

local Config = assert(oUF_Adirelle.Config)

local AC = oUF_Adirelle.GetLib("AceConfig-3.0")
local ACD = oUF_Adirelle.GetLib("AceConfigDialog-3.0")
local ACR = oUF_Adirelle.GetLib("AceConfigRegistry-3.0")

Config.playerName = UnitName("player")

function Config:SettingsModified(...)
	return oUF_Adirelle.SettingsModified(...)
end

function Config:IsLockedDown()
	return UnitAffectingCombat("player")
end

local labels = {
	altpower = "Special resources",
	border = "Frame border",
	castbar = "Casting bar",
	class = "Class colors",
	disconnected = "Disconnected player",
	health = "Health",
	healthPrediction = "Health prediction",
	level = "Level & class/kind",
	lowHealth = "Low health",
	misc = "Miscellanous",
	name = "Name (unit)",
	nameplate = "Name (nameplate)",
	outOfRange = "Range fading",
	selection = "Selection color",
	power = "Power",
	raid = "Name (group)",
	soul_shards = "Soul shards",
	stack = "(De)buff stacks",
	tapped = "Tapped mob",
	threat = "Threat",
	pvptimer = "PvP Timer",
	xp = "Experience",
	smooth = "Gradient low end",
	info = "Character infomartion",
}

local function humanize(text)
	text = text:gsub("(%l)(%u)", function(a, b)
		return a .. " " .. b:lower()
	end)
	return text:sub(0, 1):upper() .. text:sub(2)
end

function Config:GetLabel(text)
	return labels[text] or humanize(text)
end

local function MaxOrder(entries)
	local order = 0
	for _, entry in next, entries do
		if entry.order and entry.order > order then
			order = entry.order
		end
	end
	return order
end

local function AddGroup(target, item)
	target[item] = {
		name = Config:GetLabel(item),
		type = "group",
		order = MaxOrder(target) + 10,
		args = {},
	}
end

local function MergeArgs(path, target, source)
	for key, value in next, source do
		local thisPath = path .. "." .. key
		if not value.order then
			value.order = MaxOrder(target) + 10
		end
		if target[key] then
			if target[key].type == "group" and value.type == "group" then
				oUF_Adirelle:Debug("Merge groups", thisPath)
				target[key].args = MergeArgs(thisPath, target[key].args, value.args)
			else
				error(format(
					"MergeArgs: [%s] option already exists with type %q, cannot replace it (new type: %q)",
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
	if not item then
		return target
	end
	if type(item) == "table" then
		target = MergeArgs(path, target, item)
		return MergeIn(path, target, ...)
	end
	if type(item) ~= "string" then
		error(format(
			"MergeIn: %q: expected item to be a table or a string, got a %s",
			path,
			type(item)
		))
	end
	path = path .. "." .. item
	if not target[item] then
		AddGroup(target, item)
	elseif target[item].type ~= "group" then
		error("MergeIn: [" .. path .. "]: expected a group, got a ", target[item].type)
	end
	target[item].args = MergeIn(path, target[item].args, ...)
	return target
end

local Build
do
	local builders = {}

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

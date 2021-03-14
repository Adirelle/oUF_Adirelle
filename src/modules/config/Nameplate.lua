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
local Config = oUF_Adirelle.Config

--<GLOBALS
local C_CVar = _G.C_CVar
local IsAddOnLoaded = _G.IsAddOnLoaded
local setmetatable = _G.setmetatable
local tonumber = _G.tonumber
local tostring = _G.tostring
--GLOBALS>

local labels = {
	nameplateShowAll = "Show out of combat",
	nameplateMotion = "Layout type",
	nameplateOverlapV = "Vertical spacing",
	nameplateOverlapH = "Horizontal spacing",
	nameplateOccludedAlphaMult = "Out of sight alpha",
	nameplateTargetRadialPosition = "Clamp to screen",
}

local descs = {}

local function GetLabel(key)
	if labels[key] then
		return labels[key]
	end
	local cleanKey = key:gsub("[nN]ame[pP]late", ""):gsub("Friendly", ""):gsub("Enemy", ""):gsub("Personal", "")
	return Config:GetLabel(cleanKey)
end

local order = 0

local accessorMeta = {
	__index = {
		get = function(info)
			if info.type == "toggle" then
				return C_CVar.GetCVarBool(info.arg)
			elseif info.type == "range" then
				return tonumber(C_CVar.GetCVar(info.arg))
			else
				return C_CVar.GetCVar(info.arg)
			end
		end,
		set = function(info, value)
			if info.type == "toggle" then
				value = value and "1" or "0"
			else
				value = value and tostring(value) or nil
			end
			if value == C_CVar.GetCVar(info.arg) then
				return
			end
			C_CVar.SetCVar(info.arg, value)
			oUF_Adirelle.layoutDB.profile.nameplates.cvars[info.arg] = value
		end,
	},
}

local function OptionBuilder(prototype, constructor)
	return function(key, ...)
		order = order + 10
		local option = {
			name = GetLabel(key),
			desc = descs[key],
			arg = key,
			order = order,
		}
		setmetatable(option, { __index = setmetatable(prototype, accessorMeta) })
		if constructor then
			constructor(option, key, ...)
		end
		return { [key] = option }
	end
end

local Toggle = OptionBuilder({ type = "toggle" })
local Delay = OptionBuilder({ type = "range", min = 0.5, max = 10.0, step = 0.5 })
local Alpha = OptionBuilder({ type = "range", isPercent = true, min = 0.0, max = 1.0, step = 0.05 })
local Percent = OptionBuilder({ type = "range", isPercent = true, min = 0.0, max = 1.0, step = 0.05 })
local Scale = OptionBuilder({ type = "range", isPercent = true, min = 0.1, max = 3.0, step = 0.05 })
local Distance = OptionBuilder({ type = "range", min = 0, max = 100, step = 5 })
local Select = OptionBuilder({ type = "select" }, function(option, _, values)
	option.values = values
end)

local DisabledIfNot = function(key)
	return function(info)
		return info.type ~= "group" and info.arg ~= key and not C_CVar.GetCVarBool(key)
	end
end

Config:RegisterBuilder(function(_, options, merge)

	merge({
		nameplates = {
			name = "Nameplates",
			hidden = function()
				return not IsAddOnLoaded("oUF_Adirelle_Nameplates")
			end,
			type = "group",
			order = 40,
			args = {
				__disclaimer = {
					name = "These options are handled by the Blizzard nameplate engine. They are listed here for convenience.",
					order = 0,
					type = "description",
				},
			},
		},
	})

	order = 0
	merge(
		"nameplates",
		"general",
		Toggle("nameplateShowAll"),
		Select("nameplateMotion", {
			["0"] = "Overlapping",
			["1"] = "Stacking",
			["2"] = "Spreading",
		}),
		Distance("nameplateMaxDistance"),
		Percent("nameplateMotionSpeed"),
		Percent("nameplateOverlapV"),
		Percent("nameplateOverlapH"),
		Select("nameplateTargetRadialPosition", {
			["0"] = "None",
			["1"] = "Target only",
			["2"] = "All",
		}),
		Distance("nameplateTargetBehindMaxDistance"),
		Toggle("nameplateResourceOnTarget")
	)

	order = 0
	merge(
		"nameplates",
		"self",
		Toggle("nameplateShowSelf"),
		Select("NameplatePersonalShowWithTarget", {
			["0"] = "Ignore target",
			["1"] = "Hostile target",
			["2"] = "Any target",
		}),
		Toggle("NameplatePersonalShowInCombat"),
		Toggle("NameplatePersonalShowAlways"),
		Toggle("NameplatePersonalClickThrough"),
		Alpha("nameplateSelfAlpha"),
		Scale("nameplateSelfScale"),
		Delay("NameplatePersonalHideDelaySeconds"),
		Alpha("NameplatePersonalHideDelayAlpha")
	)

	order = 0
	merge(
		"nameplates",
		"friends",
		Toggle("nameplateShowFriends"),
		Toggle("nameplateShowFriendlyGuardians"),
		Toggle("nameplateShowFriendlyMinions"),
		Toggle("nameplateShowFriendlyNPCs"),
		Toggle("nameplateShowFriendlyPets"),
		Toggle("nameplateShowFriendlyTotems")
	)

	order = 0
	merge(
		"nameplates",
		"enemies",
		Toggle("nameplateShowEnemies"),
		Toggle("nameplateShowEnemyGuardians"),
		Toggle("nameplateShowEnemyMinions"),
		Toggle("nameplateShowEnemyMinus"),
		Toggle("nameplateShowEnemyPets"),
		Toggle("nameplateShowEnemyTotems")
	)

	order = 0
	merge(
		"nameplates",
		"alpha",
		Alpha("nameplateOccludedAlphaMult"),
		Alpha("nameplateSelectedAlpha"),
		Distance("nameplateMaxAlphaDistance"),
		Alpha("nameplateMaxAlpha"),
		Distance("nameplateMinAlphaDistance"),
		Alpha("nameplateMinAlpha")
	)

	order = 0
	merge(
		"nameplates",
		"scale",
		Scale("nameplateGlobalScale"),
		Scale("nameplateSelectedScale"),
		Scale("nameplateLargerScale"),
		Distance("nameplateMaxScaleDistance"),
		Scale("nameplateMaxScale"),
		Distance("nameplateMinScaleDistance"),
		Scale("nameplateMinScale")
	)

	options.nameplates.args.self.disabled = DisabledIfNot("nameplateShowSelf")
	options.nameplates.args.friends.disabled = DisabledIfNot("nameplateShowFriends")
	options.nameplates.args.enemies.disabled = DisabledIfNot("nameplateShowEnemies")
end)

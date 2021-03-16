--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

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

local moduleName, private = ...

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local DebuffTypeColor = assert(_G.DebuffTypeColor, "_G.DebuffTypeColor is undefined")
local debugstack = assert(_G.debugstack, "_G.debugstack is undefined")
local format = assert(_G.format, "_G.format is undefined")
local geterrorhandler = assert(_G.geterrorhandler, "_G.geterrorhandler is undefined")
local GetSpellInfo = assert(_G.GetSpellInfo, "_G.GetSpellInfo is undefined")
local select = assert(_G.select, "_G.select is undefined")
local strjoin = assert(_G.strjoin, "_G.strjoin is undefined")
local tostringall = assert(_G.tostringall, "_G.tostringall is undefined")
local tostring = assert(_G.tostring, "_G.tostring is undefined")
local type = assert(_G.type, "_G.type is undefined")
local UnitCanAssist = assert(_G.UnitCanAssist, "_G.UnitCanAssist is undefined")
local UnitClass = assert(_G.UnitClass, "_G.UnitClass is undefined")
local UnitIsUnit = assert(_G.UnitIsUnit, "_G.UnitIsUnit is undefined")
--GLOBALS>

local FindAuraByName = assert(_G.AuraUtil.FindAuraByName)

-- ------------------------------------------------------------------------------
-- Helper
-- ------------------------------------------------------------------------------

local function IsMeOrMine(caster)
	return caster and (UnitIsUnit("player", caster) or UnitIsUnit("pet", caster) or UnitIsUnit("vehicle", caster))
end

-- ------------------------------------------------------------------------------
-- Filter factories
-- ------------------------------------------------------------------------------

local reported
local function GetSpellName(caller, spellId, ...)
	local spellName = GetSpellInfo(spellId)
	if not spellName then
		local k = strjoin("-", tostringall(caller, spellId, ...))
		if not reported then
			reported = {}
		elseif reported[k] then
			return
		end
		local stack = debugstack(3):match("[^%.\\]+%.lua:%d+")
		geterrorhandler()(format(
			[[
				[%s] Wrong spell id passed to %s.
				Please report this whole error.
				id=%d, class=%s, version=%s, params=[%s], source=%s
			]],
			moduleName,
			caller,
			spellId,
			select(2, UnitClass("player")),
			oUF_Adirelle.VERSION,
			strjoin(",", tostringall(...)),
			stack
		))
		reported[k] = true
	end
	return spellName
end

local function GetGenericFilter(...)
	local name = strjoin("-", tostringall(...))
	return name, oUF:HasAuraFilter(name)
end

function private.GetOwnAuraFilter(spellId, r, g, b)
	local spellName = GetSpellName("GetOwnAuraFilter", spellId, r, g, b)
	if not spellName then
		return "none"
	end
	local filterName, exists = GetGenericFilter("OwnAura", spellName, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filterName, function(unit)
			local name, texture, count, _, duration, expirationTime = FindAuraByName(spellName, unit, "PLAYER")
			if name then
				return texture, count, expirationTime - duration, duration, r, g, b
			end
		end)
	end
	return filterName
end

function private.GetAnyAuraFilter(spellId, filter, r, g, b)
	local spellName = GetSpellName("GetAnyAuraFilter", spellId, filter, r, g, b)
	if not spellName then
		return "none"
	end
	local filterName, exists = GetGenericFilter("AnyAura", spellName, filter, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filterName, function(unit)
			local name, texture, count, _, duration, expirationTime = FindAuraByName(spellName, unit, filter)
			if name then
				return texture, count, expirationTime - duration, duration, r, g, b
			end
		end)
	end
	return filterName
end

function private.GetOwnStackedAuraFilter(spellId, countThreshold, r, g, b)
	local spellName = GetSpellName("GetOwnStackedAuraFilter", spellId, countThreshold, r, g, b)
	if not spellName then
		return "none"
	end
	assert(type(countThreshold) == "number", "invalid count threshold: " .. tostring(countThreshold))
	local filter, exists = GetGenericFilter("OwnStackedAura", spellName, countThreshold, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filter, function(unit)
			local name, texture, count, _, duration, expirationTime, caster = FindAuraByName(spellName, unit)
			if name and IsMeOrMine(caster) and count >= countThreshold then
				return texture, 1, expirationTime - duration, duration, r, g, b
			end
		end)
	end
	return filter
end

-- ------------------------------------------------------------------------------
-- Cureable debuff filter
-- ------------------------------------------------------------------------------

local IsEncounterDebuff = oUF_Adirelle.IsEncounterDebuff
local IterateDispellableDebuffs = oUF_Adirelle.IterateDispellableDebuffs

oUF:AddAuraFilter("CureableDebuff", function(unit)
	if not UnitCanAssist("player", unit) then
		return
	end
	local priority, count, expirationTime = 1, 0, 0
	local texture, debuffType, duration
	for _, canDispel, thisTexture, thisCount, thisDebuffType, thisDuration, thisExpirationTime, _, spellID, isBossDebuff in IterateDispellableDebuffs(unit) do -- luacheck: no max line length
		local thisPriority
		if isBossDebuff then
			thisPriority = 50
		elseif IsEncounterDebuff(spellID) then
			thisPriority = 40
		else
			thisPriority = 30
		end
		if canDispel then
			thisPriority = thisPriority + 50
		end
		if thisCount and thisCount > 1 then
			thisPriority = thisPriority + thisCount - 1
		end
		if thisDuration and thisDuration ~= 0 then
			thisPriority = thisPriority + thisDuration / 10
		end

		if not texture or thisPriority > priority then
			priority, texture, count, debuffType, duration, expirationTime = thisPriority, thisTexture, thisCount, thisDebuffType, thisDuration, thisExpirationTime -- luacheck: no max line length
		end
	end
	if texture then
		local color = DebuffTypeColor[debuffType]
		oUF:Debug("CureableDebuff", "debuffType=", debuffType, "priority=", priority)
		if color then
			return texture, count, expirationTime - duration, duration, color.r, color.g, color.b, 1
		else
			return texture, count, expirationTime - duration, duration, nil, nil, nil, 1
		end
	end
end)

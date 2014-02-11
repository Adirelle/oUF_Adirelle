--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local DebuffTypeColor = _G.DebuffTypeColor
local debugstack = _G.debugstack
local format = _G.format
local geterrorhandler = _G.geterrorhandler
local GetSpellInfo = _G.GetSpellInfo
local select = _G.select
local strjoin = _G.strjoin
local tostring = _G.tostring
local tostringall = _G.tostringall
local type = _G.type
local UnitAura = _G.UnitAura
local UnitBuff = _G.UnitBuff
local UnitCanAssist = _G.UnitCanAssist
local UnitClass = _G.UnitClass
local UnitDebuff = _G.UnitDebuff
local UnitIsUnit = _G.UnitIsUnit
--GLOBALS>

-- ------------------------------------------------------------------------------
-- Helper
-- ------------------------------------------------------------------------------

local function IsMeOrMine(caster)
	return caster and (UnitIsUnit('player', caster) or UnitIsUnit('pet', caster) or UnitIsUnit('vehicle', caster))
end

-- ------------------------------------------------------------------------------
-- Filter factories
-- ------------------------------------------------------------------------------

local reported
local function GetSpellName(caller, spellId, ...)
	local spellName = GetSpellInfo(spellId)
	if not spellName then
		local k = strjoin('-', tostringall(caller, spellId, ...))
		if not reported then
			reported = {}
		elseif reported[k] then
			return
		end
		local stack = debugstack(3):match("[^%.\\]+%.lua:%d+")
		geterrorhandler()(format(
			"[%s] Wrong spell id passed to %s. Please report this whole error. id=%d, class=%s, version=%s, params=[%s], source=%s",
			moduleName, caller, spellId, select(2, UnitClass('player')), oUF_Adirelle.VERSION, strjoin(',', tostringall(...)), stack
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
	if not spellName then return "none" end
	local filter, exists = GetGenericFilter("OwnAura", spellName, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filter, function(unit)
			local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName, nil, "PLAYER")
			if name then
				return texture, count, expirationTime-duration, duration, r, g, b
			end
		end)
	end
	return filter
end

function private.GetAnyAuraFilter(spellId, filter, r, g, b)
	local spellName = GetSpellName("GetAnyAuraFilter", spellId, filter, r, g, b)
	if not spellName then return "none" end
	local filter, exists = GetGenericFilter("AnyAura", spellName, filter, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filter, function(unit)
			local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName, nil, filter)
			if name then
				return texture, count, expirationTime-duration, duration, r, g, b
			end
		end)
	end
	return filter
end

function private.GetOwnStackedAuraFilter(spellId, countThreshold, r, g, b)
	local spellName = GetSpellName("GetOwnStackedAuraFilter", spellId, countThreshold, r, g, b)
	if not spellName then return "none" end
	assert(type(countThreshold) == "number", "invalid count threshold: "..tostring(countThreshold))
	local filter, exists = GetGenericFilter("OwnStackedAura", spellName, countThreshold, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filter, function(unit)
			local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName)
			if name and IsMeOrMine(caster) and count >= countThreshold then
				return texture, 1, expirationTime-duration, duration, r, g, b
			end
		end)
	end
	return filter
end

-- ------------------------------------------------------------------------------
-- Cureable debuff filter
-- ------------------------------------------------------------------------------

local LibDispellable = oUF_Adirelle.GetLib("LibDispellable-1.0")
local IsEncounterDebuff = oUF_Adirelle.IsEncounterDebuff
oUF:AddAuraFilter("CureableDebuff", function(unit)
	if not UnitCanAssist("player", unit) then return end
	local priority, count, expirationTime = 1, 0, 0
	local texture, debuffType, duration
	for index, canDispel, _, _, thisTexture, thisCount, thisDebuffType, thisDuration, thisExpirationTime, caster, _, _, spellID, _, isBossDebuff in LibDispellable:IterateDispellableAuras(unit, false, true) do

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
			priority, texture, count, debuffType, duration, expirationTime = thisPriority, thisTexture, thisCount, thisDebuffType, thisDuration, thisExpirationTime
		end
	end
	if texture then
		local color = DebuffTypeColor[debuffType]
		oUF:Debug("CureableDebuff", "debuffType=", debuffType, "priority=", priority)
		if color then
			return texture, count, expirationTime-duration, duration, color.r, color.g, color.b, 1
		else
			return texture, count, expirationTime-duration, duration, nil, nil, nil, 1
		end
	end
end)

-- ------------------------------------------------------------------------------
-- Priests' "Power word: shield" special case
-- ------------------------------------------------------------------------------

if select(2, UnitClass('player')) == "PRIEST" then
	local PWSHIELD, WEAKENEDSOUL = GetSpellName("PWSHIELD", 17), GetSpellName("WEAKENEDSOUL", 6788)
	if PWSHIELD and WEAKENEDSOUL then
		oUF:AddAuraFilter("PW:Shield", function(unit)
			local texture, _, _, duration, expirationTime = select(3, UnitBuff(unit, PWSHIELD))
			if not texture then
				duration, expirationTime = select(6, UnitDebuff(unit, WEAKENEDSOUL))
				if duration then
					-- Display a red X in place of the weakened soul icon
					texture = [[Interface\RaidFrame\ReadyCheck-NotReady]]
				end
			end
			if texture then
				return texture, 0, expirationTime-duration, duration
			end
		end)
	else
		oUF:AddAuraFilter("PW:Shield", function() end)
	end
end



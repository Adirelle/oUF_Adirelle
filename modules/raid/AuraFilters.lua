--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local moduleName = ...

local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit
local UnitAura = UnitAura
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local GetNumRaidMembers = GetNumRaidMembers
local UnitClass = UnitClass
local UnitBuff = UnitBuff
local UnitDebuff = UnitDebuff

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

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
			moduleName, caller, spellId, select(2, UnitClass('player')), VERSION, strjoin(',', tostringall(...)), stack
		))
		reported[k] = true
	end
	return spellName
end

local function GetGenericFilter(...)
	local name = strjoin("-", tostringall(...))
	return name, oUF:HasAuraFilter(name)
end

function GetOwnAuraFilter(spellId, r, g, b)
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

function GetAnyAuraFilter(spellId, filter, r, g, b)
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

function GetOwnStackedAuraFilter(spellId, countThreshold, r, g, b)
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

local LibDispellable = GetLib("LibDispellable-1.0")
oUF:AddAuraFilter("CureableDebuff", function(unit)
	local alpha, count, expirationTime = 0.5, 0, 0	
	local texture, debuffType, duration
	for i = 1, math.huge do
		local thisName, _, thisTexture, thisCount, thisDebuffType, thisDuration, thisExpirationTime, caster = UnitAura(unit, i, "HARMFUL")
		if thisName and not (caster and UnitCanAssist(caster, unit)) then
			local thisAlpha = LibDispellable:CanDispel(unit, false, thisDebuffType) and 1 or 0.5
			if not thisCount then thisCount = 0 end
			if not thisExpirationTime then thisExpirationTime = 0 end
			if not texture or thisAlpha > alpha or (thisAlpha == alpha and (thisCount > count or (thisCount == count and thisExpirationTime > expirationTime))) then
				alpha, texture, count, debuffType, duration, expirationTime = thisAlpha, thisTexture, thisCount, thisDebuffType, thisDuration, thisExpirationTime
			end
		else
			break
		end
	end
	if texture and (duration ~= 0 or debuffType) then
		color = DebuffTypeColor[debuffType or "none"]
		return texture, count, expirationTime-duration, duration, color.r, color.g, color.b, alpha
	end
end)

-- ------------------------------------------------------------------------------
-- Class specific buffs
-- ------------------------------------------------------------------------------

do
	local err = {}
	local commonBuffs = {
		[ 1022] = 70, -- Hand of Protection
		[33206] = 50, -- Pain Suppression
		[47788] = 50, -- Guardian Spirit
		[29166] = 20, -- Innervate
	}

	local tmp = {}
	local function compare(a, b)
		return tmp[a] > tmp[b]
	end
	local function BuildClassBuffs(classBuffs)
		wipe(tmp)
		local buffs = {}
		for _, t in pairs({classBuffs, commonBuffs}) do
			for id, prio in pairs(t) do
				local name = GetSpellName("BuildClassBuffs", id, prio)
				if name then
					tmp[name] = prio
					tinsert(buffs, name)
				end
			end
		end
		table.sort(buffs, compare)
		return buffs
	end

	local importantBuffs = {
		HUNTER = BuildClassBuffs{
			[19263] = 40, -- Deterrence
			[ 5384] = 10, -- Feign Death
		},
		MAGE = BuildClassBuffs{
			[45438] = 80, -- Ice Block
		},
		DRUID = BuildClassBuffs{
			[61336] = 60, -- Survival Instincts
			[22812] = 50, -- Barkskin
			[22842] = 30, -- Frenzied Regeneration
		},
		PALADIN = BuildClassBuffs{
			[  642] = 80, -- Divine Shield
			[  498] = 50, -- Divine Protection
		},
		WARRIOR = BuildClassBuffs{
			[12975] = 60, -- Last Stand
			[  871] = 50, -- Shield Wall
			[55694] = 30, -- Enraged Regeneration
			[ 2565] = 20, -- Shield Block
		},
		DEATHKNIGHT = BuildClassBuffs{
			[48792] = 50, -- Icebound Fortitude
			[51271] = 50, -- Unbreakable Armor
			[48707] = 40, -- Anti-Magic Shell
			-- [49222] = 20, -- Bone Shield
		},
		ROGUE = BuildClassBuffs{
			[31224] = 60, -- Cloak of Shadows
		},
		WARLOCK = BuildClassBuffs{
			[ 7812] = 40, -- Sacrifice
		},
		PRIEST = BuildClassBuffs{
			[20711] = 99, -- Spirit of Redemption
		},
		SHAMAN = BuildClassBuffs{},
	}

	oUF:AddAuraFilter("ClassImportantBuff", function(unit)
		if not UnitIsPlayer(unit) then return end
		local buffs = importantBuffs[select(2, UnitClass(unit))]
		if not buffs then return end
		for i, spellName in ipairs(buffs) do
			local name, _, texture, count, _, duration, expirationTime = UnitAura(unit, spellName, nil, "HELPFUL")
			if name then
				return texture, count, expirationTime-duration, duration
			end
		end
	end)
end

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



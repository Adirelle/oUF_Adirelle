--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

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

local function GetGenericFilter(...)
	local name = string.join("-", tostringall(...))
	return name, oUF:HasAuraFilter(name)
end

function GetOwnAuraFilter(spellId, r, g, b)
	local spellName = GetSpellInfo(spellId)
	if not spellName then -- FIXME
		geterrorhandler('GetOwnAuraFilter: unknown spell #'..spellId)
		return "none"
	end
	assert(spellName, "invalid spell id: "..spellId)
	local filter, exists = GetGenericFilter("OwnAura", spellName, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filter, function(unit)
			local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName)
			if name and IsMeOrMine(caster) then
				return texture, count, expirationTime-duration, duration, r, g, b
			end
		end)
	end
	return filter
end

function GetAnyAuraFilter(spellId, filter, r, g, b)
	local spellName = GetSpellInfo(spellId)
	if not spellName then -- FIXME
		geterrorhandler('GetAnyAuraFilter: unknown spell #'..spellId)
		return "none"
	end
	assert(spellName, "invalid spell id: "..spellId)
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
	local spellName = GetSpellInfo(spellId)
	if not spellName then -- FIXME
		geterrorhandler('GetOwnStackedAuraFilter: unknown spell #'..spellId)
		return "none"
	end
	assert(spellName, "invalid spell id: "..spellId)
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

function GetDebuffTypeFilter(debuffType, r, g, b, a)
	assert(type(debuffType) == "string", "invalid debuff type:"..tostring(debuffType))
	local filter, exists = GetGenericFilter("DebuffType", debuffType, r, g, b, a)
	if not exists then
		oUF:AddAuraFilter(filter, function(unit)
			for i = 1, 255 do
				local name, _, texture, count, dType, duration, expirationTime = UnitAura(unit, i, "HARMFUL")
				if not name then
					return
				elseif dType == debuffType then
					return texture, count, expirationTime-duration, duration, r, g, b, a
				end
			end
		end)
	end
	return filter
end

-- ------------------------------------------------------------------------------
-- Cureable debuff filter
-- ------------------------------------------------------------------------------

oUF:AddAuraFilter("CureableDebuff", function(unit)
	local alpha, color = 1
	local name, _, texture, count, debuffType, duration, expirationTime = UnitAura(unit, 1, "HARMFUL|RAID")
	if name then
		color = DebuffTypeColor[debuffType or "none"]
	else
		for i = 1, 1000 do
			name, _, texture, count, debuffType, duration, expirationTime = UnitAura(unit, i, "HARMFUL")
			if not name then
				return
			end
			color = debuffType and DebuffTypeColor[debuffType]
			if color then
				alpha = 0.5
				break
			end
		end
	end
	return texture, count, expirationTime-duration, duration, color.r, color.g, color.b, alpha
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
				local name = GetSpellInfo(id)
				if not name then -- FIXME
					if not err[id] then
						geterrorhandler()("BuildClassBuffs: unknown spell #"..id)
						err[id] = true
					end
				else
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

if select(2, UnitClass('player')) == "PRIEST" and false then -- FIXME
	local PWSHIELD, WEAKENEDSOUL = GetSpellInfo(17), GetSpellInfo(6788)
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
end



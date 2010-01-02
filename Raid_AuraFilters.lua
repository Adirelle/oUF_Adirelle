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

function GetDebuffTypeFilter(debuffType, r, g, b)
	assert(type(debuffType) == "string", "invalid debuff type:"..tostring(debuffType))
	local filter, exists = GetGenericFilter("DebuffType", debuffType, r, g, b)
	if not exists then
		oUF:AddAuraFilter(filter, function(unit)
			for i = 1, 255 do
				local name, _, texture, count, debuffType, duration, expirationTime = UnitAura(unit, i, "HARMFUL")
				if not name then 
					return 
				elseif debuffType == debuffType then
					return texture, count, expirationTime-duration, duration, r, g, b
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
	local name, _, texture, count, debuffType, duration, expirationTime = UnitAura(unit, 1, "HARMFUL|RAID")
	if name then
		local color = DebuffTypeColor[debuffType or "none"]
		return texture, count, expirationTime-duration, duration, color.r, color.g, color.b
	end
end)

-- ------------------------------------------------------------------------------
-- Class specific buffs
-- ------------------------------------------------------------------------------

do
	local commonBuffs = {
		[19752] = 99, -- Divine Intervention
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
				local name = assert(GetSpellInfo(id), "invalid spell id: "..id)
				tmp[name] = prio
				tinsert(buffs, name)
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
			[64205] = 90, -- Divine Sacrifice
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
			[47986] = 40, -- Sacrifice
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
-- PvP control debuff filter
-- ------------------------------------------------------------------------------

local drdata = LibStub and LibStub('DRData-1.0', true)
if drdata then
	Debug('Using DRData-1.0 version')

	local IGNORED = -1
	local SPELL_CATEGORIES = {}
	local DEFAULT_PRIORITIES = {
		banish = 100,
		cyclon = 100,
		mc = 100,
		ctrlstun = 90,
		rndstun = 90,
		cheapshot = 90,
		charge = 90,
		fear = 80,
		horror = 80,
		sleep = 60,
		disorient = 60,
		scatters = 60,
		silence = 50,
		disarm = 50,
		ctrlroot = 40,
		rndroot = 40,
		entrapment = 40,
	}
	local CLASS_PRIORITIES = {
		HUNTER = {
			silence = IGNORED,
		},
		WARRIOR = {
			silence = IGNORED,
		},
		ROGUE = {
			silence = IGNORED,
		},
		DRUID = {
			disarm = IGNORED,
		},
		PRIEST = {
			disarm = IGNORED,
		},
		WARLOCK = {
			disarm = IGNORED,
		},
		MAGE = {
			disarm = IGNORED,
		},
	}
	for id, cat in pairs(drdata:GetSpells()) do
		local name = GetSpellInfo(id)
		if name and DEFAULT_PRIORITIES[cat] then
			SPELL_CATEGORIES[name] = cat
		end
	end
	do
		local meta = { __index = DEFAULT_PRIORITIES }
		for name, t in pairs(CLASS_PRIORITIES) do
			CLASS_PRIORITIES[name] = setmetatable(t, meta)
		end
	end

	oUF:AddAuraFilter("PvPDebuff", function(unit)
		if not UnitIsPVP(unit) or GetNumRaidMembers() > 5 then return end
		local _, className = UnitClass(unit)
		local classPriorities = CLASS_PRIORITIES[className] or DEFAULT_PRIORITIES
		local curPrio, curTexture, curCount, curExpTime, curDuration, curDebuffType = IGNORED
		for index = 1, 256 do
			local name, _, icon, count, debuffType, duration, expirationTime = UnitDebuff(unit, index)
			if not name then break end
			local priority = classPriorities[SPELL_CATEGORIES[name] or false]
			if priority and priority > curPrio then
				curPrio, curTexture, curCount, curExpTime, curDuration, curDebuffType = priority, icon, count, expirationTime, duration, debuffType
			end
		end
		if curTexture then
			local color = DebuffTypeColor[curDebuffType or "none"]
			return curTexture, curCount, curExpTime-curDuration, curDuration, color.r, color.g, color.b
		end
	end)
end

-- ------------------------------------------------------------------------------
-- Priests' "Power word: shield" special case
-- ------------------------------------------------------------------------------

if select(2, UnitClass('player')) == "PRIEST" then
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

-- ------------------------------------------------------------------------------
-- PvE encounter debuffs
-- ------------------------------------------------------------------------------

do
	-- Data gathered from various sources, including BigWigs modules, Wowhead, Wowwiki and mmo-champion
	-- Most are untested too
	local DEBUFFS_STR = [=[		
		Forge of Souls
			Devourer of Souls
				Mirrored Soul: 69051 = 100
		Pit of Saron
			Krick and Ick
				Pursuit: 68987 = 100
			Scourgelord Tyrannus
				Mark of Rimefang: 69275 = 80
				Overlords' Brand: 69172 = 100
		Halls of Reflection
			Marwyn
				Corrupted Touch: 72383 = 100
		Ulduar
			XT-002 Deconstructor
				Gravity Bomb: 63024, 64234 = 100
				Light Bomb: 63018, 65121 = 100
			Ignis the Furnace Master
				SlagPot: 62717, 63477 = 100
			The Iron Council
				Overwhelm: 64637, 61888 = 100
			Kologarn
				Grip: 64290, 64292 = 100
			Freya
				Root: 62861, 62930, 62283, 62438 = 100
				Fury: 62589, 63571 = 100
			Hodir
				Flash-freezed: 61969, 61990 = 100
			Thorim
				Hammer: 62042 = 100
				Detonation: 62526 = 100
			Yogg-Saron
				Squeeze: 64125, 64126 = 80
				Linked: 63802 = 100
				Insane: 63120 = 100
		Coliseum
			Gormok
				Impale: 67477 = 100
			Jormungars
				Toxin: 67618, 67619, 67620, 66823 = 100
				Burn: 66869, 66870 = 100	
			Lord Jaraxxus			
				Legion Flame: 68123, 68124, 68125, 66197 = 80
				Incinerate Flesh: 67049, 67050, 67051, 66237 = 100
			Faction Champions
				Blind: 65960 = 100
				Polymorph: 65801 = 100			
				Wyvern: 65877 = 100
			The Twin Val'kyr
				Light/Dark Essence: 65686, 67222, 67223, 67224, 67176, 67177, 67178, 65684 = 80
				Light/Dark Touch: 67281, 67282, 67283, 67296, 67297, 67298 = 100
			Anub'arak
				ColdDebuff: 66013, 67700, 68509, 68510 = 80
				Pursue: 67574 = 100
		Icecrown Citadel
			Lord Marrowgar
				Coldflame: 69146 = 100
			Lady Deathwhisper
				Death and Decay: 71001 = 80
				Dominate Mind: 71289 = 100
			Saurfang
				Boiling Blood: 72385 = 60
				Rune of Blood: 72408 = 80
				Mark: 72293 = 100
			Rotface
				Infection: 69674, 71224 = 100
			Precious
				Wound: 71127 = 100
			Professor Putricide
				Gaseous Bloat: 72455 = 100
				Volatile Ooze Adhesive: 70447 = 100	
			Blood-Queen Lana'thel
				Pact: 71340, 71390 = 100
			Sindragosa
				Frost Beacon: 70126 = 100
			Stinky
				Wound: 71127 = 100
	]=]
	
	-- Convert string data to table
	local DEBUFFS = {}
	for def, ids, priority in DEBUFFS_STR:gmatch('((%d[%d%s,]*)%s*=%s*(%d+))') do
		priority = tonumber(priority)
		for id in ids:gmatch("(%d+)") do
			local name = GetSpellInfo(tonumber(id))
			if name then
				DEBUFFS[name] = priority
			else
				geterrorhandler()("InlineAura: unknown spell #"..id.." in "..def)
			end
		end
	end

	oUF:AddAuraFilter("EncounterDebuff", function(unit)
		local curPrio, curTexture, curCount, curDebuffType, curDuration, curExpirationTime
		for i = 1, 255 do
			local name, _, texture, count, debuffType, duration, expirationTime = UnitDebuff(unit, i)
			if not name then
				break
			else
				local prio = DEBUFFS[name]
				if prio and (not curPrio or prio > curPrio) then
					curPrio, curTexture, curCount, curDebuffType, curDuration, curExpirationTime = prio, texture, count, debuffType, duration, expirationTime
				end 
			end
		end
		if curTexture then
			local color = DebuffTypeColor[curDebuffType or "none"]
			return curTexture, curCount, curExpirationTime-curDuration, curDuration, color.r, color.g, color.b
		end
	end)
end


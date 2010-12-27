--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local GetSpellInfo = GetSpellInfo
local UnitDebuff = UnitDebuff
local DebuffTypeColor = DebuffTypeColor

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

local EncounterDebuff, PvPDebuff

-- ------------------------------------------------------------------------------
-- PvE encounter debuffs
-- ------------------------------------------------------------------------------

do
	-- Data gathered from various sources, including BigWigs modules, Wowhead, Wowwiki and mmo-champion
	-- Most are untested too
	local DEBUFFS_STR = [=[
		--------------------------------------------------------------------------------
		-- 3.3 instances and raids
		--------------------------------------------------------------------------------
		Forge of Souls
			Bronhajm
				Corrupt Soul: 68839 = 100
			Devourer of Souls
				Mirrored Soul: 69051, 69023, 69034 = 100
		Pit of Saron
			Krick and Ick
				Pursuit: 68987 = 100
			Scourgelord Tyrannus
				Mark of Rimefang: 69275 = 80
				Overlords' Brand: 69190, 69189, 69172 = 100
			Forgemaster Garfrost
				Permafrost: 68786, 70336 = 100 [>=4]
				Deep Freeze: 70380, 70384 = 100
		Halls of Reflection
			Marwyn
				Corrupted Touch: 72383, 72450 = 100
		Ulduar
			XT-002 Deconstructor
				Gravity Bomb: 63024, 64234 = 100
				Seearing Light: 63018, 65121 = 100
			Ignis the Furnace Master
				SlagPot: 62717, 63477 = 100
			The Iron Council
				Overwhelming Power: 64637, 61888 = 100
			Kologarn
				Stone Grip: 64290, 64292 = 80
				Crunch Armor: 63355, 64002 = 100
			Freya
				Iron Roots: 62861, 62930, 62283, 62438 = 80
				Nature's Fury: 62589, 63571 = 100
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
				Impale: 67477, 66331, 67478, 67479 = 100
				Snobolled: 66406 = 100
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
				Impale: 69065 = 100
			Lady Deathwhisper
				Dominate Mind: 71289 = 100
			Saurfang
				Boiling Blood: 72385, 72441, 72442, 72443 = 60
				Rune of Blood: 72408, 72409, 72410, 72447, 72448, 72449 = 80
				Mark: 72293 = 100
			Rotface
				Infection: 69674, 71224 = 100
			Festergut
				Inoculated: 69291, 72101, 72102, 72103 = 40 [>=3]
				Gastric Bloat: 72551, 72219 = 60 [>= 6]
				Malleable Goo: 72297, 70852, 70853, 72296, 72458, 72548, 72549, 72550, 72873, 72878 = 70
				Spores: 69279 = 80
				Vile Gas: 72272, 72273, 72274, 73020 = 100
			Precious & Stinky
				Mortal Wound: 71127 = 100 [>=4]
			Professor Putricide
				Gaseous Bloat: 72455 = 100
				Volatile Ooze Adhesive: 70447 = 100
				Mutated Plague: 72672, 72451, 72454, 72463, 72464, 72506, 72507, 72671, 72745, 72746, 72747, 72748 = 100
			Blood-Queen Lana'thel
				Volatile Ooze Adhesive: 70447 = 100
				Essence of the Blood Queen: 70867, 70871, 70950, 71473, 71532, 71533, 70872, 70879, 71525, 71530, 71531 = 80
				Pact: 71340, 71341, 71390 = 90
				Frenzied Bloodthirst: 70877, 71474 = 100
			Blood Prince Council
				Shadow Resonance: 71822 = 100
			Sindragosa
				Unchained Magic: 69762 = 60
				Chilled to the Bone: 70106 = 80 [>=4]
				Instability: 69766 = 80
				Mystic Buffet: 70128, 70127, 72528, 72529, 72530 = 90 [>=3]
				Asphyxiation: 71665 = 100
				Ice Tomb: 70157 = 100
				Frost Beacon: 70126 = 100
			The Lich King
				Infest: 70541, 73779, 73780, 73781 = 80
				Necrotic Plague: 70337, 73912, 73913, 73914 = 100
		Vault of Archavon
			Toravon
				Frostbite: 72004, 72120, 72121 = 100 [>=4]
		--------------------------------------------------------------------------------
		-- Cataclysm
		--------------------------------------------------------------------------------
		Blackrock Mountain: Blackrock Caverns
			Corla, Herald of Twilight
				Evolution: 75610 = 100
			Karsh Steelbender
				Superheated Quicksilver Armor: 75846, 93567 = 100
		Grim Batol
			Forgemaster Throngus
				Impaling Slam: 75056, 90756 = 100
				Disorienting Roar: 74976, 90737 = 80
				Burning Flames: 90764 = 100
		Lost City of the Tol'vir
			Lockmaw
				Vicious Poison: 81630, 90004 = 80
				Scent of Blood: 89998, 81690 = 100
	]=]

	-- Convert string data to table
	local DEBUFFS = {}
	local THRESHOLDS = {}
	for def, ids, priority in DEBUFFS_STR:gmatch('((%d[%d%s,]*)%s*=%s*(%d+))') do
		priority = tonumber(priority)
		for id in ids:gmatch("(%d+)") do
			DEBUFFS[tonumber(id)] = priority
		end
	end
	-- Parse data with a threshold
	for def, ids, priority, threshold in DEBUFFS_STR:gmatch('((%d[%d%s,]*)%s*=%s*(%d+)%s*%[%s*>=%s*(%d+)%s*%]%s*)') do
		priority = tonumber(priority)
		threshold = tonumber(threshold)
		for id in ids:gmatch("(%d+)") do
			id = tonumber(id)
			DEBUFFS[id] = priority
			THRESHOLDS[id] = threshold
		end
	end

	local tonumber, UnitDebuff, DebuffTypeColor = tonumber, UnitDebuff, DebuffTypeColor
	function EncounterDebuff(unit)
		local texture, count, debuffType, duration, expirationTime
		local priority = 0
		local index = 0
		repeat
			index = index + 1
			local name, _, newTexture, newCount, newDebuffType, newDuration, newExpirationTime, _, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, index)
			if name then
				local newPriority = (isBossDebuff and 10) or (spellID and (not THRESHOLDS[spellID] or (newCount or 0) >= THRESHOLDS[spellID]) and DEBUFFS[spellID])
				if newPriority and newPriority > priority then
					priority, texture, count, debuffType, duration, expirationTime = newPriority, newTexture, newCount, newDebuffType, newDuration, newExpirationTime
				end
			end
		until not name
		if texture then
			local color = DebuffTypeColor[debuffType or "none"]
			if color then
				return texture, count, expirationTime-duration, duration, color.r, color.g, color.b
			else
				return texture, count, expirationTime-duration, duration
			end
		end
	end

	oUF:AddAuraFilter("EncounterDebuff", EncounterDebuff)
end

-- ------------------------------------------------------------------------------
-- PvP control debuff filter
-- ------------------------------------------------------------------------------

local drdata = GetLib('DRData-1.0')
if drdata then

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

	function PvPDebuff(unit)
		if not UnitIsPVP(unit) then return end
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
	end

	oUF:AddAuraFilter("PvPDebuff", PvPDebuff)
end

-- ------------------------------------------------------------------------------
-- Important debuff
-- ------------------------------------------------------------------------------

if PvPDebuff then
	oUF:AddAuraFilter("ImportantDebuff", function(...)
		local texture, count, start, duration, r, g, b = PvPDebuff(...)
		if texture then
			return texture, count, start, duration, r, g, b
		else
			return EncounterDebuff(...)
		end
	end)
else
	oUF:AddAuraFilter("ImportantDebuff", EncounterDebuff)
end

--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local GetSpellInfo = GetSpellInfo
local UnitDebuff = UnitDebuff
local DebuffTypeColor = DebuffTypeColor

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

-- ------------------------------------------------------------------------------
-- PvE encounter debuffs
-- ------------------------------------------------------------------------------

do
	-- Data gathered from various sources, including BigWigs modules, Wowhead, Wowwiki and mmo-champion
	-- Most are untested too
	local DEBUFFS_STR = [=[
		Forge of Souls
			Devourer of Souls
				Mirrored Soul: 69051, 69023, 69034 = 100
		Pit of Saron
			Krick and Ick
				Pursuit: 68987 = 100
			Scourgelord Tyrannus
				Mark of Rimefang: 69275 = 80
				Overlords' Brand: 69190, 69189, 69172 = 100
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
			DEBUFFS[tonumber(id)] = priority
		end
	end

	oUF:AddAuraFilter("EncounterDebuff", function(unit)
		local _, iType = IsInInstance()
		if iType ~= 'party' and iType ~= 'raid' then return end
		local curPrio, curName, curTexture, curCount, curDebuffType, curDuration, curExpirationTime
		for i = 1, 255 do
			local name, _, texture, count, debuffType, duration, expirationTime, _, _, _, spellId = UnitDebuff(unit, i)
			if not name then
				break
			else
				local prio = DEBUFFS[spellId]
				if prio and (not curPrio or prio > curPrio) then
					curPrio, curName, curTexture, curCount, curDebuffType, curDuration, curExpirationTime = prio, name, texture, count, debuffType, duration, expirationTime
				end
			end
		end
		if curTexture then
			--Debug("Encounter debuff", "target=", UnitName(unit), "prio=", curPrio, "debuff=", curName, "texture=", curTexture, "count=", curCount, "type=", curDebuffType, "duration=", curDuration, "expTime=", curExpirationTime)
			local color = DebuffTypeColor[curDebuffType or "none"]
			local r, g, b
			if color then
				r, g, b = color.r, color.g, color.b
			end
			return curTexture, curCount, curExpirationTime-curDuration, curDuration, r, g, b
		end
	end)
end


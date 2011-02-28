--[=[
Adirelle's oUF layout
(c) 2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .WarningIcon
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

-- ------------------------------------------------------------------------------
-- Spell data
-- ------------------------------------------------------------------------------

local SPELLS = {}
local THRESHOLDS = {}

-- General crowd Control
for spellID in gmatch([=[
		710 Banish
	76780 Bind Elemental
	33786 Cyclone
		339 Entangling Roots
	 5782 Fear
	 3355 Freezing Trap
	51514 Hex
	 2637 Hibernate
		118 Polymorph
	61305 Polymorph (Black Cat)
	28272 Polymorph (Pig)
	61721 Polymorph (Rabbit)
	61780 Polymorph (Turkey)
	28271 Polymorph (Turtle)
	20066 Repentance
	 6770 Sap
	 6358 Seduction
	 9484 Shackle Undead
	10326 Turn Evil
	19386 Wyvern Sting
]=], "%d+") do
	SPELLS[tonumber(spellID)] = 90
end

-- PvP debuffs using DRData-1.0
local drdata = ns.GetLib('DRData-1.0')
if drdata then
	local priorities = {
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
	for spellID, cat in pairs(drdata:GetSpells()) do
		SPELLS[spellID] = priorities[cat]
	end
end

-- PvE encounters
do
	-- Data gathered from various sources, including BigWigs modules, Wowhead, Wowwiki and mmo-champion
	-- Most are untested too
	local DEBUFFS_STR = [=[
		Blackrock Mountain: Blackrock Caverns
			Corla, Herald of Twilight
				Evolution: 75697, 87378 = 100
			Karsh Steelbender
				Superheated Quicksilver Armor: 75846, 93567 = 100
		Grim Batol
			Forgemaster Throngus
				Impaling Slam: 75056, 90756 = 100
				Disorienting Roar: 74976, 90737 = 80
				Burning Flames: 90764 = 100
		Lost City of the Tol'vir
			Trashs
				Infectious Plague: 82768, 82769 = 100
			Lockmaw
				Vicious Poison: 81630, 90004 = 80
				Scent of Blood: 89998, 81690 = 100
			Siamat
				Lightning Charge: 93959, 91871 = 100
		The Deadmines
			Helix Gearbreaker
				Chest Bomb: 88352 = 100
		Vortex Pinacle
			Altairus
				Downwind of Altairus: 88286 = 100
		Blackwing Descent
			Magmaw
				Parasitic Infection: 91913, 94678, 94679 = 100
			Omnotron Defense System
				Lightning Conductor: 79888, 91431, 91432, 91433 = 100
				Poison Soaked Shell: 91501, 79835, 91503 = 70
				Fixate: 80094 = 90
				Acquiring Target: 79501, 92035, 92036, 92037 = 80
				Flamethrower: 79504, 91537, 91536, 91535 = 100
			Maloriak
				Consuming Flames: 77786, 92971, 92972, 92973 = 80
				Biting Chill: 77760, 92975, 92976, 92977 = 80
				Flash Freeze: 77699, 92978, 92979, 92980 = 100
			Chimaeron
				Break: 82881 = 100
		Bastion of Twilight
			Valiona and Theralion
				Blackout: 86788, 92876, 92877, 92878 = 80
				Engulfing Magic: 86622, 95639, 95640, 95641 = 100
		Baradin Hold
			Argaloth
				Consuming Darkness: 88954, 95173 = 100
		}
	]=]

	-- Simple debuffs
	for def, spellIDs, priority in gmatch(DEBUFFS_STR, '((%d[%d%s,]*)%s*=%s*(%d+))') do
		priority = tonumber(priority)
		for spellID in gmatch(spellIDs, '(%d+)') do
			SPELLS[tonumber(spellID)] = priority
		end
	end
	
	-- Debuffs with threshold
	for def, spellIDs, priority, threshold in gmatch(DEBUFFS_STR, '((%d[%d%s,]*)%s*=%s*(%d+)%s*%[%s*>=%s*(%d+)%s*%]%s*)') do
		priority = tonumber(priority)
		threshold = tonumber(threshold)
		for spellID in gmatch(spellIDs, '(%d+)') do
			spellID = tonumber(spellID)
			SPELLS[spellID] = priority
			THRESHOLDS[spellID] = threshold
		end
	end
end

-- To be used to avoid displaying these spells twice
function ns.IsEncounterDebuff(spellID)
	return spellID and SPELLS[spellID]
end

-- ------------------------------------------------------------------------------
-- Element logic
-- ------------------------------------------------------------------------------

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = self.unit
	local icon = self.WarningIcon

	local index = 0
	local priority = 0
	local name, texture, count, debuffType, duration, expirationTime, _
	local newTexture, newCount, newDebuffType, newDuration, newExpirationTime
	repeat
		index = index + 1
		name, _, newTexture, newCount, newDebuffType, newDuration, newExpirationTime, _, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, index)
		if name then
			local newPriority = (spellID and (not THRESHOLDS[spellID] or (newCount or 0) >= THRESHOLDS[spellID]) and SPELLS[spellID]) or (isBossDebuff and 50)
			if newPriority and newPriority > priority then
				priority, texture, count, debuffType, duration, expirationTime = newPriority, newTexture, newCount, newDebuffType, newDuration, newExpirationTime
			end
		end
	until not name
	if texture then
		local color = DebuffTypeColor[debuffType or "none"]
		icon:SetTexture(texture)
		icon:SetCooldown(expirationTime-duration, duration)
		icon:SetStack(count or 0)		
		icon:SetColor(color.r, color.g, color.b)
		icon:Show()
	else
		icon:Hide()
	end	
end

local function Path(self, ...)
	return (self.WarningIcon.Update or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local icon = self.WarningIcon
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		self:RegisterEvent('UNIT_AURA', Path)
		return true
	end
end

local function Disable(self)
	local icon = self.WarningIcon
	if icon then
		self:UnregisterEvent('UNIT_AURA', Path)
		icon:Hide()
	end
end

oUF:AddElement('WarningIcon', Update, Enable, Disable)


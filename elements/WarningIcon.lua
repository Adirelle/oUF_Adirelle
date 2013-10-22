--[=[
Adirelle's oUF layout
(c) 2011-2012 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .WarningIcon
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local DebuffTypeColor = _G.DebuffTypeColor
local gmatch = _G.gmatch
local huge = _G.math.huge
local pairs = _G.pairs
local tonumber = _G.tonumber
local UnitBuff = _G.UnitBuff
local UnitCanAssist = _G.UnitCanAssist
local UnitCanAttack = _G.UnitCanAttack
local UnitDebuff = _G.UnitDebuff
local UnitIsVisible = _G.UnitIsVisible
--GLOBALS>

-- ------------------------------------------------------------------------------
-- Spell data
-- ------------------------------------------------------------------------------

local BUFFS = {}
local DEBUFFS = {}
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
	DEBUFFS[tonumber(spellID)] = 90
end

-- PvP debuffs using DRData-1.0
local drdata = oUF_Adirelle.GetLib('DRData-1.0')
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
		DEBUFFS[spellID] = priorities[cat]
	end
end


-- To be used to avoid displaying these spells twice
function oUF_Adirelle.IsEncounterDebuff(spellID)
	return spellID and DEBUFFS[spellID]
end

-- Class noticeable buffs
do
	local BUFFS_STR = [=[
		DEATHKNIGHT:
			Bone Shield: 49222 = 30
			Vampiric Blood: 55233 = 30
			Anti-Magic Shell: 48707 = 40
			Dancing Rune Weapon: 49028 = 50
			Icebound Fortitude: 48792 = 60
		DRUID:
			Innervate: 29166 = 20
			Frenzied Regeneration: 22842 = 30
			Barkskin: 22812 = 50
			Might of Ursoc: 106922 = 55
			Survival Instincts: 61336 = 60
		HUNTER:
			Feign Death: 5384 = 20
			Deterrence: 19263 = 40
		MAGE:
			Ice Block: 45438 = 80
		PALADIN:
			Divine Plea: 54428 = 20
			Divine Protection: 498 = 30
			Hand of Sacrifice: 6940 = 50
			Ardent Defender: 31850 = 50
			Ancient Guardian (prot): 86659 = 60
			Hand of Protection: 1022 = 70
			Divine Shield: 642 = 80
		PRIEST:
			Hymn of Hope: 64901 = 20
			Pain Suppression: 33206 = 50
			Guardian Spirit: 47788 = 50
			Spirit of Redemption: 20711 = 99
		ROGUE:
			Evasion: 5277 = 40
			Cloak of Shadows: 31224 = 60
		WARLOCK:
			Sacrifice: 7812 = 40
			Unending Resolve: 104773 = 50
			Dark Bargain: 110913 = 60
		WARRIOR:
			Shield Block: 2565 = 20
			Enraged Regeneration: 55694 = 30
			Shield Wall: 871 = 50
			Last Stand: 12975 = 60
	]=]

	for def, spellIDs, priority in gmatch(BUFFS_STR, '((%d[%d%s,]*)%s*=%s*(%d+))') do
		priority = tonumber(priority)
		for spellID in gmatch(spellIDs, '(%d+)') do
			BUFFS[tonumber(spellID)] = priority
		end
	end
end

-- ------------------------------------------------------------------------------
-- Element logic
-- ------------------------------------------------------------------------------

local function GetBuff(unit, index)
	local name, _, texture, count, dispelType, duration, expirationTime, _, _, _, spellID = UnitBuff(unit, index)
	return name, BUFFS[spellID], texture, count, dispelType, duration, expirationTime
end

local function GetDebuff(unit, index)
	local name, _, texture, count, dispelType, duration, expirationTime, _, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, index)
	if isBossDebuff then
		return name, 50, texture, count, dispelType, duration, expirationTime
	elseif spellID then
		return name, DEBUFFS[spellID], texture, count, dispelType, duration, expirationTime
	end
	return name
end

local function Scan(self, unit, getFunc, offensive)
	local index = 0
	local priority = -huge
	local name, texture, count, dispelType, duration, expirationTime
	local newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime
	repeat
		index = index + 1
		name, newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime = getFunc(unit, index)
		if name and newPriority and newPriority > priority then
			priority, texture, count, dispelType, duration, expirationTime = newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime
		end
	until not name
	if dispelType and (offensive and not UnitCanAttack("player", unit)) or (not offensive and not UnitCanAssist("player", unit)) then
		dispelType = nil
	end
	return priority, texture, count, dispelType, duration, expirationTime
end

local function SetAuraIcon(icon, texture, count, dispelType, duration, expirationTime)
	if texture then
		icon:SetTexture(texture)
		icon:SetCooldown(expirationTime-duration, duration)
		icon:SetStack(count or 0)
		local color = dispelType and DebuffTypeColor[dispelType]
		if color then
			icon:SetColor(color.r, color.g, color.b)
		else
			icon:SetColor(nil, nil, nil)
		end
		icon:Show()
	elseif icon:IsShown() then
		icon:Hide()
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = self.unit

	local debuffIcon, buffIcon, bothIcon = self.WarningIconDebuff, self.WarningIconBuff, self.WarningIcon

	if UnitIsVisible(unit) then
		local buffPriority, buffTexture, buffCount, buffDispelType, buffDuration, buffExpirationTime = -huge
		local debuffPriority, debuffTexture, debuffCount, debuffDispelType, debuffDuration, debuffExpirationTime = -huge

		if bothIcon or debuffIcon then
			debuffPriority, debuffTexture, debuffCount, debuffDispelType, debuffDuration, debuffExpirationTime = Scan(self, unit, GetDebuff, false)
			if debuffIcon then
				debuffIcon:SetAura(debuffTexture, debuffCount, debuffDispelType, debuffDuration, debuffExpirationTime)
			end
		end
		if bothIcon or buffIcon then
			buffPriority, buffTexture, buffCount, buffDispelType, buffDuration, buffExpirationTime = Scan(self, unit, GetBuff, true)
			if buffIcon then
				buffIcon:SetAura(buffTexture, buffCount, buffDispelType, buffDuration, buffExpirationTime)
			end
		end
		if bothIcon then
			if debuffTexture then
				bothIcon:SetAura(debuffTexture, debuffCount, debuffDispelType, debuffDuration, debuffExpirationTime)
			else
				bothIcon:SetAura(buffTexture, buffCount, buffDispelType, buffDuration, buffExpirationTime)
			end
		end
	else
		if debuffIcon then
			debuffIcon:Hide()
		end
		if buffIcon then
			buffIcon:Hide()
		end
		if bothIcon then
			bothIcon:Hide()
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate')
end

local function EnableIcon(self, icon)
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		if not icon.SetAura then
			icon.SetAura = SetAuraIcon
		end
		return true
	end
end

local function Enable(self)
	if self.WarningIcon or self.WarningIconBuff or self.WarningIconDebuff then
		EnableIcon(self, self.WarningIcon)
		EnableIcon(self, self.WarningIconBuff)
		EnableIcon(self, self.WarningIconDebuff)
		self:RegisterEvent('UNIT_AURA', Update)
		return true
	end
end

local function Disable(self)
	local icon = self.WarningIcon
	if icon then
		self:UnregisterEvent('UNIT_AURA', Update)
		icon:Hide()
	end
end

oUF:AddElement('WarningIcon', Update, Enable, Disable)


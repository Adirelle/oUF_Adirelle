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
local ENCOUNTER_DEBUFFS = {}

-- PvP debuffs using DRData-1.0
local drdata = oUF_Adirelle.GetLib('DRData-1.0')
if drdata then
	local priorities = {
		ctrlstun = 90,
		rndstun = 90,
		fear = 80,
		horror = 80,
		disorient = 60,
		shortdisorient = 60,
		silence = 50,
		disarm = 50,
		ctrlroot = 40,
		shortroot = 40,
	}
	for spellID, cat in pairs(drdata:GetSpells()) do
		DEBUFFS[spellID] = priorities[cat] or 10
	end
end

-- Special cases
DEBUFFS[   605] = 100 -- Dominate Mind
DEBUFFS[   710] = 100 -- Banish
DEBUFFS[  1098] = 100 -- Enslave Demon
DEBUFFS[ 33786] = 100 -- Cyclone
DEBUFFS[113506] = 100 -- Cyclone (Symbiosis)

-- To be used to avoid displaying these spells twice
function oUF_Adirelle.IsEncounterDebuff(spellID)
	return spellID and ENCOUNTER_DEBUFFS[spellID]
end

-- Use BigWigs whenever available
if BigWigsLoader and BigWigsLoader.RegisterMessage then
	-- Listen to BigWigs messages to update ENCOUNTER_DEBUFFS

	-- Thanks Funkeh for adding this one
	BigWigsLoader.RegisterMessage(ENCOUNTER_DEBUFFS, 'BigWigs_OnBossLog', function(_, bossMod, event, ...)
		if event ~= 'SPELL_AURA_APPLIED' and event ~= 'SPELL_AURA_APPLIED_DOSE' then return end
		for i = 1, select('#', ...) do
			local id = select(i, ...)
			oUF.Debug('WarningIcon', 'Watching', id, GetSpellLink(id), 'for', bossMod:GetName())
			ENCOUNTER_DEBUFFS[id] = bossMod
		end
	end)

	BigWigsLoader.RegisterMessage(ENCOUNTER_DEBUFFS, 'BigWigs_OnBossDisable', function(_, bossMod)
		oUF.Debug('WarningIcon', bossMod:GetName(), 'disabled, cleaning the debuffs list')
		for id, mod in pairs(ENCOUNTER_DEBUFFS) do
			if mod == bossMod then
				ENCOUNTER_DEBUFFS[id] = nil
			end
		end
	end)

	oUF.Debug('WarningIcon', 'Using BigWigs for encounter debuffs')
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
		MONK
			Guard: 115295 = 20
			Mana Tea: 115294 = 20
			Elusive Brew: 115308 = 40
			Dampen Harm: 122278 = 50
			Zen Meditation: 115176 = 50
			Diffuse Magic: 122783 = 50
			Fortifying Brew: 115203 = 60
			Avert Harm: 115213 = 80
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

local function GetBuff(unit, index, offensive)
	local name, _, texture, count, dispelType, duration, expirationTime, _, _, _, spellID = UnitBuff(unit, index)
	local priority = BUFFS[spellID]
	if priority and LibDispellable:CanDispel(unit, offensive, dispelType) then
		priority = priority + 5
	end
	return name, priority, texture, count, dispelType, duration, expirationTime
end

local LibDispellable = oUF_Adirelle.GetLib('LibDispellable-1.0')
local function GetDebuff(unit, index, offensive)
	local name, _, texture, count, dispelType, duration, expirationTime, _, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, index)
	if name and spellID then
		local priority = DEBUFFS[spellID]
		if priority and LibDispellable:CanDispel(unit, offensive, dispelType) then
			priority = priority + 5
		elseif (isBossDebuff or ENCOUNTER_DEBUFF[spellID]) and dispelType == "none" then
			priority = 55
		end
		return name, priority, texture, count, dispelType, duration, expirationTime
	end
end

local function Scan(self, unit, getFunc, offensive)
	local index = 0
	local priority = -huge
	local name, texture, count, dispelType, duration, expirationTime
	local newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime
	repeat
		index = index + 1
		name, newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime = getFunc(unit, index, offensive)
		if name and newPriority and newPriority >= priority then
			priority, texture, count, dispelType, duration, expirationTime = newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime
		end
	until not name
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


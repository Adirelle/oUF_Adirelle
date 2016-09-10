--[=[
Adirelle's oUF layout
(c) 2011-2016 Adirelle (adirelle@gmail.com)
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
local band = bit.band
--GLOBALS>

-- ------------------------------------------------------------------------------
-- Spell data
-- ------------------------------------------------------------------------------

local BUFFS = {}
local DEBUFFS = {}
local ENCOUNTER_DEBUFFS = {}

local LibPlayerSpells = oUF_Adirelle.GetLib('LibPlayerSpells-1.0')

-- PvP debuffs using LibPlayerSpells-1.0
do
	local priorities = {
		[LibPlayerSpells.constants.STUN]         = 90,
		[LibPlayerSpells.constants.INCAPACITATE] = 80,
		[LibPlayerSpells.constants.DISORIENT]    = 60,
		[LibPlayerSpells.constants.ROOT]         = 40,
	}
	for debuff, _, _, _, cat in LibPlayerSpells:IterateSpells("", "AURA HARMFUL CROWD_CTRL") do
		local prio = 10
		for flag, value in pairs(priorities) do
			if value > prio and band(cat, flag) ~= 0 then
				prio = value
			end
		end
		DEBUFFS[spellID] = prio
	end
end

-- To be used to avoid displaying these spells twice
function oUF_Adirelle.IsEncounterDebuff(spellID)
	return spellID and ENCOUNTER_DEBUFFS[spellID]
end

-- Use BigWigs whenever available
if BigWigsLoader and BigWigsLoader.RegisterMessage then
	-- Listen to BigWigs messages to update ENCOUNTER_DEBUFFS

	-- Thanks Funkeh for adding this one
	BigWigsLoader.RegisterMessage(ENCOUNTER_DEBUFFS, 'BigWigs_OnBossLog', function(_, bossMod, event, ...)
		if event ~= 'SPELL_AURA_APPLIED' and event ~= 'SPELL_AURA_APPLIED_DOSE' and event ~= "SPELL_CAST_SUCCESS" then return end
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
local SURVIVAL = LibPlayerSpells.constants.SURVIVAL
local COOLDOWN = LibPlayerSpells.constants.COOLDOWN
local HELPFUL = LibPlayerSpells.constants.HELPFUL
local classFlag = LibPlayerSpells.constants[select(2, UnitClass('player'))]
for buff, flags in LibPlayerSpells:IterateSpells("SURVIVAL", "AURA") do
	local priority = 35
	if band(flags, SURVIVAL) ~= 0 then
		priority = priority + 30
	end
	if band(flags, COOLDOWN) ~= 0 then
		priority = priority + 20
	end
	if band(flags, HELPFUL) ~= 0 then
		priority = priority + 10
	end
	if band(flags, classFlag) ~= 0 then
		priority = priority + 5
	end
	BUFFS[buff] = priority
end

-- ------------------------------------------------------------------------------
-- Element logic
-- ------------------------------------------------------------------------------

local function GetBuff(unit, index)
	local name, _, texture, count, dispelType, duration, expirationTime, _, _, _, spellID = UnitBuff(unit, index)
	local priority = BUFFS[spellID]
	if oUF_Adirelle.CanDispel(unit, dispelType) then
		priority = (priority or 95) + 5
	end
	return name, priority, texture, count, dispelType, duration, expirationTime
end

local function GetDebuff(unit, index, noDispellable)
	local name, _, texture, count, dispelType, duration, expirationTime, caster, _, _, _, _, isBossDebuff = UnitDebuff(unit, index)
	local isDispellable = oUF_Adirelle.IsDispellable(dispelType)
	if not name or not spellID or (noDispellable and isDispellable) then
		return
	end
	local priority = DEBUFFS[spellID]
	if priority then
		if oUF_Adirelle.CanDispel(unit, dispelType) then
			priority = priority + 2
		elseif isDispellable then
			priority = priority - 2
		end
	elseif isBossDebuff then
		priority = 65
	elseif ENCOUNTER_DEBUFFS[spellID] then
		priority = 55
	end
	return name, priority, texture, count, dispelType, duration, expirationTime
end

local function UpdateIcon(icon, unit, isBuff)
	local index = 0
	local priority = icon.minPriority or -huge
	local noDispellable = icon.noDispellable
	local name, texture, count, dispelType, duration, expirationTime
	local newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime
	local getFunc = isBuff and GetBuff or GetDebuff
	repeat
		index = index + 1
		name, newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime = getFunc(unit, index, noDispellable)
		if name and newPriority and newPriority >= priority then
			priority, texture, count, dispelType, duration, expirationTime = newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime
		end
	until not name
	return icon:SetAura(texture, count, dispelType, duration, expirationTime)
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
		return true
	end
	icon:Hide()
	return false
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = self.unit

	local debuffIcon, buffIcon, bothIcon = self.WarningIconDebuff, self.WarningIconBuff, self.WarningIcon

	if UnitIsVisible(unit) then
		if debuffIcon then
			UpdateIcon(debuffIcon, unit, false)
		end
		if buffIcon then
			UpdateIcon(buffIcon, unit, true)
		end
		if bothIcon then
			if not UpdateIcon(bothIcon, unit, false) then
				UpdateIcon(bothIcon, unit, true)
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
			if not icon.minPriority then
				icon.minPriority = 0
			end
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

--[=[
Adirelle's oUF layout
(c) 2011-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Elements handled: .WarningIcon
--]=]

local _G = _G
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local band = _G.bit.band
local BigWigsLoader = _G.BigWigsLoader
local DebuffTypeColor = _G.DebuffTypeColor
local huge = _G.math.huge
local pairs = _G.pairs
local select = _G.select
local UnitBuff = _G.UnitBuff
local UnitDebuff = _G.UnitDebuff
local UnitIsVisible = _G.UnitIsVisible
--GLOBALS>

-- ------------------------------------------------------------------------------
-- Spell data
-- ------------------------------------------------------------------------------

local BUFFS = {}
local DEBUFFS = {}
local ENCOUNTER_DEBUFFS = {}

local LPS = oUF_Adirelle.GetLib("LibPlayerSpells-1.0")

-- PvP debuffs using LPS-1.0
do
	local priorities = {
		[LPS.constants.STUN] = 90,
		[LPS.constants.INCAPACITATE] = 80,
		[LPS.constants.DISORIENT] = 60,
		[LPS.constants.ROOT] = 40,
	}
	for spellID, _, _, _, ccType in LPS:IterateSpells(nil, "AURA HARMFUL CROWD_CTRL") do
		DEBUFFS[spellID] = priorities[ccType] or 10
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
	BigWigsLoader.RegisterMessage(ENCOUNTER_DEBUFFS, "BigWigs_OnBossLog", function(_, bossMod, event, ...)
		if
			event ~= "SPELL_AURA_APPLIED"
			and event ~= "SPELL_AURA_APPLIED_DOSE"
			and event ~= "SPELL_CAST_SUCCESS"
		then
			return
		end
		for i = 1, select("#", ...) do
			local id = select(i, ...)
			ENCOUNTER_DEBUFFS[id] = bossMod
		end
	end)

	BigWigsLoader.RegisterMessage(ENCOUNTER_DEBUFFS, "BigWigs_OnBossDisable", function(_, bossMod)
		for id, mod in pairs(ENCOUNTER_DEBUFFS) do
			if mod == bossMod then
				ENCOUNTER_DEBUFFS[id] = nil
			end
		end
	end)
end

-- Class noticeable buffs
local SURVIVAL = LPS.constants.SURVIVAL
local COOLDOWN = LPS.constants.COOLDOWN
local HELPFUL = LPS.constants.HELPFUL
local classFlag = LPS.constants[oUF_Adirelle.playerClass]
for buff, flags in LPS:IterateSpells("SURVIVAL", "AURA") do
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

local function GetBuff(unit, i)
	local name, texture, count, dType, duration, expirationTime, _, _, _, spellID = UnitBuff(unit, i)
	local priority = BUFFS[spellID]
	if oUF_Adirelle.CanDispel(unit, true, dType) then
		priority = (priority or 95) + 5
	end
	return name, priority, texture, count, dType, duration, expirationTime
end

local function GetDebuff(unit, i, noDispellable)
	local name, texture, count, dType, duration, expirationTime, _, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, i)
	local isDispellable = oUF_Adirelle.IsDispellable(dType)
	if not name or not spellID or (noDispellable and isDispellable) then
		return
	end
	local priority = DEBUFFS[spellID]
	if priority then
		if oUF_Adirelle.CanDispel(unit, false, dType) then
			priority = priority + 2
		elseif isDispellable then
			priority = priority - 2
		end
	elseif isBossDebuff then
		priority = 65
	elseif ENCOUNTER_DEBUFFS[spellID] then
		priority = 55
	end
	return name, priority, texture, count, dType, duration, expirationTime
end

local function UpdateIcon(icon, unit, isBuff)
	local i = 0
	local priority = icon.minPriority or -huge
	local noDispel = icon.noDispellable
	local name, texture, count, dType, duration, expirationTime
	local newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime
	local getFunc = isBuff and GetBuff or GetDebuff
	repeat
		i = i + 1
		name, newPriority, newTexture, newCount, newDispelType, newDuration, newExpirationTime = getFunc(unit, i, noDispel)
		if name and newPriority and newPriority >= priority then
			priority, texture, count = newPriority, newTexture, newCount
			dType, duration, expirationTime = newDispelType, newDuration, newExpirationTime
		end
	until not name
	return icon:SetAura(texture, count, dType, duration, expirationTime)
end

local function SetAuraIcon(icon, texture, count, dType, duration, expirationTime)
	if texture then
		icon:SetTexture(texture)
		icon:SetCooldown(expirationTime - duration, duration)
		icon:SetStack(count or 0)
		local color = dType and DebuffTypeColor[dType]
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

local function Update(self, _, unit)
	if unit and unit ~= self.unit then
		return
	end
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
	return Update(element.__owner, "ForceUpdate")
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
		self:RegisterEvent("UNIT_AURA", Update)
		return true
	end
end

local function Disable(self)
	local icon = self.WarningIcon
	if icon then
		self:UnregisterEvent("UNIT_AURA", Update)
		icon:Hide()
	end
end

oUF:AddElement("WarningIcon", Update, Enable, Disable)

--[=[
Adirelle's oUF layout
(c) 2016 Adirelle (adirelle@gmail.com)

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
--]=]

local _G = _G
local oUF_Adirelle = _G.oUF_Adirelle

local band = _G.bit.band
local bor = _G.bit.bor
local next = _G.next
local pairs = _G.pairs
local type = _G.type
local UnitCanAssist = _G.UnitCanAssist
local UnitCanAttack = _G.UnitCanAttack
local UnitDebuff = _G.UnitDebuff
local UnitIsUnit = _G.UnitIsUnit
local IsSpellKnownOrOverridesKnown = _G.IsSpellKnownOrOverridesKnown
local unpack = _G.unpack

local LPS = oUF_Adirelle.GetLib("LibPlayerSpells-1.0")
local C = LPS.constants

local PLAYER = bor(C.PERSONAL, C.HELPFUL)
local PET = bor(C.PET, C.HELPFUL)
local FRIEND = C.HELPFUL
local FOE = C.HARMFUL
local DEBUFFS = false
local BUFFS = true

local Dispels = {}
oUF_Adirelle.Dispels = Dispels

local cat = "DISPEL " .. oUF_Adirelle.playerClass
for spellID, flags, _, _, _, _, dispels in LPS:IterateSpells("HELPFUL HARMFUL PERSONAL PET", cat) do
	Dispels[spellID] = { band(flags, LPS.masks.TARGETING), dispels }
end

local function noop()
end

if next(Dispels) == nil then
	-- Player cannot dispel: define dummy functions and bail out
	oUF_Adirelle.IsDispellable = noop
	oUF_Adirelle.CanDispel = noop
	oUF_Adirelle.IterateDispellableDebuffs = function()
		return noop
	end
	return
end

local DispelFlags = { Magic = C.MAGIC, Poison = C.POISON, Curse = C.CURSE, Disease = C.DISEASE }
local TargetsByType = { Magic = 0, Poison = 0, Curse = 0, Disease = 0 }

-- Update the tests according to known spells
local function Update()
	for k in pairs(TargetsByType) do
		TargetsByType[k] = 0
	end
	for spellID, data in pairs(Dispels) do
		if IsSpellKnownOrOverridesKnown(spellID) or IsSpellKnownOrOverridesKnown(spellID, true) then
			local targets, dispels = unpack(data)
			for t, f in pairs(DispelFlags) do
				if band(dispels, f) ~= 0 then
					TargetsByType[t] = bor(TargetsByType[t], targets)
				end
			end
		end
	end
	oUF_Adirelle:Debug("dispel targets", TargetsByType)
end

oUF_Adirelle:RegisterEvent("PLAYER_ENTERING_WORLD", Update)
oUF_Adirelle:RegisterEvent("PVP_TIMER_UPDATE", Update)
oUF_Adirelle:RegisterEvent("SPELLS_CHANGED", Update)
Update()

local function UnitTargetType(unit)
	if type(unit) ~= "string" or unit == "" then
		return 0
	elseif UnitIsUnit(unit, "player") then
		return PLAYER, DEBUFFS
	elseif UnitIsUnit(unit, "pet") then
		return PET, DEBUFFS
	elseif UnitCanAttack(unit, "player") then
		return FOE, BUFFS
	elseif UnitCanAssist("player", unit) then
		return FRIEND, DEBUFFS
	end
	return 0
end

function oUF_Adirelle.IsDispellable(debuffType)
	return not not (debuffType and DispelFlags[debuffType])
end

function oUF_Adirelle.CanDispel(unit, isBuff, debuffType)
	local targets = debuffType and TargetsByType[debuffType]
	if not targets then
		return false
	end
	local targetType, auraType = UnitTargetType(unit)
	return auraType == isBuff and band(targets, targetType) ~= 0
end

function oUF_Adirelle.IterateDispellableDebuffs(unit)
	local targetType, auraType = UnitTargetType(unit)
	if auraType ~= DEBUFFS then
		return noop
	end
	local function iter(_, i)
		repeat
			i = i + 1
			local name, icon, count, dType, duration, expires, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(unit, i)
			if name and dType and TargetsByType[dType] then
				local canDispel = band(TargetsByType[dType], targetType) ~= 0
				return i, canDispel, icon, count, dType, duration, expires, unitCaster, spellId, isBossDebuff
			end
		until not name
	end
	return iter, nil, 0
end

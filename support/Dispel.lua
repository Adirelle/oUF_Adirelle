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

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local next = _G.next
local pairs = _G.pairs
local band = _G.bit.band
local bor = _G.bit.bor
local UnitCanAttack = _G.UnitCanAttack
local UnitCanAssist = _G.UnitCanAssist
local UnitBuff = _G.UnitBuff
local UnitDebuff = _G.UnitDebuff
--GLOBALS>

local LPS = oUF_Adirelle.GetLib('LibPlayerSpells-1.0')
local C = LPS.constants

local Dispels = {}
oUF_Adirelle.Dispels = Dispels

local base = bor(C.DISPEL, C[oUF_Adirelle.playerClass])
for i, target in pairs{C.HELPFUL, C.HARMFUL, C.PERSONAL, C.PET} do
    for spellID, _, _, _, _, _, dispels in LPS:IterateSpells(nil, bor(base, target)) do
        Dispels[spellID] = bor(target, dispels)
    end
end

local function noop() return end

if next(Dispels) == nil then
    -- This class cannot dispel, use short funcs
    oUF_Adirelle.IsDispellable =  function() return false end
    oUF_Adirelle.CanDispel = oUF_Adirelle.IsDispellable
    oUF_Adirelle.IterateDispellableAuras = function() return noop end
    return
end

local DispelFlags = { Magic = C.MAGIC, Poison = C.POISON, Curse = C.CURSE, Disease = C.DISEASE }
local DispelByType = { Magic = 0, Poison = 0, Curse = 0, Disease = 0 }

-- Update the tests according to known spells
oUF_Adirelle:RegisterEvent('SPELLS_CHANGED', function()
    for k in pairs(DispelByType) do
        DispelByType[k] = 0
    end
    for spellID, flags in pairs(Dispels) do
        if IsSpellKnown(spellID, false) or IsSpellKnown(spellID, true) then
            for t, f in pairs(DispelFlags) do
                DispelByType[t] = bor(DispelByType[t], flags)
            end
        end
	end
end)

local function UnitCat(unit)
    if type(unit) ~= "string" or unit == "" then
        return 0
    elseif UnitIsUnit(unit, "player") then
        return bor(C.PERSONAL, C.HELPFUL), false
    elseif UnitIsUnit(unit, "pet") then
        return bor(C.PET, C.HELPFUL), false
    elseif UnitCanAttack(unit, "player") then
        return C.HARMFUL, true
    elseif UnitCanAssist("player", unit) then
        return C.HELPFUL, false
    end
    return 0
end

function oUF_Adirelle.IsDispellable(debuffType)
    return not not (debuffType and DispelFlags[debuffType])
end

function oUF_Adirelle.CanDispel(unit, isBuff, debuffType)
    local flags = debuffType and DispelByType[debuffType]
    if not flags then return false end
    local unitCat, forBuff = UnitCat(unit)
    return isBuff == forBuff and band(flags, unitCat) ~= 0
end

function oUF_Adirelle.IterateDispellableAuras(unit, buffs)
    local unitCat = UnitCat(unit)
    local offensive = (unitCat == C.HARMFUL)
    if offensive ~= buffs then
        -- Cannot dispel enemy debuffs nor ally buffs
        return noop
    end
    local getAura = buffs and UnitBuff or UnitDebuff
    local function iter(_, index)
        repeat
            index = index + 1
            local name, rank, icon, count, debuffType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = getAura(index)
            if name and debuffType and DispelFlags[debuffType] then
                local canDispel = band(DispelByType[debuffType], unitCat) ~= 0
                return index, name, canDispel, rank, icon, count, debuffType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
            end
        until not name
    end
    return iter, nil, 0
end

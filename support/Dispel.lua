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

local LibPlayerSpells = oUF_Adirelle.GetLib('LibPlayerSpells-1.0')

local ALLY = true
local ENEMY = false

local Dispels = {}
oUF_Adirelle.Dispels = Dispels

for i, target in pairs{"HELPFUL", "HARMFUL", "PERSONAL", "PET"} do
    for spellID, _, _, _, categories in LibPlayerSpells:IterateSpells("", strjoin(" ", "DISPEL", oUF_Adirelle.playerClass, target)) do
        Dispels[spellID] = {target, categories}
    end
end

local TypeToCategory = {
    Magic   = LibPlayerSpells.constants.MAGIC,
    Poison  = LibPlayerSpells.constants.POISON,
    Curse   = LibPlayerSpells.constants.CURSE,
    Disease = LibPlayerSpells.constants.DISEASE,
}

local DispelCategories = { HELPFUL = 0, HARMFUL = 0, PET = 0, PERSONAL = 0 }

local function UnitCat(unit)
    if not unit then
        return nil
    elseif UnitIsUnit(unit, "player") then
        return "PERSONAL"
    elseif UnitIsUnit(unit, "pet") then
        return "PET"
    elseif UnitCanAttack(unit, "player") then
        return "HARMFUL"
    elseif UnitCanAssist("player", unit) then
        return "HELPFUL"
    end
    return nil
end

function oUF_Adirelle.IsDispellable(debuffType)
    return debuffType and TypeToCategory[debuffType] ~= nil
end

function oUF_Adirelle.CanDispel(unit, debuffType)
    if not unit or not debuffType then
        return false
    end
    local debuffCat = TypeToCategory[debuffType]
    if not debuffCat then
        return false
    end
    local unitCat = UnitCat(unit)
    if not unitCat then
        return false
    end
    return band(debuffCat, DispelCategories[unitCat]) ~= 0
end

local function noop() return end

function oUF_Adirelle.IterateDispellableAuras(unit, buffs)
    local unitCat = UnitCat(unit)
    local offensive = unitCat == "HARMFUL"
    if offensive ~= buffs then
        -- Cannot dispel enemy debuffs nor ally buffs
        return noop
    end
    local dispellable = DispelCategories[unitCat]
    local getAura = buffs and UnitBuff or UnitDebuff
    local function iter(_, index)
        repeat
            index = index + 1
            local name, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = getAura(index)
            if name and dispelType then
                local canDispel = band(TypeToCategory[dispelType], dispellable) ~= 0
                return index, name, canDispel, rank, icon, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
            end
        until not name
    end
    return iter, f, 0
end

if not next(Dispels) then
    -- This class has no dispel spells, don't bother updating the categories
    return
end

-- Update the tests according to known spells

local function SPELLS_CHANGED()
    for target in pairs(DispelCategories) do
        DispelCategories[target] = 0
    end
    for spellID, data in pairs(Dispels) do
        if IsSpellKnown(spellID, false) or IsSpellKnown(spellID, true) then
            local target, cats = unpack(data)
            DispelCategories[target] = bor(categories[target], cats)
            if target == "HELPFUL" then
                DispelCategories["PET"] = bor(categories["PET"], cats)
                DispelCategories["PERSONAL"] = bor(categories["PERSONAL"], cats)
            end
        end
	end
end

oUF_Adirelle:RegisterEvent('SPELLS_CHANGED', SPELLS_CHANGED)

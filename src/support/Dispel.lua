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
local LS = oUF_Adirelle.GetLib('LibSpellbook-1.0')
local C = LPS.constants

local Dispels = {}
oUF_Adirelle.Dispels = Dispels

for spellID, flags, _, _, _, _, dispels in LPS:IterateSpells("HELPFUL HARMFUL PERSONAL PET", "DISPEL "..oUF_Adirelle.playerClass) do
    Dispels[spellID] = {band(flags, LPS.masks.TARGETING), dispels}
end

local function noop() end

if next(Dispels) == nil then
    -- Player cannot dispel: define dummy functions and bail out
    oUF_Adirelle.IsDispellable = noop
    oUF_Adirelle.CanDispel = noop
    oUF_Adirelle.IterateDispellableDebuffs = function() return noop end
    return
end

local DispelFlags = { Magic = C.MAGIC, Poison = C.POISON, Curse = C.CURSE, Disease = C.DISEASE }
local TargetsByType = { Magic = 0, Poison = 0, Curse = 0, Disease = 0 }

-- Update the tests according to known spells
LS.RegisterCallback(oUF_Adirelle, 'LibSpellbook_Spells_Changed', function(...)
    for k in pairs(TargetsByType) do
        TargetsByType[k] = 0
    end
    for spellID, data in pairs(Dispels) do
        if LS:IsKnown(spellID) then
            local targets, dispels = unpack(data)
            for t, f in pairs(DispelFlags) do
                if band(dispels, f) ~= 0 then
                    TargetsByType[t] = bor(TargetsByType[t], targets)
                end
            end
        end
	end
end)

local PLAYER = bor(C.PERSONAL, C.HELPFUL)
local PET = bor(C.PET, C.HELPFUL)
local FRIEND = C.HELPFUL
local FOE = C.HARMFUL
local DEBUFFS = false
local BUFFS = true

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
    if not targets then return false end
    local targetType, auraType = UnitTargetType(unit)
    return auraType == isBuff and band(targets, targetType) ~= 0
end

function oUF_Adirelle.IterateDispellableDebuffs(unit)
    local targetType, auraType = UnitTargetType(unit)
    if auraType ~= DEBUFFS then
        return noop
    end
    local function iter(unit, index)
        repeat
            index = index + 1
			local name, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId, _, isBossDebuff = UnitDebuff(unit, index)
            if name and debuffType and TargetsByType[debuffType] then
                local canDispel = band(TargetsByType[debuffType], targetType) ~= 0
                return index, canDispel, icon, count, debuffType, duration, expirationTime, unitCaster, spellId, isBossDebuff
            end
        until not name
    end
    return iter, unit, 0
end

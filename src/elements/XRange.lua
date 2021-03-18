--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

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

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local CheckInteractDistance = assert(_G.CheckInteractDistance, "_G.CheckInteractDistance is undefined")
local CreateFromMixins = assert(_G.CreateFromMixins, "_G.CreateFromMixins is undefined")
local error = assert(_G.error, "_G.error is undefined")
local format = assert(_G.format, "_G.format is undefined")
local geterrorhandler = assert(_G.geterrorhandler, "_G.geterrorhandler is undefined")
local GetSpecialization = assert(_G.GetSpecialization, "_G.GetSpecialization is undefined")
local GetSpecializationInfo = assert(_G.GetSpecializationInfo, "_G.GetSpecializationInfo is undefined")
local IsSpellKnownOrOverridesKnown = assert(_G.IsSpellKnownOrOverridesKnown, "_G.IsSpellKnownOrOverridesKnown is undefined")
local loadstring = assert(_G.loadstring, "_G.loadstring is undefined")
local next = assert(_G.next, "_G.next is undefined")
local SpellMixin = assert(_G.SpellMixin, "_G.SpellMixin is undefined")
local tinsert = assert(_G.tinsert, "_G.tinsert is undefined")
local tostring = assert(_G.tostring, "_G.tostring is undefined")
local type = assert(_G.type, "_G.type is undefined")
local UnitCanAssist = assert(_G.UnitCanAssist, "_G.UnitCanAssist is undefined")
local UnitCanAttack = assert(_G.UnitCanAttack, "_G.UnitCanAttack is undefined")
local UnitInRange = assert(_G.UnitInRange, "_G.UnitInRange is undefined")
local UnitIsConnected = assert(_G.UnitIsConnected, "_G.UnitIsConnected is undefined")
local UnitIsCorpse = assert(_G.UnitIsCorpse, "_G.UnitIsCorpse is undefined")
local UnitIsUnit = assert(_G.UnitIsUnit, "_G.UnitIsUnit is undefined")
local UnitIsVisible = assert(_G.UnitIsVisible, "_G.UnitIsVisible is undefined")
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

-- Declare our color
oUF.colors.outOfRange = { 0.4, 0.4, 0.4 }

local function DefaultRangeCheck(unit)
	local inRange, checked = UnitInRange(unit)
	if checked then
		return inRange
	end
	return CheckInteractDistance(unit, 4)
end

local function AddSpellTest(spellID, ...)
	if not spellID then
		return "nil"
	end
	return format("IsSpellInRange(%d, unit) or ", spellID) .. AddSpellTest(...)
end

local function KeepKnown(spellID, ...)
	if not spellID then
		return
	end
	if IsSpellKnownOrOverridesKnown(spellID) then
		return spellID, KeepKnown(...)
	end
	return KeepKnown(...)
end

-- Tester builder
local function BuildCheckFunc(...)
	local spellTests = AddSpellTest(KeepKnown(...)):gsub("or nil", "")
	if spellTests == "" or spellTests == "nil" then
		return DefaultRangeCheck, "DefaultRangeCheck"
	end
	local code = "local DefaultRangeCheck = ... return function (unit) local inRange = "
		.. spellTests
		.. " if inRange ~= nil then return inRange == 1 end return DefaultRangeCheck(unit) end"
	local func, err = loadstring(code)
	if func then
		return func(DefaultRangeCheck), code
	end
	error(err, 3)
end

local EMPTY = {}
local checks = {
	FRIENDLY = DefaultRangeCheck,
	HOSTILE = DefaultRangeCheck,
	RESURRECT = DefaultRangeCheck,
	PET = DefaultRangeCheck,
}

local RANGE_SPELLS = {}

local function UpdateRangeChecks()
	oUF:Factory(function()
		local spec = GetSpecialization()
		local specID = spec and GetSpecializationInfo(spec)
		if not specID then
			return
		end
		local classSpells = RANGE_SPELLS["*"] or EMPTY
		local specSpells = RANGE_SPELLS[specID] or EMPTY

		for key in next, checks do
			local spells = specSpells[key] or classSpells[key] or EMPTY
			local func, code = BuildCheckFunc(unpack(spells))
			oUF_Adirelle.Debug("XRange", key, code)
			checks[key] = func
		end
	end)
end

-- Load spell info for the current class
do
	local spell = CreateFromMixins(SpellMixin)
	local numSpells = 0
	local waiting = false

	local function Done()
		numSpells = numSpells - 1
		if waiting and numSpells == 0 then
			waiting = false
			UpdateRangeChecks()
		end
	end

	local function QuerySpell(spec, key, spellID)
		spell:SetSpellID(spellID)
		if spell:IsSpellEmpty() then
			geterrorhandler()(format(
				"XRange %s[%q][%q]: unknown spell #%d",
				oUF_Adirelle.playerClass,
				spec,
				tostring(key),
				spellID
			))
			return
		end
		if not RANGE_SPELLS[spec] then
			RANGE_SPELLS[spec] = {}
		end
		if not RANGE_SPELLS[spec][key] then
			RANGE_SPELLS[spec][key] = {}
		end
		numSpells = numSpells + 1
		spell:ContinueOnSpellLoad(function()
			tinsert(RANGE_SPELLS[spec][key], spellID)
			Done()
		end)
	end

	local function SetKeySpells(spec, key, spellIDs)
		for _, spellID in next, spellIDs do
			QuerySpell(spec, key, spellID)
		end
	end

	local function SetSpecSpells(spec, specSpellIDs)
		for key, spellIDs in next, specSpellIDs do
			if type(spellIDs) == "number" then
				SetKeySpells(spec, key, { spellIDs })
			else
				SetKeySpells(spec, key, spellIDs)
			end
		end
	end

	local function SetRangeSpells(spells)
		for spec, specSpellIDs in next, spells[oUF_Adirelle.playerClass] do
			SetSpecSpells(spec, specSpellIDs)
		end
		if numSpells == 0 then
			UpdateRangeChecks()
		else
			waiting = true
		end
	end

	SetRangeSpells({
		PRIEST = {
			["*"] = {
				FRIENDLY = 2061, -- Flash Heal
				HOSTILE = 589, -- Shadow Word: Pain
				RESURRECT = 2006, -- Resurrection
			},
		},
		DRUID = {
			["*"] = {
				FRIENDLY = 774, -- Rejuvenation
				HOSTILE = 5176, -- Wrath
				RESURRECT = 20484, -- Rebirth
			},
		},
		PALADIN = {
			["*"] = {
				FRIENDLY = 19750, -- Flash of Light
				HOSTILE = 62124, -- Hand of Reckoning
				RESURRECT = 7328, -- Redemption
			},
		},
		HUNTER = {
			["*"] = {
				HOSTILE = 75, -- Auto Shot
				PET = 136, -- Mend Pet
			},
			[255] = { -- Survival
				HOSTILE = { 186270, 190925 }, -- Raptor Strike or Harpoon
			},
		},
		SHAMAN = {
			["*"] = {
				FRIENDLY = 51886, -- Cleanse Spirit
				HOSTILE = 403, -- Lightning Bolt
				RESURRECT = 2008, -- Ancestral Spirit
			},
		},
		WARLOCK = {
			["*"] = {
				HOSTILE = 686, -- Shadow Bolt
				FRIENDLY = 5697, -- Unending Breath
				PET = 755, -- Health Funnel
			},
		},
		MAGE = {
			["*"] = {
				HOSTILE = 133, --  Fireball
				FRIENDLY = 475, -- Remove Curse
			},
		},
		DEATHKNIGHT = {
			["*"] = {
				HOSTILE = 49576, -- Death grip
				RESURRECT = 61999, -- Raise Ally
			},
		},
		DEMONHUNTER = {
			["*"] = {},
		},
		ROGUE = {
			["*"] = {
				HOSTILE = { 1752, 121733 }, -- Sinister Strike or Throw
			},
		},
		WARRIOR = {
			["*"] = {
				HOSTILE = { 1464, 100 }, -- Slam (melee) or Charge
			},
		},
		MONK = {
			["*"] = {
				FRIENDLY = 116670, -- Vivify
				HOSTILE = 117952, -- Crackling Jade Lightning
				RESURRECT = 115178, -- Resuscitate
			},
		},
	})
end

local function RangeStatus(unit)
	if UnitIsUnit(unit, "player") then
		return "INRANGE"
	elseif not UnitIsConnected(unit) then
		return "DISCONNECTED"
	elseif not UnitIsVisible(unit) then
		return "OUTOFSCOPE"
	end
	local check
	if UnitCanAttack("player", unit) then
		check = checks.HOSTILE
	elseif UnitIsUnit(unit, "pet") then
		check = checks.PET
	elseif UnitIsCorpse(unit) and UnitCanAssist("player", unit) then
		check = checks.RESURRECT
	elseif UnitCanAssist("player", unit) then
		check = checks.FRIENDLY
	end
	return (check or DefaultRangeCheck)(unit) and "INRANGE" or "OUTOFRANGE"
end

local function Update(frame, event, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame.XRange
	local status = RangeStatus(frame.unit)
	if element.status ~= status or event == "ForceUpdate" then
		element.status = status
		element:SetShown(status == "OUTOFRANGE" or status == "OUTOFSCOPE")
		if element.PostUpdate then
			element:PostUpdate(event, frame.unit, status)
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate")
end

local function NOOP()
end

local function Enable(frame)
	local element = frame.XRange
	if not element then
		return
	end
	element.__owner, element.ForceUpdate = frame, ForceUpdate
	element:Hide()
	if frame.unit == "player" then
		element.ForceUpdate = NOOP
		return
	end
	if not element.ticker then
		frame:RegisterColor(element, "outOfRange")
		element.ticker = frame:CreateTicker(0.25, Update, "Tick")
	end
	element.ticker:Play()
	return true
end

local function Disable(frame)
	local element = frame.XRange
	if not element then
		return
	end
	element.ticker:Stop()
end

oUF:AddElement("XRange", Update, Enable, Disable)

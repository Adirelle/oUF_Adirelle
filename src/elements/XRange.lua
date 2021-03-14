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
local CheckInteractDistance = assert(_G.CheckInteractDistance)
local CreateFrame = assert(_G.CreateFrame)
local format = assert(_G.format)
local geterrorhandler = assert(_G.geterrorhandler)
local GetSpecialization = assert(_G.GetSpecialization)
local GetSpecializationInfo = assert(_G.GetSpecializationInfo)
local GetSpellInfo = assert(_G.GetSpellInfo)
local IsLoggedIn = assert(_G.IsLoggedIn)
local IsSpellInRange = assert(_G.IsSpellInRange)
local next = assert(_G.next)
local pairs = assert(_G.pairs)
local type = assert(_G.type)
local UnitCanAssist = assert(_G.UnitCanAssist)
local UnitCanAttack = assert(_G.UnitCanAttack)
local UnitExists = assert(_G.UnitExists)
local UnitInRange = assert(_G.UnitInRange)
local UnitIsConnected = assert(_G.UnitIsConnected)
local UnitIsCorpse = assert(_G.UnitIsCorpse)
local UnitIsUnit = assert(_G.UnitIsUnit)
local UnitIsVisible = assert(_G.UnitIsVisible)
local unpack = assert(_G.unpack)
--GLOBALS>

-- Declare our color
oUF.colors.outOfRange = { 0.4, 0.4, 0.4 }

-- Per class and specialization spells
local RANGE_SPELLS = {
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
			HOSTILE = { 78, 100 }, -- Heroic Strike (melee) or Charge
		},
	},
	MONK = {
		["*"] = {
			FRIENDLY = 116670, -- Vivify
			HOSTILE = 117952, -- Crackling Jade Lightning
			RESURRECT = 115178, -- Resuscitate
		},
	},
}

local INTERACT_RANGE = 4
local function DefaultRangeCheck(unit)
	local inRange, checked = UnitInRange(unit)
	if checked then
		return inRange
	else
		return CheckInteractDistance(unit, INTERACT_RANGE)
	end
end

local warned = {}
local function BuildSingleCheckFunc(spell)
	if not spell then
		return
	end
	local name = GetSpellInfo(spell)
	if not name then -- Does not exist anymore (removed)
		if not warned[spell] then
			warned[spell] = true
			geterrorhandler()(format(
				[[
						XRange:CheckSpell: the spell #%s  has been removed; it cannot be used for range checking.
						See https://github.com/Adirelle/oUF_Adirelle/issues/13
					]],
				spell
			))
		end
		return
	end
	if not GetSpellInfo(name) then
		-- player does not known this spell
		oUF_Adirelle:Debug(
			"XRange:CheckSpell: the spell ''",
			name,
			"' is unknown to player; do not use it for range checks."
		)
		return
	end
	return function(unit)
		local inRange = IsSpellInRange(name, unit)
		if inRange ~= nil then
			return inRange == 1
		else
			return DefaultRangeCheck(unit)
		end
	end
end

local function BuildMultiCheckFunc(spell, ...)
	if not spell then
		return
	end
	local head, tail = BuildSingleCheckFunc(spell), BuildMultiCheckFunc(...)
	if head and tail then
		return function(unit)
			return head(unit) or tail(unit)
		end
	end
	return head or tail
end

local function BuildCheckFunc(spells)
	if type(spells) == "table" then
		return BuildMultiCheckFunc(unpack(spells))
	end
	return BuildSingleCheckFunc(spells)
end

local EMPTY = {}
local checks = {
	FRIENDLY = DefaultRangeCheck,
	HOSTILE = DefaultRangeCheck,
	RESURRECT = DefaultRangeCheck,
}

local function UpdateRangeCheck()
	local specID = GetSpecializationInfo(GetSpecialization())
	local classSpells = RANGE_SPELLS[oUF_Adirelle.playerClass]["*"]
	local specSpells = RANGE_SPELLS[oUF_Adirelle.playerClass][specID] or EMPTY

	for t in pairs(checks) do
		local spell = specSpells[t] or classSpells[t]
		checks[t] = BuildCheckFunc(spell) or DefaultRangeCheck
	end
end

local function IsInRange(unit)
	if not UnitExists(unit) then
		return false
	elseif UnitIsUnit(unit, "player") or not UnitIsConnected(unit) then
		return true
	elseif not UnitIsVisible(unit) then
		return false
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
	return (check or DefaultRangeCheck)(unit)
end

local objects = {}
local updateFrame
local timer = 0

local function Update(self, event, unit)
	if unit and unit ~= self.unit then
		return
	end
	local xrange = self.XRange
	local inRange = IsInRange(self.unit)
	if inRange then
		if xrange:IsShown() or event == "ForceUpdate" then
			xrange:Hide()
		else
			return
		end
	else
		if not xrange:IsShown() or event == "ForceUpdate" then
			xrange:Show()
		else
			return
		end
	end
	if xrange.PostUpdate then
		xrange:PostUpdate(event, self.unit, inRange)
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate")
end

local function OnUpdate(self, elapsed)
	if timer > 0 then
		timer = timer - elapsed
	else
		timer = 0.25
		for frame in next, objects do
			if frame:IsShown() then
				Update(frame, "OnUpdate", frame.unit)
			end
		end
		if not next(objects) then
			self:Hide()
		end
	end
end

local function Initialize()
	local LS = oUF_Adirelle.GetLib("LibSpellbook-1.0")
	LS.RegisterCallback(oUF_Adirelle, "LibSpellbook_Spells_Changed", UpdateRangeCheck)

	updateFrame:UnregisterEvent("PLAYER_LOGIN")
	updateFrame:SetScript("OnEvent", nil)
	updateFrame:SetScript("OnUpdate", OnUpdate)
end

local function NOOP()
end

local function Enable(self)
	local xrange = self.XRange
	if xrange then
		if self.unit == "player" then
			xrange.ForceUpdate = NOOP
			return
		end
		if not updateFrame then
			updateFrame = CreateFrame("Frame")
			-- Postpone initialization so all spells are available
			if IsLoggedIn() then
				Initialize()
			else
				updateFrame:RegisterEvent("PLAYER_LOGIN")
				updateFrame:SetScript("OnEvent", Initialize)
			end
		end
		updateFrame:Show()
		xrange.__owner, xrange.ForceUpdate = self, ForceUpdate
		xrange:Hide()
		if not objects[self] then
			self:RegisterColor(xrange, "outOfRange")
			objects[self] = true
		end
		return true
	end
end

local function Disable(self)
	if objects[self] then
		objects[self] = nil
		self.XRange:Hide()
	end
end

oUF:AddElement("XRange", Update, Enable, Disable)

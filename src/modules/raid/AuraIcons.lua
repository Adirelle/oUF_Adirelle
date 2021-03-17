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

local _, private = ...

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)

--<GLOBALS
local pairs = assert(_G.pairs, "_G.pairs is undefined")
local strmatch = assert(_G.strmatch, "_G.strmatch is undefined")
--GLOBALS>

local SMALL_ICON_SIZE = private.SMALL_ICON_SIZE
local INSET = private.INSET

local GetAnyAuraFilter = private.GetAnyAuraFilter

local band = _G.bit.band
local LPS = oUF_Adirelle.GetLib("LibPlayerSpells-1.0")
local requiredFlags = oUF_Adirelle.playerClass .. " AURA"
local rejectedFlags = "INTERRUPT DISPEL BURST SURVIVAL HARMFUL"
local INVERT_AURA = LPS.constants.INVERT_AURA
local UNIQUE_AURA = LPS.constants.UNIQUE_AURA

local anchors = { "TOPLEFT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMLEFT", "TOP", "RIGHT", "BOTTOM", "LEFT" }

local filters = {}
local defaultAnchors = {}
local count = 0

local ExpandFlags
do
	local C = LPS.constants

	local function expandSimple2(flags, n, ...)
		if not n then
			return
		end
		local v = C[n]
		if band(flags, v) ~= 0 then
			return n, expandSimple2(flags, ...)
		else
			return expandSimple2(flags, ...)
		end
	end

	local function expandSimple(flags, n, ...)
		if not n then
			if band(flags, C.DISPEL) ~= 0 then
				return expandSimple2(flags, "CURSE", "DISEASE", "MAGIC", "POISON")
			end
			if band(flags, C.CROWD_CTRL) ~= 0 then
				return expandSimple2(flags, "DISORIENT", "INCAPACITATE", "ROOT", "STUN", "TAUNT")
			end
			return expandSimple2(
				flags,
				"DEATHKNIGHT",
				"DEMONHUNTER",
				"DRUID",
				"HUNTER",
				"MAGE",
				"MONK",
				"PALADIN",
				"PRIEST",
				"ROGUE",
				"SHAMAN",
				"WARLOCK",
				"WARRIOR",
				"RACIAL"
			)
		end
		local v = C[n]
		if band(flags, v) ~= 0 then
			return n, expandSimple(flags, ...)
		else
			return expandSimple(flags, ...)
		end
	end

	function ExpandFlags(flags)
		return expandSimple(
			flags,
			"DISPEL",
			"CROWD_CTRL",
			"HELPFUL",
			"HARMFUL",
			"PERSONAL",
			"PET",
			"AURA",
			"INVERT_AURA",
			"UNIQUE_AURA",
			"COOLDOWN",
			"SURVIVAL",
			"BURST",
			"POWER_REGEN",
			"IMPORTANT",
			"INTERRUPT",
			"KNOCKBACK",
			"SNARE"
		)
	end
end

for spellId, flags in LPS:IterateSpells("HELPFUL PET", requiredFlags, rejectedFlags) do
	local auraFilter = band(flags, INVERT_AURA) ~= 0 and "HARMFUL" or "HELPFUL"
	if band(flags, UNIQUE_AURA) == 0 then
		auraFilter = auraFilter .. " PLAYER"
	end

	filters[spellId] = GetAnyAuraFilter(spellId, auraFilter)
	count = (count % #anchors) + 1
	defaultAnchors[spellId] = anchors[count]
end

oUF_Adirelle.ClassAuraIcons = {
	filters = filters,
	defaultAnchors = defaultAnchors,
}

private.CreateClassAuraIcons = function(self)
	self.ClassAuraIcons = {}
	for id, filter in pairs(oUF_Adirelle.ClassAuraIcons.filters) do
		local icon = self:CreateIcon(self.Overlay, SMALL_ICON_SIZE, true, true, true, false)
		self.ClassAuraIcons[id] = icon
		self:AddAuraIcon(icon, filter)
	end
end

private.LayoutClassAuraIcons = function(self, layout)
	for id, icon in pairs(self.ClassAuraIcons) do
		local anchor = layout.Raid.classAuraIcons[id] or oUF_Adirelle.ClassAuraIcons.defaultAnchors[id]
		icon:ClearAllPoints()
		if anchor and anchor ~= "HIDDEN" then
			local xOffset = strmatch(anchor, "LEFT") and INSET or strmatch(anchor, "RIGHT") and -INSET or 0
			local yOffset = strmatch(anchor, "BOTTOM") and INSET or strmatch(anchor, "TOP") and -INSET or 0
			icon:SetPoint(anchor, xOffset, yOffset)
		end
	end
end

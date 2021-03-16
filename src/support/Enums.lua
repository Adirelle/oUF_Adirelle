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

--<GLOBALS
local Enum = assert(_G.Enum, "_G.Enum is undefined")
--GLOBALS>

oUF_Adirelle.Enum = {}

oUF_Adirelle.Enum.PowerMap = {
	MANA = Enum.PowerType.Mana or 0,
	RAGE = Enum.PowerType.Rage or 1,
	FOCUS = Enum.PowerType.Focus or 2,
	ENERGY = Enum.PowerType.Energy or 3,
	COMBO_POINTS = Enum.PowerType.ComboPoints or 4,
	RUNES = Enum.PowerType.Runes or 5,
	RUNIC_POWER = Enum.PowerType.RunicPower or 6,
	SOUL_SHARDS = Enum.PowerType.SoulShards or 7,
	LUNAR_POWER = Enum.PowerType.LunarPower or 8,
	HOLY_POWER = Enum.PowerType.HolyPower or 9,
	ALTERNATE = Enum.PowerType.Alternate or 10,
	MAELSTROM = Enum.PowerType.Maelstrom or 11,
	CHI = Enum.PowerType.Chi or 12,
	INSANITY = Enum.PowerType.Insanity or 13,
	-- 14 obsolete
	-- 15 obsolete
	ARCANE_CHARGES = Enum.PowerType.ArcaneCharges or 16,
	FURY = Enum.PowerType.Fury or 17,
	PAIN = Enum.PowerType.Pain or 18,
	NONE = Enum.PowerType.None or -1,
	HEALTH = Enum.PowerType.HealthCost or -2,
}

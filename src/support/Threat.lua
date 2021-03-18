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
local UnitCanAttack = assert(_G.UnitCanAttack, "_G.UnitCanAttack is undefined")
local UnitDetailedThreatSituation = assert(_G.UnitDetailedThreatSituation, "_G.UnitDetailedThreatSituation is undefined")
local UnitThreatSituation = assert(_G.UnitThreatSituation, "_G.UnitThreatSituation is undefined")
--GLOBALS>

-- local LOW_THREAT = 0
local TAKING_AGGRO = 1
local LOOSING_AGGRO = 2
-- local TANKING = 3

local GetPlayerRole = assert(oUF_Adirelle.GetPlayerRole)

local function GetUnitThreat(unit)
	-- Get detailled threat info about enemy unit
	if UnitCanAttack("player", unit) then
		local _, status, percent = UnitDetailedThreatSituation("player", unit)
		return status, (percent or 0)
	end
	-- Get highest aggro of the non-enemy unit
	return UnitThreatSituation(unit), 100
end

-- Centralized "smart" threat
function oUF_Adirelle.GetThreatInfo(unit)
	local status, value = GetUnitThreat(unit)
	local warningStatus = GetPlayerRole() == "TANK" and LOOSING_AGGRO or TAKING_AGGRO
	return status, value, (status == warningStatus)
end

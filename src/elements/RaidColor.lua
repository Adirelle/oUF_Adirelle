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
local select = assert(_G.select, "_G.select is undefined")
local UnitClass = assert(_G.UnitClass, "_G.UnitClass is undefined")
local UnitHasVehicleUI = assert(_G.UnitHasVehicleUI, "_G.UnitHasVehicleUI is undefined")
local UnitIsCharmed = assert(_G.UnitIsCharmed, "_G.UnitIsCharmed is undefined")
local UnitIsConnected = assert(_G.UnitIsConnected, "_G.UnitIsConnected is undefined")
local UnitIsPlayer = assert(_G.UnitIsPlayer, "_G.UnitIsPlayer is undefined")
--GLOBALS>

local function GetColor(unit, colors)
	if not UnitIsConnected(unit) then
		return colors.disconnected
	elseif UnitHasVehicleUI(unit) then
		return colors.vehicle.name
	elseif UnitIsCharmed(unit) then
		return colors.charmed.name
	elseif UnitIsPlayer(unit) then
		return colors.class[select(2, UnitClass(unit))]
	end
	return colors.health
end

local function Update(frame, event, eventUnit)
	local unit = frame.realUnit or frame.unit
	if eventUnit and eventUnit ~= unit then
		return
	end
	unit = unit:gsub("pet", "")
	if unit == "" then
		unit = "player"
	end
	local color = GetColor(unit, frame.colors)
	local element = frame.RaidColor
	if element.color ~= color or event == "ForceUpdate" then
		element.color = color
		if element.PostUpdate then
			element:PostUpdate(color)
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate")
end

local function Enable(frame)
	local element = frame.RaidColor
	if not element then
		return
	end
	element.__owner, element.ForceUpdate = frame, ForceUpdate
	frame:RegisterEvent("UNIT_CONNECTION", Update)
	frame:RegisterEvent("UNIT_FACTION", Update)
	frame:RegisterEvent("PARTY_MEMBER_ENABLE", Update)
	frame:RegisterEvent("PARTY_MEMBER_DISABLE", Update)
	frame:RegisterEvent("UNIT_FLAGS", Update)
	frame:RegisterEvent("UNIT_ENTERED_VEHICLE", Update)
	frame:RegisterEvent("UNIT_EXITED_VEHICLE", Update)
	return true
end

local function Disable(frame)
	local element = frame.RaidColor
	if not element then
		return
	end
	frame:UnregisterEvent("UNIT_CONNECTION", Update)
	frame:UnregisterEvent("UNIT_FACTION", Update)
	frame:UnregisterEvent("PARTY_MEMBER_ENABLE", Update)
	frame:UnregisterEvent("PARTY_MEMBER_DISABLE", Update)
	frame:UnregisterEvent("UNIT_FLAGS", Update)
	frame:UnregisterEvent("UNIT_ENTERED_VEHICLE", Update)
	frame:UnregisterEvent("UNIT_EXITED_VEHICLE", Update)
end

oUF:AddElement("RaidColor", Update, Enable, Disable)

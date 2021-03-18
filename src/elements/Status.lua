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
local C_IncomingSummon = assert(_G.C_IncomingSummon, "_G.C_IncomingSummon is undefined")
local format = assert(_G.format, "_G.format is undefined")
local UnitHasIncomingResurrection = assert(_G.UnitHasIncomingResurrection, "_G.UnitHasIncomingResurrection is undefined")
local UnitHasVehicleUI = assert(_G.UnitHasVehicleUI, "_G.UnitHasVehicleUI is undefined")
local UnitIsCharmed = assert(_G.UnitIsCharmed, "_G.UnitIsCharmed is undefined")
local UnitIsConnected = assert(_G.UnitIsConnected, "_G.UnitIsConnected is undefined")
local UnitIsDead = assert(_G.UnitIsDead, "_G.UnitIsDead is undefined")
local UnitIsDeadOrGhost = assert(_G.UnitIsDeadOrGhost, "_G.UnitIsDeadOrGhost is undefined")
local UnitIsGhost = assert(_G.UnitIsGhost, "_G.UnitIsGhost is undefined")
local UnitIsPlayer = assert(_G.UnitIsPlayer, "_G.UnitIsPlayer is undefined")
local UnitPhaseReason = assert(_G.UnitPhaseReason, "_G.UnitPhaseReason is undefined")
--GLOBALS>

local function GetStatus(unit)
	if not UnitIsPlayer(unit) then
		return UnitIsDeadOrGhost(unit) and "DEAD" or nil
	elseif UnitHasIncomingResurrection(unit) then
		return "RESURRECTION"
	elseif not UnitIsConnected(unit) then
		return "DISCONNECTED"
	elseif C_IncomingSummon.IncomingSummonStatus(unit) ~= 0 then
		return format("SUMMON%d", C_IncomingSummon.IncomingSummonStatus(unit))
	elseif UnitIsDead(unit) then
		return "DEAD"
	elseif UnitIsGhost(unit) then
		return "GHOST"
	elseif UnitPhaseReason(unit) then
		return "OUTOFPHASE"
	elseif UnitHasVehicleUI(unit) then
		return "INVEHICLE"
	elseif UnitIsCharmed(unit) then
		return "CHARMED"
	end
end

local function Get(element)
	local frame = element.__owner
	return GetStatus(frame.realUnit or frame.unit)
end

local function Update(frame, event, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame.Status
	local status = element:Get()
	if element.status ~= status or event == "ForceUpdate" then
		element.status = status
		if element.PostUpdate then
			element:PostUpdate(status)
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate")
end

local function Enable(frame)
	local element = frame.Status
	if not element then
		return
	end
	element.__owner, element.ForceUpdate, element.Get = frame, ForceUpdate, Get
	frame:RegisterEvent("INCOMING_RESURRECT_CHANGED", Update)
	frame:RegisterEvent("INCOMING_SUMMON_CHANGED", Update)
	frame:RegisterEvent("PARTY_MEMBER_DISABLE", Update)
	frame:RegisterEvent("PARTY_MEMBER_ENABLE", Update)
	frame:RegisterEvent("UNIT_CONNECTION", Update)
	frame:RegisterEvent("UNIT_ENTERED_VEHICLE", Update)
	frame:RegisterEvent("UNIT_EXITED_VEHICLE", Update)
	frame:RegisterEvent("UNIT_FACTION", Update)
	frame:RegisterEvent("UNIT_FLAGS", Update)
	frame:RegisterEvent("UNIT_HEALTH", Update)
	frame:RegisterEvent("UNIT_PHASE", Update)
	return true
end

local function Disable(frame)
	local element = frame.Status
	if not element then
		return
	end
	frame:UnregisterEvent("INCOMING_RESURRECT_CHANGED", Update)
	frame:UnregisterEvent("INCOMING_SUMMON_CHANGED", Update)
	frame:UnregisterEvent("PARTY_MEMBER_DISABLE", Update)
	frame:UnregisterEvent("PARTY_MEMBER_ENABLE", Update)
	frame:UnregisterEvent("UNIT_AURA", Update)
	frame:UnregisterEvent("UNIT_CONNECTION", Update)
	frame:UnregisterEvent("UNIT_ENTERED_VEHICLE", Update)
	frame:UnregisterEvent("UNIT_EXITED_VEHICLE", Update)
	frame:UnregisterEvent("UNIT_FACTION", Update)
	frame:UnregisterEvent("UNIT_FLAGS", Update)
	frame:UnregisterEvent("UNIT_HEALTH", Update)
	frame:UnregisterEvent("UNIT_PHASE", Update)
end

oUF:AddElement("Status", Update, Enable, Disable)

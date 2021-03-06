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

Elements handled: .ThreatBar
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local GetThreatInfo = assert(oUF_Adirelle.GetThreatInfo)

local function Update(frame, event, unit)
	if unit and unit ~= frame.unit then
		return
	end
	local element = frame.ThreatBar

	local status, value, warning = GetThreatInfo(frame.unit)
	if status then
		element:SetValue(value)
		element:SetStatusBarColor(unpack(frame.colors.threat[status], 1, 3))
		element:Show()
	else
		element:Hide()
	end
	if element.PostUpdate then
		element:PostUpdate(frame.unit, status, value, warning)
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(frame)
	local element = frame.ThreatBar
	if not element then
		return
	end
	element.__owner = frame
	element.ForceUpdate = ForceUpdate
	element:Hide()
	frame:RegisterEvent("UNIT_PET", Update)
	frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
	frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
	return true
end

local function Disable(frame)
	local element = frame.ThreatBar
	if not element then
		return
	end
	element:Hide()
	frame:UnregisterEvent("UNIT_PET", Update)
	frame:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Update)
	frame:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
end

oUF:AddElement("ThreatBar", Update, Enable, Disable)

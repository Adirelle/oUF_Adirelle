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
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local GetThreatInfo = assert(oUF_Adirelle.GetThreatInfo)

local Update = function(frame, _, unit)
	if unit and unit ~= frame.unit then
		return
	end

	local element = frame.SmartThreat
	if element.PreUpdate then
		element:PreUpdate(frame.unit)
	end

	local status, value, warning = GetThreatInfo(frame.unit)
	if status and (element.showNoAggro or status > 0) then
		local a, r, g, b = 1.0, unpack(frame.colors.threat[status])
		if value and element.percentAsAlpha then
			a = (value / 100) * (element.highAlpha - element.lowAlpha) + element.lowAlpha
		end
		element:SetVertexColor(r, g, b, element.percentAsAlpha and value or 1.0)
		element:Show()
	else
		element:Hide()
	end

	if element.PostUpdate then
		return element:PostUpdate(frame.unit, status, value, warning)
	end
end

local Path = function(frame, ...)
	return (frame.SmartThreat.Override or Update)(frame, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate")
end

local Enable = function(frame)
	local element = frame.SmartThreat
	if element then
		element.__owner = frame
		element.ForceUpdate = ForceUpdate

		frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		frame:RegisterEvent("UNIT_TARGET", Path)
		element:Hide()

		return true
	end
end

local Disable = function(frame)
	local element = frame.SmartThreat
	if element then
		frame:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Path)
		frame:UnregisterEvent("UNIT_THREAT_LIST_UPDATE", Path)
		frame:UnregisterEvent("UNIT_TARGET", Path)
		element:Hide()
	end
end

oUF:AddElement("SmartThreat", Path, Enable, Disable)

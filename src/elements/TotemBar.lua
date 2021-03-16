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

Elements handled: .RuneBar
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local GetTime = assert(_G.GetTime, "_G.GetTime is undefined")
local GetTotemInfo = assert(_G.GetTotemInfo, "_G.GetTotemInfo is undefined")
local ipairs = assert(_G.ipairs, "_G.ipairs is undefined")
--GLOBALS>

local function OnUpdate(totem, elapsed)
	local timeLeft = totem:GetValue() - elapsed
	if timeLeft <= 0 then
		totem:Hide()
	else
		totem:SetValue(timeLeft)
	end
end

local function Update(self)
	for _, totem in ipairs(self.TotemBar) do
		local haveTotem, name, start, duration = GetTotemInfo(totem.totemType)
		if haveTotem and name and name ~= "" then
			totem:SetMinMaxValues(0, duration)
			totem:SetValue(start + duration - GetTime())
			totem:Show()
		else
			totem:Hide()
		end
	end
end

local function Enable(self)
	if self.TotemBar then
		self:RegisterEvent("PLAYER_TOTEM_UPDATE", Update)
		for _, totem in ipairs(self.TotemBar) do
			totem:Hide()
			totem:SetScript("OnUpdate", OnUpdate)
		end
		return true
	end
end

local function Disable(self)
	if self.TotemBar then
		self:UnregisterEvent("PLAYER_TOTEM_UPDATE", Update)
		self.TotemBar:Hide()
	end
end

oUF:AddElement("TotemBar", Update, Enable, Disable)

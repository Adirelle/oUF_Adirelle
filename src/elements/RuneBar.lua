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
local GetRuneCooldown = assert(_G.GetRuneCooldown)
local GetTime = assert(_G.GetTime)
local RuneFrame = assert(_G.RuneFrame)
local tonumber = assert(_G.tonumber)
--GLOBALS>

local function OnUpdate(rune)
	local now = GetTime()
	rune:SetValue(now)
	if now > rune.readyTime then
		rune:SetScript("OnUpdate", nil)
	end
end

local function RuneUpdate(self, _, index)
	local rune = self.RuneBar[index]
	if not rune then
		return
	end
	if rune.UpdateRuneColor then
		rune:UpdateRuneColor()
	end
	local start, duration, ready = GetRuneCooldown(index)
	if not ready then
		rune.duration = duration
		rune.readyTime = start + duration
		rune:SetMinMaxValues(start, start + duration)
		rune:SetScript("OnUpdate", OnUpdate)
	else
		rune:SetScript("OnUpdate", nil)
	end
end

local function Update(self, event, index)
	if not tonumber(index) then
		if self.unit ~= "player" then
			return self.RuneBar:Hide()
		else
			self.RuneBar:Show()
		end
		for i = 1, 6 do
			RuneUpdate(self, event, i)
		end
	else
		RuneUpdate(self, event, index)
	end
end

local function Enable(self)
	if self.RuneBar then
		self:RegisterEvent("RUNE_POWER_UPDATE", Update)
		self:RegisterEvent("RUNE_TYPE_UPDATE", Update)
		RuneFrame:Hide()
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:UnregisterAllEvents()
		return true
	end
end

local function Disable(self)
	if self.RuneBar then
		self:UnregisterEvent("RUNE_POWER_UPDATE", Update)
		self:UnregisterEvent("RUNE_TYPE_UPDATE", Update)
		self.RuneBar:Hide()
	end
end

oUF:AddElement("RuneBar", Update, Enable, Disable)

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
local GetXPExhaustion = assert(_G.GetXPExhaustion, "_G.GetXPExhaustion is undefined")
local IsResting = assert(_G.IsResting, "_G.IsResting is undefined")
local IsXPUserDisabled = assert(_G.IsXPUserDisabled, "_G.IsXPUserDisabled is undefined")
local pairs = assert(_G.pairs, "_G.pairs is undefined")
local UnitLevel = assert(_G.UnitLevel, "_G.UnitLevel is undefined")
local UnitXP = assert(_G.UnitXP, "_G.UnitXP is undefined")
local UnitXPMax = assert(_G.UnitXPMax, "_G.UnitXPMax is undefined")
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local mmin = assert(_G.math.min)

local colors = {
	resting = { 0.0, 1.0, 0.37 }, -- green
	normal = { 0.0, 0.75, 1.0 }, -- blue
	rested = { 0.0, 0.37, 0.5 }, -- darker blue
}

local function Update(self)
	local bar = self.ExperienceBar
	local restedBar = bar.Rested
	if UnitLevel("player") == _G.MAX_PLAYER_LEVEL then
		return self:DisableElement("Experience")
	elseif IsXPUserDisabled() then
		restedBar:Hide()
		return bar:Hide()
	else
		bar:Show()
	end
	local current, max, rested = UnitXP("player"), UnitXPMax("player"), GetXPExhaustion()
	bar:SetMinMaxValues(0, max)
	bar:SetValue(current)
	bar:SetStatusBarColor(unpack(IsResting() and bar.Colors.resting or bar.Colors.normal))
	if rested and rested > 0 then
		local total = mmin(current + rested, max)
		restedBar:SetStatusBarColor(unpack(bar.Colors.rested))
		restedBar:SetMinMaxValues(0, max)
		restedBar:SetValue(total)
		restedBar:Show()
	else
		restedBar:Hide()
	end
	if bar.UpdateText then
		bar.UpdateText(self, bar, current, max, rested, UnitLevel("player"))
	end
end

local function Path(self, ...)
	return (self.ExperienceBar.Update or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate")
end

local function Enable(self, unit)
	local bar = self.ExperienceBar
	if not bar then
		return
	elseif (unit and unit ~= "player") or UnitLevel("player") == _G.MAX_PLAYER_LEVEL then
		bar.Rested:Hide()
		bar:Hide()
		return
	end
	bar.ForceUpdate, bar.__owner = ForceUpdate, self

	bar.Colors = bar.Colors or {}
	for name, value in pairs(colors) do
		if not bar.Colors[name] then
			bar.Colors[name] = value
		end
	end

	self:RegisterEvent("PLAYER_LOGIN", Path, true)
	self:RegisterEvent("UPDATE_EXHAUSTION", Path, true)
	self:RegisterEvent("DISABLE_XP_GAIN", Path, true)
	self:RegisterEvent("ENABLE_XP_GAIN", Path, true)
	self:RegisterEvent("PLAYER_XP_UPDATE", Path, true)
	self:RegisterEvent("PLAYER_UPDATE_RESTING", Path, true)
	self:RegisterEvent("PLAYER_LEVEL_UP", Path, true)
	return true
end

local function Disable(self)
	local bar = self.ExperienceBar
	bar:Hide()
	bar.Rested:Hide()
	self:UnregisterEvent("PLAYER_LOGIN", Path)
	self:UnregisterEvent("UPDATE_EXHAUSTION", Path)
	self:UnregisterEvent("DISABLE_XP_GAIN", Path)
	self:UnregisterEvent("ENABLE_XP_GAIN", Path)
	self:UnregisterEvent("PLAYER_XP_UPDATE", Path)
	self:UnregisterEvent("PLAYER_UPDATE_RESTING", Path)
	self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
end

oUF:AddElement("Experience", Path, Enable, Disable)

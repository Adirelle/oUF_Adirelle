--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local GetXPExhaustion = _G.GetXPExhaustion
local IsResting = _G.IsResting
local IsXPUserDisabled = _G.IsXPUserDisabled
local pairs = _G.pairs
local UnitLevel = _G.UnitLevel
local UnitXP = _G.UnitXP
local UnitXPMax = _G.UnitXPMax
local unpack = _G.unpack
--GLOBALS>
local mmin = _G.min

local colors = {
	resting = { 0.0, 1.0, 0.37 }, -- green
	normal = { 0.0, 0.75, 1.0 }, -- blue
	rested = { 0.0, 0.37, 0.5 }, -- darker blue
}

local function Update(self, event)
	local bar = self.ExperienceBar
	local restedBar = bar.Rested
	if UnitLevel("player") == _G.MAX_PLAYER_LEVEL then
		return self:DisableElement('Experience')
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

	self:RegisterEvent('PLAYER_LOGIN', Path)
	self:RegisterEvent('UPDATE_EXHAUSTION', Path)
	self:RegisterEvent('DISABLE_XP_GAIN', Path)
	self:RegisterEvent('ENABLE_XP_GAIN', Path)
	self:RegisterEvent('PLAYER_XP_UPDATE', Path)
	self:RegisterEvent('PLAYER_UPDATE_RESTING', Path)
	self:RegisterEvent('PLAYER_LEVEL_UP', Path)
	return true
end

local function Disable(self)
	local bar = self.ExperienceBar
	bar:Hide()
	bar.Rested:Hide()
	self:UnregisterEvent('PLAYER_LOGIN', Path)
	self:UnregisterEvent('UPDATE_EXHAUSTION', Path)
	self:UnregisterEvent('DISABLE_XP_GAIN', Path)
	self:UnregisterEvent('ENABLE_XP_GAIN', Path)
	self:UnregisterEvent('PLAYER_XP_UPDATE', Path)
	self:UnregisterEvent('PLAYER_UPDATE_RESTING', Path)
	self:UnregisterEvent('PLAYER_LEVEL_UP', Path)
end

oUF:AddElement('Experience', Path, Enable, Disable)


--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local UnitLevel = UnitLevel
local IsXPUserDisabled = IsXPUserDisabled
local UnitXP = UnitXP
local UnitXPMax = UnitXPMax
local GetXPExhaustion = GetXPExhaustion

local colors = {
	resting = { 0.0, 0.1, 0.75 }, -- green
	normal = { 1.00, 0.0, 1.0 }, -- purple
	rested = { 0.0, 0.75, 1.0 }, -- blue
}

local function Update(self, event)
	local bar = self.ExperienceBar
	local restedBar = bar.Rested
	if UnitLevel("player") == MAX_PLAYER_LEVEL then
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
		local total = math.min(current + rested, max)
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


local function Enable(self, unit)
	local bar = self.ExperienceBar
	if not bar or (unit and unit ~= "player") or UnitLevel("player") == MAX_PLAYER_LEVEL then return end
	
	bar.Colors = bar.Colors or {}
	for name, value in pairs(colors) do
		if not bar.Colors[name] then
			bar.Colors[name] = value
		end
	end
	
	self:RegisterEvent('PLAYER_LOGIN', Update)
	self:RegisterEvent('UPDATE_EXHAUSTION', Update)
	self:RegisterEvent('DISABLE_XP_GAIN', Update)
	self:RegisterEvent('ENABLE_XP_GAIN', Update)
	self:RegisterEvent('PLAYER_XP_UPDATE', Update)
	self:RegisterEvent('PLAYER_UPDATE_RESTING', Update)
	self:RegisterEvent('PLAYER_LEVEL_UP', Update)
	return true
end

local function Disable(self)
	local bar = self.ExperienceBar
	bar:Hide()
	bar.Rested:Hide()
	self:UnregisterEvent('PLAYER_LOGIN', Update)
	self:UnregisterEvent('UPDATE_EXHAUSTION', Update)
	self:UnregisterEvent('DISABLE_XP_GAIN', Update)
	self:UnregisterEvent('ENABLE_XP_GAIN', Update)
	self:UnregisterEvent('PLAYER_XP_UPDATE', Update)
	self:UnregisterEvent('PLAYER_UPDATE_RESTING', Update)
	self:UnregisterEvent('PLAYER_LEVEL_UP', Update)
end

oUF:AddElement('Experience', Update, Enable, Disable)


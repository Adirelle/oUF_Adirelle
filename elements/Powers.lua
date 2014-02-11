 --[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: Powers

Options

	.frequentUpdates - Set to true to listen to UNIT_POWER_FREQUENT instead of UNIT_POWER

Sub-widgets

	.MANA .RAGE .FOCUS .ENERGY .RUNIC_POWER .SOUL_SHARDS
	.HOLY_POWER .CHI .SHADOW_ORBS .BURNING_EMBERS .DEMONIC_FURY
		There widgets are used to display the various powers.

Power sub-widget "interface"

	The power sub-widgets should implement the following methods:
		:SetMinMaxValues(min, max)
		:SetValue(current)
		:SetStatusBarColor(r, g, b, a)

Sub-widget hooks

	:Override(event, ...)           - Totally override the update.
	:PreUpdate(unit)                - Called just before updating
	:PostUpdate(unit, current, max) - Called just after updating

--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local pairs = _G.pairs
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local UnitIsConnected = _G.UnitIsConnected
local unpack = _G.unpack
--GLOBALS>

-- Set default colors for burning embers and demonic fury
if not oUF.colors.power.BURNING_EMBERS then
	oUF.colors.power.BURNING_EMBERS = { 175/255, 39/255, 5/255, 247/255, 190/255, 41/255 }
end
if not oUF.colors.power.DEMONIC_FURY then
	oUF.colors.power.DEMONIC_FURY = { 148/255, 36/255, 214/255 }
end

local RequiredClasses = {
	MANA           = { DRUID = true, MONK = true },
	CHI            = { MONK = true },
	SOUL_SHARDS    = { WARLOCK = true },
	BURNING_EMBERS = { WARLOCK = true },
	DEMONIC_FURY   = { WARLOCK = true },
	SHADOW_ORBS    = { PRIEST = true },
	HOLY_POWER     = { PALADIN = true },
}

local RequiredSpecializations = {
	MANA           = {
		-- Druid specs
		[102] = true, -- Balance
		[103] = true, -- Feral
		[104] = true, -- Guardian
		[105] = true, -- Restoration
		-- Monk specs
		[270] = true, -- Mistweaver
	},
	SOUL_SHARDS    = { [265] = true }, -- Affliction Warlock
	BURNING_EMBERS = { [267] = true }, -- Destruction Warlock
	DEMONIC_FURY   = { [266] = true }, -- Demonology Warlock
	SHADOW_ORBS    = { [258] = true }, -- Shadow Priest
}

local function ShouldShow(unit, powerIndex, powerType)
	local classes, specs = RequiredClasses[powerType], RequiredSpecializations[powerType]
	if classes then
		if not UnitIsPlayer(unit) then
			return false
		end
		local _, class = UnitClass(unit)
		--oUF:Debug('Class required for',  powerType, 'on', unit, 'class=', class, 'ok=', classes[class])
		if not classes[class] then
			return false
		end
	end
	if specs then
		if not UnitIsUnit(unit, 'player') or UnitLevel(unit) < 10 then
			return false
		end
		local specIndex = GetSpecialization()
		local spec = specIndex and GetSpecializationInfo(specIndex) or 0
		--oUF:Debug('Spec required for',  powerType, 'on', unit, 'spec=', spec, 'ok=', specs[spec])
		if not specs[spec] then
			return false
		end
	end
	return UnitIsConnected(unit) and UnitPowerType(unit) ~= powerIndex and (UnitPowerMax(unit, powerIndex) or 0) ~= 0
end

local function Update(self, event)
	local unit, powerIndex = self.__owner.unit, self.powerIndex

	if event ~= 'UNIT_POWER' and event ~= 'UNIT_POWER_FREQUENT' and event ~= 'UNIT_MAXPOWER' then
		self:SetShown(ShouldShow(unit, powerIndex, self.powerType))
	end
	if not self:IsVisible() then
		return
	end

	if self.PreUpdate then self:PreUpdate(unit) end

	local current, max = (UnitPower(unit, powerIndex, true) or 0), (UnitPowerMax(unit, powerIndex, true) or 0)
	self:SetMinMaxValues(0, max)
	self:SetValue(current)

	local t, r, g, b = oUF.colors.power[self.powerType]
	if not t or self.colorSmooth then
		r, g, b = oUF.ColorGradient(current, max, unpack(self.smoothGradient or oUF.colors.smooth))
	else
		r, g, b = unpack(t, 1, 3)
	end

	self:SetStatusBarColor(r, g, b)
	local bg = self.bg
	if bg then
		local mu = bg.multiplier or 1
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end

	if self.PostUpdate then self:PostUpdate(unit, current, max) end
end

-- Handled powers
local HandledPowers = {}
for powerType in pairs(RequiredClasses) do
	HandledPowers[powerType] = _G['SPELL_POWER_'..powerType]
end

local CommonPath = function(self, event, unit, ...)
	if unit ~= self.unit then return end
	local powers = self.Powers
	for powerType in pairs(HandledPowers) do
		local widget = powers[powerType]
		if widget then
			(widget.Override or Update)(widget, event, unit, ...)
		end
	end
end

local CommonForceUpdate = function(element)
	return CommonPath(element.__owner.Powers, 'ForceUpdate', element.__owner.unit)
end

local CommonPowerPath = function(self, event, unit, powerType, ...)
	if unit ~= self.unit then return end
	local widget = self.Powers[powerType]
	if widget then
		return (widget.Override or Update)(widget, event, unit, powerType, ...)
	end
end

local CommonEnable = function(self, unit)
	local powers = self.Powers
	if powers then
		powers.__owner = self
		powers.ForceUpdate = CommonForceUpdate
		local found = false
		for powerType, powerIndex in pairs(HandledPowers) do
			local widget = powers[powerType]
			if widget then
				widget.__owner = self
				widget.powerType = powerType
				widget.powerIndex = powerIndex
				widget:Show()
				found = true
			end
		end

		if self.SetShown then
			self:SetShown(found)
		end
		if not found then
			return false
		end

		if self.frequentUpdates and (unit == 'player' or unit == 'pet') then
			self:RegisterEvent('UNIT_POWER_FREQUENT', CommonPowerPath)
		else
			self:RegisterEvent('UNIT_POWER', CommonPowerPath)
		end
		self:RegisterEvent('UNIT_MAXPOWER', CommonPowerPath)

		self:RegisterEvent('UNIT_DISPLAYPOWER', CommonPath)
		self:RegisterEvent('UNIT_CONNECTION', CommonPath)
		if unit == "player" then
			self:RegisterEvent('UNIT_LEVEL', CommonPath)
			self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', CommonPath)
		end

		return true
	end
end

local CommonDisable = function(self)
	local powers = self.Powers
	if powers then
		for powerType in pairs(HandledPowers) do
			if powers[powerType] then
				powers[powerType]:Hide()
			end
		end

		self:UnregisterEvent('UNIT_POWER_FREQUENT', CommonPowerPath)
		self:UnregisterEvent('UNIT_POWER', CommonPowerPath)
		self:UnregisterEvent('UNIT_MAXPOWER', CommonPowerPath)

		self:UnregisterEvent('UNIT_DISPLAYPOWER', CommonPath)
		self:UnregisterEvent('UNIT_CONNECTION', CommonPath)
		self:UnregisterEvent('UNIT_LEVEL', CommonPath)
		self:UnregisterEvent('PLAYER_SPECIALIZATION_CHANGED', CommonPath)

		if self.Hide then
			self:Hide()
		end
	end
end

oUF:AddElement('Powers', CommonPath, CommonEnable, CommonDisable)

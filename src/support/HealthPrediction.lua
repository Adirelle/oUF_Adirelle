--[=[
Adirelle's oUF layout
(c) 2013-2021 Adirelle (adirelle@gmail.com)

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

local ALMOST_ZERO = 1e-8

local function SetMinMaxValues(bar, minValue, maxValue)
	if bar.minValue ~= minValue or bar.maxValue ~= maxValue then
		bar.minValue, bar.maxValue = minValue, maxValue
		bar:UpdateWidth()
	end
end

local function SetValue(bar, value)
	if bar.value ~= value then
		bar.value = value
		bar:UpdateWidth()
	end
end

local function UpdateWidth(bar)
	local value, maxValue = bar.value - bar.minValue, bar.maxValue - bar.minValue
	local width, maxWidth = ALMOST_ZERO, bar:GetParent():GetWidth()
	if value > 0 and maxValue > 0 and maxWidth > 0 then
		width = value * maxWidth / maxValue
	end
	bar:SetWidth(width)
end

local function SpawnPredictionBar(parent)
	local bar = parent:CreateTexture(nil, "OVERLAY")
	bar:SetWidth(ALMOST_ZERO)
	bar:SetPoint("TOP", parent)
	bar:SetPoint("BOTTOM", parent)
	bar.minValue, bar.maxValue, bar.value = 0, 0, 0
	bar.SetMinMaxValues = SetMinMaxValues
	bar.SetValue = SetValue
	bar.UpdateWidth = UpdateWidth

	return bar
end

local function HealthPrediction_OnSizeChanged(health)
	local hp = health.__owner.HealthPrediction
	hp.myBar:UpdateWidth()
	hp.otherBar:UpdateWidth()
	hp.absorbBar:UpdateWidth()
	hp.healAbsorbBar:UpdateWidth()
end

local function HealthPrediction_UpdateColors(frame)
	local hp = frame.HealthPrediction
	local colors = oUF.colors.healthPrediction
	hp.myBar:SetColorTexture(unpack(colors.self, 1, 4))
	hp.otherBar:SetColorTexture(unpack(colors.others, 1, 4))
	hp.absorbBar:SetColorTexture(unpack(colors.absorb, 1, 4))
	hp.healAbsorbBar:SetColorTexture(unpack(colors.healAbsorb, 1, 4))
end

oUF:RegisterMetaFunction("SpawnHealthPrediction", function(self, maxOverflow)
	local health = self.Health

	local myIncomingHeal = SpawnPredictionBar(health)
	local otherIncomingHeal = SpawnPredictionBar(health)
	local absorb = SpawnPredictionBar(health)
	local healAbsorb = SpawnPredictionBar(health)

	healAbsorb:SetPoint("RIGHT", health:GetStatusBarTexture())
	myIncomingHeal:SetPoint("LEFT", healAbsorb, "RIGHT")
	otherIncomingHeal:SetPoint("LEFT", myIncomingHeal, "RIGHT")
	absorb:SetPoint("LEFT", otherIncomingHeal, "RIGHT")

	health:HookScript("OnSizeChanged", HealthPrediction_OnSizeChanged)

	self.HealthPrediction = {
		frequentUpdates = health.frequentUpdates,
		maxOverflow = maxOverflow,
		myBar = myIncomingHeal,
		otherBar = otherIncomingHeal,
		absorbBar = absorb,
		healAbsorbBar = healAbsorb,
	}
	HealthPrediction_UpdateColors(self)

	self:RegisterMessage("OnColorModified", HealthPrediction_UpdateColors)

	return self.HealthPrediction
end)

local function PowerPrediction_OnSizeChanged(power)
	local pp = power.__owner.PowerPrediction
	if pp.mainBar then
		pp.mainBar:UpdateWidth()
	end
	if pp.altBar then
		pp.altBar:UpdateWidth()
	end
end

oUF:RegisterMetaFunction("SpawnPowerPrediction", function(self)
	local mainBar, altBar

	local power = self.Power
	if power then
		mainBar = SpawnPredictionBar(power)
		mainBar:SetPoint("RIGHT", power:GetStatusBarTexture())
		mainBar:SetColorTexture(1, 1, 1, 0.3)
	end

	local altPower = self.AdditionalPower
	if altPower then
		altBar = SpawnPredictionBar(altPower)
		altBar:SetPoint("RIGHT", altPower:GetStatusBarTexture())
		altBar:SetColorTexture(1, 1, 1, 0.3)
	end

	if mainBar or altBar then
		self.PowerPrediction = {
			mainBar = mainBar,
			altBar = altBar,
		}

		power:HookScript("OnSizeChanged", PowerPrediction_OnSizeChanged)
	end

	return self.PowerPrediction
end)

--[=[
Adirelle's oUF layout
(c) 2013-2016 Adirelle (adirelle@gmail.com)

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

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local ipairs = _G.ipairs
local unpack = _G.unpack
--GLOBALS>

local ALMOST_ZERO = 1e-8

local function HealthPrediction_OnSizeChanged(health)
	local hp = health.__owner.HealthPrediction
	hp.myBar:UpdateWidth()
	hp.otherBar:UpdateWidth()
	hp.absorbBar:UpdateWidth()
	hp.healAbsorbBar:UpdateWidth()
end

local function HealthPrediction_SetMinMaxValues(bar, minValue, maxValue)
	if bar.minValue ~= minValue or bar.maxValue ~= maxValue then
		bar.minValue,  bar.maxValue = minValue, maxValue
		bar:UpdateWidth()
	end
end

local function HealthPrediction_SetValue(bar, value)
	if bar.value ~= value then
		bar.value = value
		bar:UpdateWidth()
	end
end

local function HealthPrediction_UpdateWidth(bar)
	local value, maxValue = bar.value - bar.minValue, bar.maxValue - bar.minValue
	local width, maxWidth = ALMOST_ZERO, bar:GetParent():GetWidth()
	if value > 0 and maxValue > 0 and maxWidth > 0 then
		width = value * maxWidth / maxValue
	end
	bar:SetWidth(width)
end

local function HealthPrediction_UpdateColors(frame)
	local hp = frame.HealthPrediction
	local colors = oUF.colors.healthPrediction
	hp.myBar:SetColorTexture(unpack(colors.self, 1, 4))
	hp.otherBar:SetColorTexture(unpack(colors.others, 1, 4))
	hp.absorbBar:SetColorTexture(unpack(colors.absorb, 1, 4))
	hp.healAbsorbBar:SetColorTexture(unpack(colors.healAbsorb, 1, 4))
end

oUF:RegisterMetaFunction('SpawnHealthPrediction', function(frame, maxOverflow)
	local health = frame.Health

	local myIncomingHeal = health:CreateTexture(nil, "OVERLAY")
	local otherIncomingHeal = health:CreateTexture(nil, "OVERLAY")
	local absorb = health:CreateTexture(nil, "OVERLAY")
	local healAbsorb = health:CreateTexture(nil, "OVERLAY")

	for i, bar in ipairs{healAbsorb, myIncomingHeal, otherIncomingHeal, absorb} do
		bar:SetWidth(ALMOST_ZERO)
		bar:SetPoint("TOP", health)
		bar:SetPoint("BOTTOM", health)
		bar.minValue, bar.maxValue, bar.value = 0, 0, 0
		bar.SetMinMaxValues = HealthPrediction_SetMinMaxValues
		bar.SetValue = HealthPrediction_SetValue
		bar.UpdateWidth = HealthPrediction_UpdateWidth
	end

	healAbsorb:SetPoint("RIGHT", health:GetStatusBarTexture())
	myIncomingHeal:SetPoint("LEFT", healAbsorb, "RIGHT")
	otherIncomingHeal:SetPoint("LEFT", myIncomingHeal, "RIGHT")
	absorb:SetPoint("LEFT", otherIncomingHeal, "RIGHT")

	health:HookScript('OnSizeChanged', HealthPrediction_OnSizeChanged)

	frame.HealthPrediction = {
		frequentUpdates = health.frequentUpdates,
		maxOverflow = maxOverflow,
		myBar = myIncomingHeal,
		otherBar = otherIncomingHeal,
		absorbBar = absorb,
		healAbsorbBar = healAbsorb
	}
	HealthPrediction_UpdateColors(frame)

	frame:RegisterMessage('OnColorModified', HealthPrediction_UpdateColors)

	return frame.HealthPrediction
end)

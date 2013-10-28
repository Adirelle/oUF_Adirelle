--[=[
Adirelle's oUF layout
(c) 2013 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local ipairs = _G.ipairs
local unpack = _G.unpack
--GLOBALS>

local ALMOST_ZERO = 1e-8

local function HealPrediction_OnSizeChanged(health)
	local hp = health.__owner.HealPrediction
	hp.myBar:UpdateWidth()
	hp.otherBar:UpdateWidth()
	hp.absorbBar:UpdateWidth()
	hp.healAbsorbBar:UpdateWidth()
end

local function HealPrediction_SetMinMaxValues(bar, minValue, maxValue)
	if bar.minValue ~= minValue or bar.maxValue ~= maxValue then
		bar.minValue,  bar.maxValue = minValue, maxValue
		bar:UpdateWidth()
	end
end

local function HealPrediction_SetValue(bar, value)
	if bar.value ~= value then
		bar.value = value
		bar:UpdateWidth()
	end
end

local function HealPrediction_UpdateWidth(bar)
	local value, maxValue = bar.value - bar.minValue, bar.maxValue - bar.minValue
	local width, maxWidth = ALMOST_ZERO, bar:GetParent():GetWidth()
	if value > 0 and maxValue > 0 and maxWidth > 0 then
		width = value * maxWidth / maxValue
	end
	bar:SetWidth(width)
end

local function HealPrediction_UpdateColors(frame)
	local hp = frame.HealPrediction
	hp.myBar:SetTexture(unpack(oUF.colors.healPrediction.self, 1, 4))
	hp.otherBar:SetTexture(unpack(oUF.colors.healPrediction.others, 1, 4))
	hp.absorbBar:SetTexture(unpack(oUF.colors.healPrediction.absorb, 1, 4))
	hp.healAbsorbBar:SetTexture(unpack(oUF.colors.healPrediction.healAbsorb, 1, 4))
end

oUF:RegisterMetaFunction('SpawnHealPrediction', function(frame, maxOverflow)
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
		bar.SetMinMaxValues = HealPrediction_SetMinMaxValues
		bar.SetValue = HealPrediction_SetValue
		bar.UpdateWidth = HealPrediction_UpdateWidth
	end

	healAbsorb:SetPoint("RIGHT", health:GetStatusBarTexture())
	myIncomingHeal:SetPoint("LEFT", healAbsorb, "RIGHT")
	otherIncomingHeal:SetPoint("LEFT", myIncomingHeal, "RIGHT")
	absorb:SetPoint("LEFT", otherIncomingHeal, "RIGHT")

	health:HookScript('OnSizeChanged', HealPrediction_OnSizeChanged)

	frame.HealPrediction = {
		frequentUpdates = health.frequentUpdates,
		maxOverflow = maxOverflow,
		myBar = myIncomingHeal,
		otherBar = otherIncomingHeal,
		absorbBar = absorb,
		healAbsorbBar = healAbsorb
	}
	HealPrediction_UpdateColors(frame)

	frame:RegisterMessage('OnColorModified', HealPrediction_UpdateColors)

	return frame.HealPrediction
end)

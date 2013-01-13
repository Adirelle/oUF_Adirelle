--[=[
Adirelle's oUF layout
(c) 2009-2012 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle = _G.oUF_Adirelle

if oUF_Adirelle.SingleStyle then return end

--<GLOBALS
local _G = _G
local CreateFrame = _G.CreateFrame
local floor = _G.floor
local format = _G.format
local strjoin = _G.strjoin
local tostring = _G.tostring
local UnitClassification = _G.UnitClassification
--GLOBALS>
local GameFontWhiteSmall = _G.GameFontWhiteSmall

local GAP, TEXT_MARGIN = private.GAP, private.TEXT_MARGIN
local GetLib = oUF_Adirelle.GetLib

local function smartValue(value)
	if value >= 10000000 then
		return format("%.1fm", value/1000000)
	elseif value >= 10000 then
		return format("%.1fk", value/1000)
	else
		return tostring(value)
	end
end
private.smartValue = smartValue

local function OnStatusBarUpdate(bar)
	if not bar:IsShown() then return end
	local text = bar.Text
	if not text then return end
	local value, min, max = bar:GetValue(), bar:GetMinMaxValues()
	if max == 100 then
		text:SetFormattedText("%d%%", floor(value))
	elseif max <= 1 then
		return text:Hide()
	else
		local perValue = ((value < max) and UnitClassification(bar:GetParent().unit) ~= 'normal') and format("%d%% ", floor(value/max*100)) or ""
		local maxValue = smartValue(max)
		local curValue = value < max and (smartValue(value).."/") or ""
		text:SetText(strjoin('', perValue, curValue, maxValue))
	end
	text:Show()
end

local function SpawnTexture(object, size, to, xOffset, yOffset)
	local texture = object:CreateTexture(nil, "OVERLAY")
	texture:SetWidth(size)
	texture:SetHeight(size)
	texture:SetPoint("CENTER", object, to or "CENTER", xOffset or 0, yOffset or 0)
	return texture
end

local function SpawnText(self, object, layer, from, to, xOffset, yOffset, fontKind, fontSize, fontFlags)
	local text = object:CreateFontString(nil, layer, "GameFontNormal")
	self:RegisterFontString(text, fontKind or "number", fontSize or 12, fontFlags or "")
	text:SetWidth(0)
	text:SetHeight(0)
	text:SetJustifyV("MIDDLE")
	if from then
		text:SetPoint(from, object, to or from, xOffset or 0, yOffset or 0)
		if from:match("RIGHT") then
			text:SetJustifyH("RIGHT")
		elseif from:match("LEFT") then
			text:SetJustifyH("LEFT")
		else
			text:SetJustifyH("CENTER")
		end
	else
		text:SetJustifyH("LEFT")
	end
	return text
end

local function SpawnStatusBar(self, noText, from, anchor, to, xOffset, yOffset, fontKind, fontSize, fontFlags)
	local bar = CreateFrame("StatusBar", nil, self)
	if not noText then
		local text = SpawnText(self, bar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0, fontKind, fontSize, fontFlags)
		text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
		bar.Text = text
		bar:SetScript('OnShow', OnStatusBarUpdate)
		bar:SetScript('OnValueChanged', OnStatusBarUpdate)
		bar:SetScript('OnMinMaxChanged', OnStatusBarUpdate)
	end
	if from then
		bar:SetPoint(from, anchor or self, to or from, xOffset or 0, yOffset or 0)
	end
	self:RegisterStatusBarTexture(bar)
	return bar
end

local function DiscreteBar_Layout(bar)
	if bar.numItems > 0 then
		local width, itemHeight = bar:GetSize()
		local spacing = (width + GAP) / bar.numItems
		local itemWidth = spacing - GAP
		for i = 1, bar.maxItems do
			local item = bar[i]
			if i <= bar.numItems then
				item:SetPoint("TOPLEFT", bar, "TOPLEFT", spacing * (i-1), 0)
				item:SetSize(itemWidth, itemHeight)
				item:Show()
			else
				item:Hide()
			end
		end
	else
		for i = 1, bar.maxItems do
			bar[i]:Hide()
		end
	end
end

local function DiscreteBar_SetMinMaxValues(bar, min, max)
	if min ~= bar.minValue or max ~= bar.maxValue then
		bar.minValue, bar.maxValue = min, max
		bar.numItems = max - min
		return DiscreteBar_Layout(bar)
	end
end

local function DiscreteBar_SetValue(bar, current)
	if current == bar.value then return end
	bar.value = current
	local rel = current - bar.minValue
	for i = 1, bar.numItems do
		bar[i]:SetShown(i <= rel)
	end
end

local function DiscreteBar_SetStatusBarColor(bar, r, g, b, a)
	for i = 1, bar.maxItems do
		local widget = bar[i]
		if widget:IsObjectType("StatusBar") then
			widget:SetStatusBarColor(r, g, b, a)
		elseif widget:IsObjectType("Texture") then
			widget:SetVertexColor(r, g, b, a)
		end
	end
end

local function SpawnDiscreteBar(self, numItems, createStatusBar, texture)
	local bar = CreateFrame("Frame", nil, self)
	self:Debug('Using texture', texture, 'for discrete bar')
	bar.maxItems = numItems
	bar.numItems = numItems
	bar.minValue = 0
	bar.maxValue = numItems
	bar.value = 0
	bar:SetScript('OnShow', DiscreteBar_Layout)
	bar:SetScript('OnSizeChanged', DiscreteBar_Layout)
	bar.SetMinMaxValues = DiscreteBar_SetMinMaxValues
	bar.SetValue = DiscreteBar_SetValue
	bar.SetStatusBarColor = DiscreteBar_SetStatusBarColor
	for i = 1, numItems do
		local item
		if createStatusBar then
			item = CreateFrame("StatusBar", nil, bar)
			if texture then
				item:SetStatusBarTexture(texture)
			end
		else
			item = bar:CreateTexture(nil, "ARTWORK")
			if texture then
				self:Debug('Using texture', texture, 'for discrete bar')
				item:SetTexture(texture)
			end
		end
		if not texture then
			self:RegisterStatusBarTexture(item)
		end
		item.index = i
		item.__owner = self
		bar[i] = item
	end
	return bar
end

local function HybridBar_SetMinMaxValues(bar, min, max)
	if min ~= bar.minValue or max ~= bar.maxValue then
		bar.minValue, bar.maxValue = min, max
		local step = bar.valueStep
		local num = floor((max - min) / step)
		bar.numItems = num
		for i = 1, num do
			bar[i]:SetMinMaxValues(min + step * (i-1), min + (step * i))
		end
		return DiscreteBar_Layout(bar)
	end
end

local function HybridBar_SetValue(bar, current)
	if current == bar.value or not bar.numItems then return end
	bar.value = current
	for i = 1, bar.numItems do
		bar[i]:SetValue(current)
	end
end

local function SpawnHybridBar(self, numItems, step)
	local bar = SpawnDiscreteBar(self, numItems, true)
	bar.valueStep = step
	bar.SetMinMaxValues = HybridBar_SetMinMaxValues
	bar.SetValue = HybridBar_SetValue
	return bar
end

private.SpawnTexture, private.SpawnText, private.SpawnStatusBar, private.SpawnDiscreteBar, private.SpawnHybridBar = SpawnTexture, SpawnText, SpawnStatusBar, SpawnDiscreteBar, SpawnHybridBar


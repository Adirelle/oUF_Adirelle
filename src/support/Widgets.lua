--[=[
Adirelle's oUF layout
(c) 2009-2016 Adirelle (adirelle@gmail.com)

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

local _G = _G
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local CreateFrame = _G.CreateFrame
local floor = _G.floor
local ceil = _G.ceil
local format = _G.format
local tostring = _G.tostring
local UnitClassification = _G.UnitClassification
--GLOBALS>

local GAP, TEXT_MARGIN = oUF_Adirelle.GAP, oUF_Adirelle.TEXT_MARGIN

local function CreateName() -- luacheck: ignore
end
local function GetSerialName() -- luacheck: ignore
end
--@debug@
-- These are only used in unpackaged version
do
	function CreateName(parent, suffix)
		local name = parent and parent:GetName()
		return name and (name .. suffix)
	end

	local serials = {}
	function GetSerialName(parent, suffix)
		local prefix = CreateName(parent, suffix)
		if prefix then
			local serial = (serials[prefix] or 0) + 1
			serials[prefix] = serial
			return prefix .. serial
		end
	end
end
--@end-debug@
oUF_Adirelle.CreateName = CreateName
oUF_Adirelle.GetSerialName = GetSerialName

local function smartValue(value)
	if value >= 10000000 then
		return format("%.1fm", value / 1000000)
	elseif value >= 10000 then
		return format("%.1fk", value / 1000)
	else
		return tostring(value)
	end
end
oUF_Adirelle.smartValue = smartValue

local function OnStatusBarUpdate(bar)
	if not bar:IsShown() then
		return
	end
	local text = bar.Text
	if not text then
		return
	end
	local value, _, max = bar:GetValue(), bar:GetMinMaxValues()
	if max == 100 then
		text:SetFormattedText("%d%%", floor(value))
	elseif max <= 1 then
		return text:Hide()
	elseif UnitClassification(bar:GetParent().unit) ~= "normal" and value < max then
		text:SetFormattedText("%d%% %s", ceil(value / max * 100), smartValue(value))
	else
		text:SetText(smartValue(value))
	end
	text:Show()
end

oUF:RegisterMetaFunction("SpawnTexture", function(self, frame, size, to, xOffset, yOffset)
	local texture = frame:CreateTexture(GetSerialName(frame, "Texture"), "OVERLAY")
	texture:SetSize(size, size)
	texture:SetPoint("CENTER", self, to or "CENTER", xOffset or 0, yOffset or 0)
	return texture
end)

oUF:RegisterMetaFunction("SpawnText", function(self, frame, layer, from, to, xOffset, yOffset, fontKind, fontSize, fontFlags)
	local text = frame:CreateFontString(GetSerialName(frame, "Text"), layer or "ARTWORK", "GameFontNormal")
	self:RegisterFontString(text, fontKind or "text", fontSize or 12, fontFlags or "")
	text:SetSize(0, 0)
	text:SetJustifyV("MIDDLE")
	if from then
		text:SetPoint(from, frame, to or from, xOffset or 0, yOffset or 0)
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
end)

oUF:RegisterMetaFunction("SpawnStatusBar", function(self, textureKind, noText, from, anchor, to, xOffset, yOffset, fontKind, fontSize, fontFlags)
	local bar = CreateFrame("StatusBar", GetSerialName(self, "StatusBar"), self, "BackdropTemplate")
	if not noText then
		local text = self:SpawnText(
			bar,
			"ARTWORK",
			"TOPRIGHT",
			"TOPRIGHT",
			-TEXT_MARGIN,
			0,
			fontKind or textureKind,
			fontSize,
			fontFlags
		)
		text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
		bar.Text = text
		bar:SetScript("OnShow", OnStatusBarUpdate)
		bar:SetScript("OnValueChanged", OnStatusBarUpdate)
		bar:SetScript("OnMinMaxChanged", OnStatusBarUpdate)
	end
	if from then
		bar:SetPoint(from, anchor or self, to or from, xOffset or 0, yOffset or 0)
	end
	self:RegisterStatusBarTexture(bar, textureKind)
	return bar
end)

local function DiscreteBar_Layout(bar)
	if bar.numItems > 0 then
		local width, itemHeight = bar:GetSize()
		local spacing = (width + GAP) / bar.numItems
		local itemWidth = spacing - GAP
		local rel = (bar.value or 0) - (bar.minValue or 0)
		for i = 1, bar.maxItems do
			local item = bar[i]
			if i <= bar.numItems then
				item:SetPoint("TOPLEFT", bar, "TOPLEFT", spacing * (i - 1), 0)
				item:SetSize(itemWidth, itemHeight)
				item:SetShown(i <= rel)
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
	if current == bar.value then
		return
	end
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

oUF:RegisterMetaFunction("SpawnDiscreteBar", function(self, textureKind, numItems, createStatusBar, texture)
	local bar = CreateFrame("Frame", GetSerialName(self, "DiscreteBar"), self)
	bar.maxItems = numItems
	bar.numItems = numItems
	bar.minValue = 0
	bar.maxValue = numItems
	bar.value = 0
	bar:SetScript("OnShow", DiscreteBar_Layout)
	bar:SetScript("OnSizeChanged", DiscreteBar_Layout)
	bar.SetMinMaxValues = DiscreteBar_SetMinMaxValues
	bar.SetValue = DiscreteBar_SetValue
	bar.SetStatusBarColor = DiscreteBar_SetStatusBarColor
	for i = 1, numItems do
		local item
		if createStatusBar then
			item = CreateFrame("StatusBar", GetSerialName(bar, "StatusBar"), bar)
			if texture then
				item:SetStatusBarTexture(texture)
			end
		else
			item = bar:CreateTexture(GetSerialName(bar, "Texture"), "ARTWORK")
			if texture then
				item:SetTexture(texture)
			end
		end
		if not texture then
			self:RegisterStatusBarTexture(item, textureKind)
		end
		item.index = i
		item.__owner = self
		bar[i] = item
	end
	return bar
end)

local function HybridBar_SetMinMaxValues(bar, min, max)
	if min ~= bar.minValue or max ~= bar.maxValue then
		bar.minValue, bar.maxValue = min, max
		local step = bar.valueStep
		local num = floor((max - min) / step)
		bar.numItems = num
		for i = 1, num do
			bar[i]:SetMinMaxValues(min + step * (i - 1), min + (step * i))
		end
		return DiscreteBar_Layout(bar)
	end
end

local function HybridBar_SetValue(bar, current)
	if current == bar.value or not bar.numItems then
		return
	end
	bar.value = current
	for i = 1, bar.numItems do
		bar[i]:SetValue(current)
	end
end

oUF:RegisterMetaFunction("SpawnHybridBar", function(self, textureKind, numItems, step)
	local bar = self:SpawnDiscreteBar(textureKind, numItems, true)
	bar.valueStep = step
	bar.SetMinMaxValues = HybridBar_SetMinMaxValues
	bar.SetValue = HybridBar_SetValue
	return bar
end)

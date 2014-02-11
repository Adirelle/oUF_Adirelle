--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local CreateFrame = _G.CreateFrame
local ipairs = _G.ipairs
local pairs = _G.pairs
local tinsert = _G.tinsert
local tsort = _G.table.sort
local wipe = _G.wipe
--GLOBALS>

local GAP = private.GAP

local wlist = {}

local function SortWidgets(a, b)
	return a.__layoutOrder < b.__layoutOrder
end

local function UpdateLayout(self)
	self.dirty = false
	self:SetScript('OnUpdate', nil)

	wipe(wlist)
	local totalWeight = 0
	for widget in pairs(self.widgets) do
		if widget:IsVisible() then
			tinsert(wlist, widget)
			totalWeight = totalWeight + widget.__layoutWeight
		end
	end
	local count = #wlist
	if count == 0 then
		return
	end

	local totalHeight = self:GetHeight() - GAP * (count - 1)
	local heightUnit = totalHeight / totalWeight
	tsort(wlist, SortWidgets)
	for i, widget in ipairs(wlist) do
		widget:SetHeight(widget.__layoutWeight * heightUnit)
		if i == 1 then
			widget:SetPoint("TOP", self, 0, 0)
		else
			widget:SetPoint("TOP", wlist[i-1], "BOTTOM", 0, -GAP)
		end
	end
end

local function AddWidget(self, widget, order, weight)
	self.widgets[widget] = true
	widget.__layoutOrder = order or 1
	widget.__layoutWeight = weight or 1
	widget:ClearAllPoints()
	widget:SetPoint("LEFT", self)
	widget:SetPoint("RIGHT", self)
	widget:HookScript('OnShow', self.RequireUpdate)
	widget:HookScript('OnHide', self.RequireUpdate)
	self:RequireUpdate()
end

local function SpawnBarLayout(self)
	local widget = CreateFrame("Frame", private.CreateName(self, "BarLayout"), self)
	widget.Debug = self.Debug
	widget.widgets = {}
	widget.AddWidget = AddWidget
	widget.RequireUpdate = function()
		widget.dirty = true
		widget:SetScript('OnUpdate', UpdateLayout)
	end
	widget:SetScript('OnShow', widget.RequireUpdate)
	widget:SetScript('OnSizeChanged', widget.RequireUpdate)
	return widget
end

private.SpawnBarLayout = SpawnBarLayout
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

local _, private = ...

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)

--<GLOBALS
local CreateFrame = assert(_G.CreateFrame)
local ipairs = assert(_G.ipairs)
local pairs = assert(_G.pairs)
local tinsert = assert(_G.tinsert)
local wipe = assert(_G.wipe)
--GLOBALS>

local tsort = assert(_G.table.sort)

local CreateName = assert(oUF_Adirelle.CreateName)
local GAP = assert(oUF_Adirelle.GAP)

local wlist = {}

local function SortWidgets(a, b)
	return a.__layoutOrder < b.__layoutOrder
end

local function UpdateLayout(self)
	self.dirty = false
	self:SetScript("OnUpdate", nil)

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
			widget:SetPoint("TOP", wlist[i - 1], "BOTTOM", 0, -GAP)
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
	widget:HookScript("OnShow", self.RequireUpdate)
	widget:HookScript("OnHide", self.RequireUpdate)
	self:RequireUpdate()
end

local function SpawnBarLayout(self)
	local widget = CreateFrame("Frame", CreateName(self, "BarLayout"), self)
	widget.Debug = self.Debug
	widget.widgets = {}
	widget.AddWidget = AddWidget
	widget.RequireUpdate = function()
		widget.dirty = true
		widget:SetScript("OnUpdate", UpdateLayout)
	end
	widget:SetScript("OnShow", widget.RequireUpdate)
	widget:SetScript("OnSizeChanged", widget.RequireUpdate)
	return widget
end

private.SpawnBarLayout = SpawnBarLayout

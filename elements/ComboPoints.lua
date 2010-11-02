--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Slightly modified CPoints that should properly handle units

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local GetComboPoints = GetComboPoints
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local function GetSourceUnit(target)
	if target == 'focus' or target == 'target' then
		return UnitHasVehicleUI('player') and 'vehicle' or 'player'
	else
		local prefix, index = target:match('^(.-)target(.-)$')
		if prefix then
			return UnitHasVehicleUI(prefix..index) and prefix..'pet'..index or prefix..index
		end
	end
end

local Update = function(self, event, unit)
	local source = GetSourceUnit(self.unit)
	if not source or (unit and unit ~= self.unit and unit ~= source) then return end
	local count = GetComboPoints(source, self.unit)
	if count == 5 then
		for _, point in pairs(self.ComboPoints) do
			point:SetVertexColor(1, 0, 0)
			point:Show()
		end
	else
		for i, point in ipairs(self.ComboPoints) do
			if i <= count then
				point:SetVertexColor(1, 1, 1)
				point:Show()
			else
				point:Hide()
			end
		end
	end
end

local Enable = function(self)
	if self.ComboPoints then
		self:RegisterEvent('UNIT_COMBO_POINTS', Update)
		self:RegisterEvent('UNIT_ENTERED_VEHICLE', Update)
		self:RegisterEvent('UNIT_EXITED_VEHICLE', Update)
		return true
	end
end

local Disable = function(self)
	if self.ComboPoints then
		self:UnregisterEvent('UNIT_COMBO_POINTS', Update)
		self:UnregisterEvent('UNIT_ENTERED_VEHICLE', Update)
		self:UnregisterEvent('UNIT_EXITED_VEHICLE', Update)
	end
end

oUF:AddElement('ComboPoints', Update, Enable, Disable)

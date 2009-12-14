--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local function Update(self, event)
	local unit = SecureButton_GetModifiedUnit(self)
	if unit and unit ~= self.unit then
		self.unit = unit
		self:PLAYER_ENTERING_WORLD()
	end
end

local function OnAttributeChanged(self, name, value)
	if name == "unit" or name == "unitsuffix" then
		local newOrig = SecureButton_GetUnit(self)
		if newOrig ~= self.__origUnit then
			self.__origUnit = newOrig
			return Update(self, "OnAttributeChanged") 			
		end
	end
end

local function OnVehicleUpdate(self, event, unit)
	if unit == self.__origUnit then
		return Update(self, "event") 
	end
end

local function Enable(self)
	if self.noVehicleSwap or (self.unit == "player" or self.unit == "pet") then return end	
	self.__origUnit = SecureButton_GetUnit(self) or self.unit
	self:SetAttribute('toggleForVehicle', true)
	self:HookScript('OnAttributeChanged', OnAttributeChanged)
	self:RegisterEvent('UNIT_ENTERED_VEHICLE', OnVehicleUpdate)
	self:RegisterEvent('UNIT_EXITED_VEHICLE', OnVehicleUpdate)
	return true
end

local function Disable(self)
	self:SetAttribute('toggleForVehicle', false)
	self:UnregisterEvent('UNIT_ENTERED_VEHICLE', OnVehicleUpdate)
	self:UnregisterEvent('UNIT_EXITED_VEHICLE', OnVehicleUpdate)
end

oUF:AddElement('VehicleSwap', Update, Enable, Disable)


--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local function Update(self, event)
	local unit = SecureButton_GetModifiedUnit(self)
	if unit and unit ~= self.unit then
		self.unit = unit
		self:PLAYER_ENTERING_WORLD()
	end
end

local function OnAttributeChanged(self, name, value)
	if name == "unit" or name == "unitsuffix" then
		self.__origUnit = SecureButton_GetUnit(self)
		return Update(self, "OnAttributeChanged") 
	end
end

local function OnVehicleUpdate(self, event, unit)
	if unit == self.__origUnit then
		return Update(self, "event") 
	end
end

local function Enable(self)
	if self.noVehicleSwap then return end	
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


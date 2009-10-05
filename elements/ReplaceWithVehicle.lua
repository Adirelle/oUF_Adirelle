--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local function Update(self, event)
	local unit = SecureButton_GetModifiedUnit(self)
	if unit and unit ~= self.unit then
		self.unit = unit
		self.id = unit:match("^.-(%d+)")
		self:PLAYER_ENTERING_WORLD()		
	end
end

local function OnAttributeChanged(self, name, value)
	if name == 'unit' then
		Update(self, 'OnAttributeChanged')
	end
end

local function OnVehicleChanged(self, event, unit)
	if unit == SecureButton_GetUnit(self) then
		Update(self, event)
	end
end

local function Enable(self)
	if self.noVehicleSwap then return end
	self:SetAttribute("toggleForVehicle", true)
	self:HookScript('OnAttributeChanged', OnAttributeChanged)
	self:RegisterEvent('UNIT_ENTERED_VEHICLE', OnVehicleChanged)
	self:RegisterEvent('UNIT_EXITED_VEHICLE', OnVehicleChanged)
	return true
end

local function Disable(self)
	self:SetAttribute("toggleForVehicle", false)
	self:UnregisterEvent('UNIT_ENTERED_VEHICLE', OnVehicleChanged)
	self:UnregisterEvent('UNIT_EXITED_VEHICLE', OnVehicleChanged)
end

oUF:AddElement('ReplaceWithVehicle', Update, Enable, Disable)

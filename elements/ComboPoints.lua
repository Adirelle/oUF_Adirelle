-- Slightly modified CPoints that should properly handle units

local parent, ns = ...
local oUF
if ns then
	oUF = ns.oUF
else
	parent = debugstack():match[[\AddOns\(.-)\]]
	local global = GetAddOnMetadata(parent, 'X-oUF')
	assert(global, 'X-oUF needs to be defined in the parent add-on.')
	oUF = _G[global]
end

local GetComboPoints = GetComboPoints
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local function GetSourceUnit(target)
	if target == 'focus' or target == 'player' then
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
	local cpoints = self.ComboPoints
	local cp = GetComboPoints(source, self.unit)

	if(#cpoints == 0) then
		cpoints:SetText((cp > 0) and cp)
	else
		for i=1, MAX_COMBO_POINTS do
			if(i <= cp) then
				cpoints[i]:Show()
			else
				cpoints[i]:Hide()
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

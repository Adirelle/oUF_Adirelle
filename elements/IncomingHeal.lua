--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local function NOOP() end
local DoEnable, DoDisable, GetIncomingHeal = NOOP, NOOP, nil
local lhc

-- ------------------------------------------------------------------------------
-- LibHealComm-4.0 support
-- ------------------------------------------------------------------------------

--[[
lhc = LibStub('LibHealComm-4.0', true)
if lhc then
end
--]]

-- ------------------------------------------------------------------------------
-- LibHealComm-3.0 support
-- ------------------------------------------------------------------------------

lhc = LibStub('LibHealComm-3.0', true)
if lhc then
	local playerName = UnitName('player')
	local objects = {}
	local playerHeals = {}

	local function UpdateHeals(event, healer, amount, ...)
		for i = 1, select('#', ...) do
			local target = select(i, ...)
			if healer == playerName then
				playerHeals[target] = amount and ((playerHeals[target] or 0) + amount) or nil
			end
			for frame in pairs(objects) do
				if UnitName(frame.unit) == target then
					frame:UpdateElement('IncomingHeal')
				end
			end
		end
	end
	
	local function DirectHealStart(event, healer, amount, _, ...)
		return UpdateHeals(event, healer, amount, ...)
	end
	local function DirectHealDelayed(event, healer, _, ...)
		return UpdateHeals(event, healer, 0, ...)
	end
	local function DirectHealStop(event, healer, _, ...)
		return UpdateHeals(event, healer, nil, ...)
	end
	local function HealModifierUpdate(event, unit)
		local frame = oUF.units[unit]
		if frame and frame.unit == unit then
			frame:UpdateElement('IncomingHeal')
		end
	end

	function GetIncomingHeal(unit, time)
		return lhc:UnitHealModifierGet(unit) * ( (lhc:UnitIncomingHealGet(unit, time) or 0) + (playerHeals[UnitName(unit) or false] or 0))
	end

	function DoEnable(self)
		if self.IncomingHeal then
			if not next(objects) then
				lhc.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealStart', DirectHealStart)
				lhc.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealDelayed', DirectHealDelayed)
				lhc.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealStop', DirectHealStop)
				lhc.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealModifierUpdate', HealModifierUpdate)
			end
			objects[self] = true
		end
	end

	function DoDisable(self) 
		if objects[self] then
			objects[self] = nil
			if not next(objects) then
				lhc.UnregisterAllCallbacks('oUF_IncomingHeal')
			end
		end
	end
end

if GetIncomingHeal then

	function Enable(self)
		if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then
			return DoEnable(self)
		end
	end

	local function Disable(self)
		if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then
			return DoDisable(self)
		end
	end

	local function Update(self, event, unit)
		local heal = self.IncomingHeal
		if not heal then return end
		local current, max, incomingHeal = UnitHealth(unit), UnitMaxHealth(unit), 0
		if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
			GetIncomingHeal(unit, GetTime()+4)
		end
		self:UpdateIncomingHeal(self, event, unit, heal, current, max, incomingHeal)
	end

	oUF.HasIncomingHeal = true
	oUF:AddElement('IncomingHeal', Update, Enable, Disable)
end


--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local DoEnable, DoDisable, GetIncomingHeal

local lhc3, lhc3_minor = LibStub('LibHealComm-3.0', true)
local lhc4, lhc4_minor = LibStub('LibHealComm-4.0', true)

-- ------------------------------------------------------------------------------
-- LibHealComm-4.0 support
-- ------------------------------------------------------------------------------
if lhc4 then
	local band = bit.band
	local HEAL_FLAGS = lhc4.ALL_HEALS
	local objects = {}

	local function UpdateHeals(event, _, healType, _, ...)
		if band(healType, HEAL_FLAGS) == 0 then return end
		local unitMap = lhc4:GetGuidUnitMapTable()
		local units = oUF.units
		for i = 1, select('#', ...) do
			local guid = select(i, ...)
			local unit = guid and unitMap[guid]
			local frame = unit and units[unit]
			if frame and objects[frame] then
				frame:UpdateElement('IncomingHeal')
			end
		end
	end
	
	local function ModifierChanged(guid)
		local unitMap = lhc4:GetGuidUnitMapTable()
		local frame = oUF.units[unitMap[guid] or false]
		if frame and objects[frame] then
			frame:UpdateElement('IncomingHeal')
		end
	end

	function GetIncomingHeal(unit, timeLimit)
		local guid = UnitGUID(unit)
		local inc = lhc4:GetHealAmount(guid, HEAL_FLAGS, timeLimit)
		if inc then
			return inc * lhc4:GetHealModifier(guid)
		else
			return 0
		end
	end

	function DoEnable(self)
		if not next(objects) then
			lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStarted', UpdateHeals)
			lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealUpdated', UpdateHeals)
			lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealDelayed', UpdateHeals)
			lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStopped', UpdateHeals)
			lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_ModifierChanged', ModifierChanged)
		end
		objects[self] = true
	end

	function DoDisable(self) 
		objects[self] = nil
		if not next(objects) then
			lhc4.UnregisterAllCallbacks('oUF_IncomingHeal')
		end
	end

-- ------------------------------------------------------------------------------
-- LibHealComm-3.0 support
-- ------------------------------------------------------------------------------
elseif lhc3 then
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
				if frame.unit and UnitName(frame.unit) == target then
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
		return lhc3:UnitHealModifierGet(unit) * ( (lhc3:UnitIncomingHealGet(unit, time) or 0) + (playerHeals[UnitName(unit) or false] or 0))
	end

	function DoEnable(self)
		if not next(objects) then
			lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealStart', DirectHealStart)
			lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealDelayed', DirectHealDelayed)
			lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealStop', DirectHealStop)
			lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealModifierUpdate', HealModifierUpdate)
		end
		objects[self] = true
	end

	function DoDisable(self) 
		if objects[self] then
			objects[self] = nil
			if not next(objects) then
				lhc3.UnregisterAllCallbacks('oUF_IncomingHeal')
			end
		end
	end

else
	-- No library
	return
end

local function Enable(self)
	if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then
		return DoEnable(self)
	end
end

local function Disable(self)
	if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then	
		return DoDisable(self)
	end
end

local floor = math.floor
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local function Update(self, event, unit)
	local heal = self.IncomingHeal
	if not heal then return end
	local incomingHeal = 0
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		incomingHeal = floor(GetIncomingHeal(unit, GetTime() + 3.0))
	end
	if incomingHeal ~= heal.__incomingHeal then
		heal.__incomingHeal = incomingHeal
		self:UpdateIncomingHeal(event, unit, heal, incomingHeal)
	end
end

oUF.HasIncomingHeal = true
oUF:AddElement('IncomingHeal', Update, Enable, Disable)


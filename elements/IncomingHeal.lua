--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local DoEnable, DoDisable, GetIncomingHeal, Update

local lhc3, lhc3_minor = LibStub('LibHealComm-3.0', true)
local lhc4, lhc4_minor = LibStub('LibHealComm-4.0', true)

local playerName = UnitName('player')
local objects = {}

-- ------------------------------------------------------------------------------
-- LibHealComm-4.0 support
-- ------------------------------------------------------------------------------
if lhc4 then
	local band = bit.band
	local HEAL_FLAGS = lhc4.ALL_HEALS -- lhc4.BOMB_HEALS
	
	local unitMap, units
	
	do
		local _unitMap = lhc4:GetGuidUnitMapTable()
		unitMap = setmetatable({}, {
			__index = function(t, guid)
				local unit = guid and _unitMap[guid] or false
				if guid and not unit then
					geterrorhandler()(string.format('No unit for guid %s', tostring(guid)))
				end
				return unit
			end
		})
	end
	
	do
		units = setmetatable({}, {
			__index = function(t, unit)
				local frame = unit and oUF.units[unit] or false
				if unit and not frame then
					geterrorhandler()(string.format('No frame for unit %s', tostring(unit)))
				end
				return frame
			end
		})
	end
	
	local function UpdateHeals(event, casterGUID, spellId, healType, _, ...)
		if band(healType, HEAL_FLAGS) == 0 then return end
		for i = 1, select('#', ...) do
			local unit = unitMap[select(i, ...)]
			local frame = units[unit]
			if frame and objects[frame] then
				Update(frame, event, unit)
			end
		end
	end
	
	local function ModifierChanged(event, guid)
		local frame = units[unitMap[guid]]
		if frame and objects[frame] then
			Update(frame, event, unit)
		end
	end

	function GetIncomingHeal(unit, timeLimit)
		local guid = UnitGUID(unit)
		local inc = lhc4:GetHealAmount(guid, HEAL_FLAGS, timeLimit)
		if inc and inc > 0 then
			return inc * lhc4:GetHealModifier(guid)
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
	local playerHeals = {}

	local UnitName = UnitName
	local function UnitFullName(unit)
		local name, realm = UnitName(unit)
		if realm then
			return name .. '-' .. realm
		else
			return name
		end
	end

	local function UpdateHeals(event, healer, amount, ...)
		for i = 1, select('#', ...) do
			local target = select(i, ...)
			if healer == playerName then
				playerHeals[target] = amount and ((playerHeals[target] or 0) + amount) or nil
			end
			for frame in pairs(objects) do
				if frame.unit and UnitFullName(frame.unit) == target then
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
		local pHeals = playerHeals[UnitFullName(unit) or false]
		local otherHeals = lhc3:UnitIncomingHealGet(unit, time)
		if otherHeals or pHeals then
			return lhc3:UnitHealModifierGet(unit) * ((pHeals or 0) + (otherHeals or 0))
		end
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

local incomingHeals = {}

local function Enable(self)
	if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then
		return DoEnable(self)
	end
end

local function Disable(self)
	if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then	
		incomingHeals[self] = nil
		return DoDisable(self)
	end
end

local floor = math.floor
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

function Update(self, event, unit)
	local heal = self.IncomingHeal
	if not heal or (unit and unit ~= self.unit) then return end
	unit = unit or self.unit
	local incomingHeal
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		incomingHeal = GetIncomingHeal(unit, GetTime() + 3.0)
	end
	if incomingHeals[self] ~= incomingHeal or event == 'PLAYER_ENTERING_WORLD' then
		incomingHeals[self] = incomingHeal
		self:UpdateIncomingHeal(event, unit, heal, incomingHeal or 0)
	end
end

oUF.HasIncomingHeal = true
oUF:AddElement('IncomingHeal', Update, Enable, Disable)


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
local _units = {}

-- ------------------------------------------------------------------------------
-- LibHealComm-4.0 support
-- ------------------------------------------------------------------------------
if lhc4 then
	local band = bit.band
	local HEAL_FLAGS = lhc4.ALL_HEALS -- lhc4.BOMB_HEALS
	
	local function warn(...)
		return geterrorhandler()(string.format(tostringall(...)))
	end
	
	local GetUnitForGUID
	do
		local _unitMap = lhc4:GetGuidUnitMapTable()
		function GetUnitForGUID(guid, event)
			if not guid then return end
			local unit = _unitMap[guid]
			if not unit then
				warn('No unit for guid %s (event: %s, guidToUnit: %s, guidToGroup: %s)', guid, event, lhc4.guidToUnit[guid], lhc4.guidToGroup[guid])
			end
			return unit or false
		end
	end
	
	local function GetFrameForUnit(unit, event)
		if not unit then return end
		local frame = _units[unit] or oUF.units[unit] or false
		if not unit:match('pet') then
			if not frame then
				warn('No frame found for %s (event: %s)', unit, event)
			elseif not _units[unit] then
				warn('Frame for %s found only in oUF.units (event: %s)', unit, event)
			end
		end
		return frame
	end
	
	local function UpdateHeals(event, casterGUID, spellId, healType, _, ...)
		if band(healType, HEAL_FLAGS) == 0 then return end
		for i = 1, select('#', ...) do
			local unit = GetUnitForGUID(select(i, ...), event)
			local frame = GetFrameForUnit(unit, event)
			if frame and frame:IsShown() and objects[frame] then
				Update(frame, event, unit)
			end
		end
	end
	
	local function ModifierChanged(event, guid)
		local frame = GetFrameForUnit(GetUnitForGUID(guid, event), event)
		if frame and frame:IsShown() and objects[frame] then
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

	function DoEnable()
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStarted', UpdateHeals)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealUpdated', UpdateHeals)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealDelayed', UpdateHeals)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStopped', UpdateHeals)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_GUIDDisappeared', UpdateHeals)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_ModifierChanged', ModifierChanged)
	end

	function DoDisable() 
		lhc4.UnregisterAllCallbacks('oUF_IncomingHeal')
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

	function DoEnable()
		lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealStart', DirectHealStart)
		lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealDelayed', DirectHealDelayed)
		lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_DirectHealStop', DirectHealStop)
		lhc3.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealModifierUpdate', HealModifierUpdate)
	end

	function DoDisable() 
		lhc3.UnregisterAllCallbacks('oUF_IncomingHeal')
	end

else
	-- No library
	return
end

local incomingHeals = {}

local function Enable(self)
	if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then
		if not objects[self] then
			if not next(objects) then
				DoEnable()
			end
			objects[self] = true
		end
		return true
	end
end

local function Disable(self)
	if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then	
		incomingHeals[self] = nil
		if objects[self] then
			objects[self] = nil
			if not next(objects[self]) then
				DoDisable()
			end
		end
	end
end

local floor = math.floor
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

function Update(self, event, unit)
	local heal = self.IncomingHeal
	if not heal or (unit and unit ~= self.unit) then return end
	unit = unit or self.unit
	_units[unit] = self
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


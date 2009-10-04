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
local guidFrameMap = {}

local frame = CreateFrame("Frame")
frame:Hide()

-- ------------------------------------------------------------------------------
-- LibHealComm-4.0 support
-- ------------------------------------------------------------------------------
if lhc4 then
	local band = bit.band
	local HEAL_FLAGS = lhc4.ALL_HEALS -- lhc4.BOMB_HEALS
	
	--[[
	local warn
	if UnitName('player') == 'Adirelle' or UnitName('player') == 'Qwetia' then
		function warn(...)
			return geterrorhandler()(string.format(tostringall(...)))
		end
	else
		function warn() end
	end
	--]]

	local function GetFrameForGUID(guid, event)
		local frame = guid and guidFrameMap[guid]
		if frame then
			if frame.unit and UnitGUID(frame.unit) == guid then
				return frame
			else
				guidFrameMap[guid] = nil
			end
		end
	end
	
	local function CleanupGUIDFrameMap(self, event)
		if event ~= 'PLAYER_REGEN_ENABLED' and InCombatLockdown() then return end
		if event == 'PARTY_MEMBER_CHANGED' and GetNumRaidMembers() > 0 then return end
		if not UnitGUID('player') then return end
		for guid, frame in pairs(guidFrameMap) do
			if not frame.unit or UnitGUID(frame.unit) ~= guid then
				guidFrameMap[guid] = nil
			end
		end
	end
	
	local function UpdateHeals(event, casterGUID, spellId, healType, _, ...)
		if healType and band(healType, HEAL_FLAGS) == 0 then return end
		for i = 1, select('#', ...) do
			local frame = GetFrameForGUID(select(i, ...), event)
			if frame and frame:IsShown() and objects[frame] then
				Update(frame, event)
			end
		end
	end
	
	local function UpdateMultiGUID(event, casterGUID, spellId, healType, _, ...)
		if healType and band(healType, HEAL_FLAGS) == 0 then return end
		for i = 1, select('#', ...) do
			local frame = GetFrameForGUID(select(i, ...), event)
			if frame and frame:IsShown() and objects[frame] then
				Update(frame, event)
			end
		end
	end
	
	local function UpdateOneGUID(event, guid)
		local frame = GetFrameForGUID(guid, event)
		if frame and frame:IsShown() and objects[frame] then
			Update(frame, event)
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
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStarted', UpdateMultiGUID)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealUpdated', UpdateMultiGUID)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealDelayed', UpdateMultiGUID)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStopped', UpdateMultiGUID)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_GUIDDisappeared', UpdateOneGUID)
		lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_ModifierChanged', UpdateOneGUID)
		frame:SetScript('OnEvent', CleanupGUIDFrameMap)
		frame:RegisterEvent('PARTY_MEMBER_CHANGED')
		frame:RegisterEvent('RAID_ROSTER_UPDATE')
		frame:RegisterEvent('PLAYER_REGEN_ENABLED')
	end

	function DoDisable() 
		lhc4.UnregisterAllCallbacks('oUF_IncomingHeal')
		frame:UnregisterEvent('PARTY_MEMBER_CHANGED')
		frame:UnregisterEvent('RAID_ROSTER_UPDATE')
		frame:UnregisterEvent('PLAYER_REGEN_ENABLED')
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

frame:SetScript('OnShow', function(self) self.elapsed = 0 end)
frame:SetScript('OnUpdate', function(self, elapsed)
	elapsed = elapsed + self.elapsed
	if elapsed < 0.5 then
		self.elapsed = elapsed
	else
		self.elapsed = 0
		for frame in pairs(incomingHeals) do
			Update(frame, 'OnUpdate')
		end
		if not next(incomingHeals) then
			self:Hide()
		end
	end
end)

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
	local guid = UnitGUID(unit)
	if guid then
		guidFrameMap[guid] = self
	end
	local incomingHeal
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		incomingHeal = GetIncomingHeal(unit, GetTime() + 3.0)
	end
	if incomingHeals[self] ~= incomingHeal or event == 'PLAYER_ENTERING_WORLD' then
		incomingHeals[self] = incomingHeal
		self:UpdateIncomingHeal(event, unit, heal, incomingHeal or 0)
		if incomingHeal then
			frame:Show()
		end
	end
end

oUF.HasIncomingHeal = true
oUF:AddElement('IncomingHeal', Update, Enable, Disable)


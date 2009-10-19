--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local lhc4 = LibStub('LibHealComm-4.0', true)
if not lhc4 then return end

local objects = {}
local incomingHeals = {}

local pairs = pairs
local next = next
local type = type
local band = bit.band
local select = select
local floor = math.floor
local GetTime = GetTime
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitGUID = UnitGUID

local HEALTYPE_FILTER = lhc4.ALL_HEALS -- lhc4.BOMB_HEALS

local function Update(self, event, unit)
	if not objects[self] or (unit and unit ~= self.unit) then return end
	local incomingHeal
	unit = self.unit
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		local guid = UnitGUID(unit)
		incomingHeal = lhc4:GetHealAmount(guid, HEALTYPE_FILTER, GetTime()+3)
		if incomingHeal then
			incomingHeal = incomingHeal * lhc4:GetHealModifier(guid)
		end
	end
	if incomingHeals[self] ~= incomingHeal or event == 'PLAYER_ENTERING_WORLD' then
		incomingHeals[self] = incomingHeal
		self:UpdateIncomingHeal(event, unit, self.IncomingHeal, incomingHeal or 0)
	end
end

local function OnSingleUpdate(self, event, guid)
	if self:IsShown() and UnitGUID(self.unit or false) == guid then
		return Update(self, event)
	end
end

local tmp = {}
local function OnMultipleUpdate(event, _, _, healType, _, ...)
	if healType and band(healType, HEALTYPE_FILTER) == 0 then return end
	for i = 1, select('#', ...) do
		tmp[tostring(select(i, ...))] = true
	end
	for frame in pairs(objects) do
		if frame:IsShown() and frame.unit and tmp[UnitGUID(frame.unit) or false] then
			Update(frame, event)
		end
	end
	wipe(tmp)
end

local function Enable(self)
	if self.IncomingHeal and type(self.UpdateIncomingHeal) == "function" then
		if not objects[self] then
			if not next(objects) then
				lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStarted', OnMultipleUpdate)
				lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealUpdated', OnMultipleUpdate)
				lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealDelayed', OnMultipleUpdate)
				lhc4.RegisterCallback('oUF_IncomingHeal', 'HealComm_HealStopped', OnMultipleUpdate)			
			end
			objects[self] = true
			lhc4.RegisterCallback(self, 'HealComm_GUIDDisappeared', OnSingleUpdate, self)
			lhc4.RegisterCallback(self, 'HealComm_ModifierChanged', OnSingleUpdate, self)
		end
		return true
	end
end

local function Disable(self)
	if objects[self] then	
		lhc4.UnregisterAllCallbacks(self)
		incomingHeals[self] = nil
		objects[self] = nil
		if not next(objects[self]) then
			lhc4.UnregisterAllCallbacks('oUF_IncomingHeal')
		end
	end
end

oUF.HasIncomingHeal = true
oUF:AddElement('IncomingHeal', Update, Enable, Disable)


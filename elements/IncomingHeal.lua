--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local incomingHeals = {}
local incomingOthersHeals = {}

local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local function Update(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	local incomingHeal, incomingOthersHeal = 0, 0
	unit = self.unit or unit
	if unit and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		incomingHeal = UnitGetIncomingHeals(unit, "player") or 0
		if self.IncomingOthersHeal and playerHealEndTime then
			incomingOthersHeal = (UnitGetIncomingHeals(unit) or 0) - incomingHeal
		end
	end
	if incomingHeals[self] ~= incomingHeal or incomingOthersHeals[self] ~= incomingOthersHeal or event == 'PLAYER_ENTERING_WORLD' then
		incomingHeals[self] = incomingHeal
		incomingOthersHeals[self] = incomingOthersHeal
		self.IncomingHeal:PostUpdate(event, unit, incomingHeal, incomingOthersHeal)
	end
end

local function Path(self, ...)
	return (self.Update or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local incHeal = self.IncomingHeal
	if incHeal then
		incHeal.__owner, incHeal.ForceUpdate = self, ForceUpdate
		self:RegisterEvent("UNIT_HEAL_PREDICTION", Path)
		return true
	end
end

local function Disable(self)
	if objects[self] then
		self:UnregisterEvent("UNIT_HEAL_PREDICTION", Path)
	end
end

oUF.HasIncomingHeal = true
oUF:AddElement('IncomingHeal', Update, Enable, Disable)


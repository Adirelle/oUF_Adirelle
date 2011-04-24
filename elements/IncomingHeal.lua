--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local UnitGetIncomingHeals = _G.UnitGetIncomingHeals
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsConnected = _G.UnitIsConnected

local function Update(self, event, unit)
	if (unit and unit ~= self.unit) then return end
	local incomingHeals, incomingOthersHeals = 0, 0
	unit = self.unit or unit
	if unit and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		incomingHeals = UnitGetIncomingHeals(unit) or 0
		if self.IncomingOthersHeal then
			local myHeals = UnitGetIncomingHeals(unit, "player") or 0
			if myHeals > 0 and myHeals < incomingHeals then
				incomingHeals, incomingOthersHeals = myHeals, incomingHeals - myHeals
			end
		end
	end
	self.IncomingHeal:PostUpdate(event, unit, incomingHeals, incomingOthersHeals)
end

local function Path(self, ...)
	return (self.IncomingHeal.Update or Update)(self, ...)
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
	if self.IncomingHeal then
		self:UnregisterEvent("UNIT_HEAL_PREDICTION", Path)
		self.IncomingHeal:Hide()
	end
end

oUF.HasIncomingHeal = true
oUF:AddElement('IncomingHeal', Path, Enable, Disable)


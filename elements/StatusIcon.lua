--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .StatusIcon
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local CreateFrame = _G.CreateFrame
local next = _G.next
local pairs = _G.pairs
local UnitHasVehicleUI = _G.UnitHasVehicleUI
local UnitInPhase = _G.UnitInPhase
local UnitIsCharmed = _G.UnitIsCharmed
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDead = _G.UnitIsDead
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsGhost = _G.UnitIsGhost
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsVisible = _G.UnitIsVisible
local unpack = _G.unpack
--GLOBALS>

local function GetFrameUnitState(self, ignoreVisibility)
	local unit = self.realUnit or self.unit
	if UnitIsPlayer(unit) then
		if not UnitIsConnected(unit) then
			return "DISCONNECTED"
		elseif UnitIsDead(unit) then
			return "DEAD"
		elseif not ignoreVisibility and not UnitIsVisible(unit) then
			return "OUTOFSCOPE"
		elseif not ignoreVisibility and not UnitInPhase(unit) then
			return "OUTOFPHASE"
		elseif UnitIsGhost(unit) then
			return "DEAD"
		elseif UnitHasVehicleUI(unit) then
			return "INVEHICLE"
		elseif UnitIsCharmed(unit) then
			return "CHARMED"
		end
	else
		return UnitIsDeadOrGhost(unit) and "DEAD" or nil
	end
end
oUF_Adirelle.GetFrameUnitState = GetFrameUnitState

local icons = {
	DISCONNECTED = { [[Interface\Icons\INV_Sigil_Thorim]], 0.05, 0.95, 0.5-0.25*0.9, 0.5+0.25*0.9, false },
	OUTOFPHASE = { [[Interface\TargetingFrame\UI-PhasingIcon]], 0.15625, 0.84375, 0.5-0.34375*0.5, 0.5+0.34375*0.5, true },
	OUTOFSCOPE = { [[Interface\Icons\Spell_Frost_Stun]], 0.05, 0.95, 0.5-0.25*0.9, 0.5+0.25*0.9, true },
	DEAD = { [[Interface\TargetingFrame\UI-TargetingFrame-Skull]], 4/32, 26/32, 9/32, 20/32, false },
	CHARMED = { [[Interface\Icons\Ability_DualWield]], 0.05, 0.95, 0.5-0.25*0.9, 0.5+0.25*0.9, false, 1, 0, 0 }
}

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local statusIcon = self.StatusIcon
	local state = GetFrameUnitState(self) or "NONE"
	if state ~= statusIcon.currentState then
		statusIcon.currentState = state
		local icon = icons[state]
		if icon then
			local texturePath, x0, x1, y0, y1, desat, r, g, b = unpack(icon)
			statusIcon:SetTexture(texturePath)
			statusIcon:SetTexCoord(x0, x1, y0, y1)
			statusIcon:SetDesaturated(desat)
			statusIcon:SetVertexColor(r or 1, g or 1, b or 1)
			statusIcon:Show()
		else
			statusIcon:Hide()
		end
	end
	if statusIcon.PostUpdate then
		statusIcon.PostUpdate(self, event, self.unit, state)
	end
end

local visibility = {}
local objects = {}
local delay = 0
local function UpdateVisibility(_, elapsed)
	if delay > 0 then
		delay = delay - elapsed
		return
	end
	delay = 0.25
	for frame in pairs(objects) do
		if frame:IsShown() and frame.unit then
			local visible = UnitIsVisible(frame.unit)
			if visible ~= visibility[frame] then
				visibility[frame] = visible
				Update(frame, "OnUpdate", frame.unit)
			end
		end
	end
end

local checkFrame
local function Enable(self)
	if self.StatusIcon then
		self:RegisterEvent('UNIT_AURA', Update)
		self:RegisterEvent('UNIT_HEALTH', Update)
		self:RegisterEvent('UNIT_CONNECTION', Update)
		self:RegisterEvent('UNIT_PHASE', Update)
		self:RegisterEvent('UNIT_FACTION', Update)
		self:RegisterEvent('PARTY_MEMBER_ENABLE', Update)
		self:RegisterEvent('PARTY_MEMBER_DISABLE', Update)
		self:RegisterEvent('UNIT_FLAGS', Update)
		self:RegisterEvent('UNIT_DYNAMIC_FLAGS', Update)
		self:RegisterEvent('UNIT_ENTERED_VEHICLE', Update)
		self:RegisterEvent('UNIT_EXITED_VEHICLE', Update)
		if not next(objects) then
			if not checkFrame then
				checkFrame = CreateFrame("Frame")
				checkFrame:SetScript('OnUpdate', UpdateVisibility)
			end
			checkFrame:Show()
		end
		objects[self] = true
		return true
	end
end

local function Disable(self)
	if self.StatusIcon then
		self.StatusIcon:Hide()
		self:UnregisterEvent('UNIT_AURA', Update)
		self:UnregisterEvent('UNIT_HEALTH', Update)
		self:UnregisterEvent('UNIT_CONNECTION', Update)
		self:UnregisterEvent('UNIT_PHASE', Update)
		self:UnregisterEvent('UNIT_FACTION', Update)
		self:UnregisterEvent('PARTY_MEMBER_ENABLE', Update)
		self:UnregisterEvent('PARTY_MEMBER_DISABLE', Update)
		self:UnregisterEvent('UNIT_FLAGS', Update)
		self:UnregisterEvent('UNIT_DYNAMIC_FLAGS', Update)
		self:UnregisterEvent('UNIT_ENTERED_VEHICLE', Update)
		self:UnregisterEvent('UNIT_EXITED_VEHICLE', Update)
		objects[self] = nil
		if not next(objects) then
			checkFrame:Hide()
		end
	end
end

oUF:AddElement('StatusIcon', Update, Enable, Disable)


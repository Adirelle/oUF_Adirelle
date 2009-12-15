--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .StatusIcon
--]=]

local icons = {
	disconnected = { [[Interface\Icons\INV_Sigil_Thorim]], 0.05, 0.95, 0.5-0.25*0.9, 0.5+0.25*0.9, false },
	outOfScope = { [[Interface\Icons\Spell_Frost_Stun]], 0.05, 0.95, 0.5-0.25*0.9, 0.5+0.25*0.9, true },
	dead = { [[Interface\TargetingFrame\UI-TargetingFrame-Skull]], 4/32, 26/32, 9/32, 20/32, false },
}

local force = 0

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local icon = nil
	if not UnitIsConnected(self.unit) or force == 1 then
		icon = icons.disconnected
	elseif UnitIsDeadOrGhost(self.unit) or force == 2 then
		icon = icons.dead
	elseif not UnitIsVisible(self.unit) or force == 3 then
		icon = icons.outOfScope
	else
		return self.StatusIcon:Hide()
	end
	local tex = self.StatusIcon
	local texturePath, x0, x1, y0, y1, desat, r, g, b = unpack(icon)
	tex:SetTexture(texturePath)
	tex:SetTexCoord(x0, x1, y0, y1)
	tex:SetDesaturated(desat)
	tex:SetVertexColor(r or 1, g or 1, b or 1)
	tex:Show()
end

local objects = {}

_G.testBla = function()
	force = (force + 1) % 4
	for frame in pairs(objects) do
		Update(frame)
	end
end

local isVisible = {}
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
			if isVisible[frame] ~= visible then
				isVisible[frame] = visible
				Update(frame, "Visibility", frame.unit)
			end
		end
	end
end

local function PlayerUpdate(self, event) return Update(self, event, "player") end

local checkFrame
local function Enable(self)
	if self.StatusIcon then
		self:RegisterEvent('UNIT_FLAGS', Update)
		self:RegisterEvent('UNIT_DYNAMIC_FLAGS', Update)
		self:RegisterEvent('PLAYER_DEAD', PlayerUpdate)
		self:RegisterEvent('PLAYER_ALIVE', PlayerUpdate)
		self:RegisterEvent('PLAYER_UNGHOST', PlayerUpdate)
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
		self:UnregisterEvent('UNIT_FLAGS', Update)
		self:UnregisterEvent('UNIT_DYNAMIC_FLAGS', Update)
		self:UnregisterEvent('PLAYER_DEAD', PlayerUpdate)
		self:UnregisterEvent('PLAYER_ALIVE', PlayerUpdate)
		self:UnregisterEvent('PLAYER_UNGHOST', PlayerUpdate)
		objects[self] = nil
		if not next(objects) then
			checkFrame:Hide()
		end
	end
end

oUF:AddElement('StatusIcon', Update, Enable, Disable)


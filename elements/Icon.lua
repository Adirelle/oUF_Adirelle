--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local CreateBlinkingFrame
do
	local function RegisterIcon(self, icon, expireTime, threshold)
		self.icons[icon] = true
		icon.expireTime = expireTime
		icon.threshold = threshold
		self:Show()
	end
	
	local function UnregisterIcon(self, icon)
		icon:SetAlpha(1)
		self.icons[icon] = nil
	end

	local function UpdateBlinking(self)
		local now = GetTime()
		local alpha = 2 * (now % 1)
		if alpha > 1 then
			alpha = 2 - alpha
		end
		local icons = self.icons
		for icon in pairs(icons) do
			if not icon:IsShown() then
				UnregisterIcon(self, icon)
			elseif icon.expireTime - now < icon.threshold then
				icon:SetAlpha(alpha)
			else
				icon:SetAlpha(1)
			end
		end
		if not next(icons) then
			self:Hide()
		end
	end

	function CreateBlinkingFrame()
		local f  = CreateFrame("Frame", nil, UIParent)
		f:SetScript('OnUpdate', UpdateBlinking)
		f.icons = {}
		f.RegisterIcon = RegisterIcon
		f.UnregisterIcon = UnregisterIcon
		f:Hide()
		return f
	end
	
end

local blinkingFrame

local function UpdateIcon(self, unit, icon, func)
	local texture, count, start, duration, r, g, b = func(unit)
	if not texture then
		return icon:Hide()
	end
	icon:SetTexture(texture)
	icon:SetCooldown(start, duration)
	icon:SetStack(count)
	icon:SetColor(r, g, b)
	if self.iconBlinkThreshold and start and duration then
		blinkingFrame = blinkingFrame or CreateBlinkingFrame()
		blinkingFrame:RegisterIcon(icon, start+duration, self.iconBlinkThreshold)
	elseif blinkingFrame then
		blinkingFrame:UnregisterIcon(icon)
	end
	icon:Show()
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = unit or self.unit
	for icon, func in pairs(self.AuraIcons) do
		UpdateIcon(self, unit, icon, func)
	end
end

local function Enable(self)
	local icons = self.AuraIcons and next(self.AuraIcons)
	if icons then
		self:RegisterEvent('UNIT_AURA', Update)
	end
end

local function Disable(self)
	local icons = self.AuraIcons
	if icons then
		self:UnregisterEvent('UNIT_AURA')
		for icon in pairs(icons) do
			icon:Hide()
		end
	end
end

local function AuraIcon(self, icon, func, ...)
	assert(type(icon) == "table", "icon should be a table, not "..type(icon))
	assert(type(func) == "function", "func should be a function ,not "..type(func))
	self.AuraIcons = self.AuraIcons or {}
	self.AuraIcons[icon] = func
	return icon
end

oUF.AuraIcon = AuraIcon
oUF:AddElement('AuraIcons', Update, Enable, Disable)


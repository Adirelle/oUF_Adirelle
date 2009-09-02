--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local function UpdateAlpha(icon)
	local now = GetTime()
	local alpha = 1
	if icon.expireTime - now < icon.threshold then
		alpha = 2 * (now % 1)
		if alpha > 1 then
			alpha = 2 - alpha
		end
	end
	if alpha ~= icon:GetAlpha() then
		icon:SetAlpha(alpha)	
	end
end

local function EndBlinking(icon)
	icon:SetAlpha(1)
	icon:SetScript('OnUpdate', nil)
	icon:SetScript('OnHide', nil)	
end

local function UpdateIcon(self, unit, icon, func)
	local texture, count, start, duration, r, g, b = func(unit)
	if not texture then
		return icon:Hide()
	end
	icon.Texture:SetTexture(texture)
	if self.iconBlinkThreshold and start and duration then
		icon.expireTime = start + duration
		icon.threshold = self.iconBlinkThreshold
		icon:SetScript('OnUpdate', UpdateAlpha)
		icon:SetScript('OnHide', EndBlinking)	
	else
		EndBlinking(icon)
	end
	local cooldown, stack, border = icon.Cooldown, icon.Stack, icon.Border
	if cooldown then
		if start and duration then
			cooldown:SetCooldown(start, duration)
			cooldown:Show()
		else
			cooldown:Hiden()
		end
	end
	if stack then
		if (tonumber(count) or 0) > 1 then
			stack:SetText(count)
			stack:Show()
		else
			stack:Hide()
		end
	end
	if border then
		if r and g and b then
			border:SetColor(r, g, b, 1)
			border:Show()
		else
			border:Hide()
		end
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
oUF:AddElement('Adirelle_AuraIcons', Update, Enable, Disable)


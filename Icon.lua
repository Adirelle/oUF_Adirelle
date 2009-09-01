--[=[
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local function UpdateIcon(self, unit, icon, func)
	local texture, count, start, duration, r, g, b = func(unit)
	if not texture then
		return icon:Hide()
	end
	icon.Texture:SetTexture(texture)
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


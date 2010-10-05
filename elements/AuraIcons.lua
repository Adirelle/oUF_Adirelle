--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local CreateBlinkingFrame
do
	local GetTime = GetTime
	local blinkingAlpha, now = 1.0, GetTime()

	local function RegisterIcon(self, icon, start, duration, threshold)
		self.icons[icon] = true
		icon.expirationTime = start + duration
		icon.thresholdTime = icon.expirationTime - math.min(threshold, duration * threshold / 10)
		if now >= icon.thresholdTime then
			icon:SetAlpha(icon.alpha * blinkingAlpha)
		else
			icon:SetAlpha(icon.alpha)
		end
		self:Show()
	end

	local function UnregisterIcon(self, icon)
		icon:SetAlpha(1)
		self.icons[icon] = nil
	end

	local delay = 0
	local function UpdateBlinking(self, elapsed)
		if delay > elapsed then
			delay = delay - elapsed
			return
		end
		delay, now = 0.1, GetTime()
		blinkingAlpha = 2 * (now % 1)
		if blinkingAlpha > 1 then
			blinkingAlpha = 2 - blinkingAlpha
		end
		for icon in next, self.icons do
			if not icon:IsShown() or now >= icon.expirationTime then
				UnregisterIcon(self, icon)
			elseif now >= icon.thresholdTime then
				icon:SetAlpha(icon.alpha * blinkingAlpha)
			end
		end
		if not next(self.icons) then
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

local function UpdateIcon(self, unit, icon, texture, count, start, duration, r, g, b, a)
	if not texture then
		return icon:Hide()
	end
	icon:SetTexture(texture)
	icon:SetCooldown(start, duration)
	icon:SetStack(count)
	icon:SetColor(r, g, b, a)
	if self.iconBlinkThreshold and start and duration and duration > 0 and not icon.doNotBlink then
		blinkingFrame = blinkingFrame or CreateBlinkingFrame()
		blinkingFrame:RegisterIcon(icon, start, duration, self.iconBlinkThreshold)
	elseif blinkingFrame then
		blinkingFrame:UnregisterIcon(icon)
	end
	icon:Show()
end

local UnitIsConnected, UnitIsDeadOrGhost, UnitName = UnitIsConnected, UnitIsDeadOrGhost, UnitName

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = unit or self.unit
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitName(unit) ~= UNKNOWN then
		-- Update all icons
		for icon, func in pairs(self.AuraIcons) do
			UpdateIcon(self, unit, icon, func(unit))
		end
	else
		-- Hide all icons
		for icon in pairs(self.AuraIcons) do
			icon:Hide()
		end
	end
end

local function Enable(self)
	local icons = self.AuraIcons and next(self.AuraIcons)
	if icons then
		self:RegisterEvent('UNIT_AURA', Update)
		return true
	end
end

local function Disable(self)
	local icons = self.AuraIcons
	if icons then
		self:UnregisterEvent('UNIT_AURA', Update)
		for icon in pairs(icons) do
			icon:Hide()
		end
	end
end

oUF:AddElement('AuraIcons', Update, Enable, Disable)

-- Add filter methods to oUF
local filters = {}

function oUF:AddAuraFilter(name, func)
	name = tostring(name)
	assert(not filters[name], "aura filter by the same name already exists: "..name)
	assert(type(func) == "function", "func should be a function, not "..type(func))
	filters[name] = func
	oUF.Debug("New aura filter:", name, func)
	return name
end

function oUF:HasAuraFilter(name)
	return type(filters[tostring(name)]) == "function"
end

do
	local BORDER_WIDTH = 1

	local borderBackdrop = {
		edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]],
		edgeSize = BORDER_WIDTH,
		insets = {left = 0, right = 0, top = 0, bottom = 0},
	}

	local function NOOP() end

	local function SetTexture(self, path)
		local texture = self.Texture
		if path then
			texture:SetTexture(path)
			texture:Show()
		else
			texture:Hide()
		end
	end

	local function SetCooldown(self, start, duration)
		start, duration = tonumber(start), tonumber(duration)
		local cooldown = self.Cooldown
		if start and duration and duration > 0 then
			cooldown:SetCooldown(start, duration)
			cooldown:Show()
		else
			cooldown:Hide()
		end
	end

	local function SetStack(self, count)
		count = tonumber(count)
		local stack = self.Stack
		if count and count > 1 then
			stack:SetText(count)
			stack:Show()
		else
			stack:Hide()
		end
	end
	
	local function SetAlpha(self, _, _, _, a)
		self.alpha = a or 1
		self:SetAlpha(self.alpha)
	end

	local function SetBackdropBorderColor(self, r, g, b, a)
		r, g, b = tonumber(r), tonumber(g), tonumber(b)
		local border = self.Border
		if r and g and b then
			border:SetBackdropBorderColor(r, g, b)
			border:Show()
		else
			border:Hide()
		end
		SetAlpha(self, r, g, b, a)
	end

	oUF:RegisterMetaFunction('SpawnAuraIcon', function(self, parent, size, noCooldown, noStack, noBorder, noTexture, ...)
		assert(parent and type(parent.IsObjectType) == "function" and parent:IsObjectType("Frame"), "SpawnAuraIcon: parent should be a Frame")
		assert(type(size) == "nil" or type(size) == "number", "SpawnAuraIcon: size should be a number")
		local	icon = CreateFrame("Frame", nil, parent)
		size = size or parent.auraIconSize or self.auraIconSize or 14
		icon:SetWidth(size)
		icon:SetHeight(size)
		icon.alpha = 1.0

		if not noTexture then
			local texture = icon:CreateTexture(nil, "OVERLAY")
			texture:SetAllPoints(icon)
			texture:SetTexCoord(0.05, 0.95, 0.05, 0.95)
			texture:SetTexture(1,1,1,0)
			icon.Texture = texture
			icon.SetTexture = SetTexture
		else
			icon.SetTexture = NOOP
		end

		if not noCooldown then
			local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
			cooldown:SetAllPoints(icon.Texture or icon)
			cooldown:SetDrawEdge(true)
			cooldown:SetReverse(true)
			icon.Cooldown = cooldown
			icon.SetCooldown = SetCooldown
		else
			icon.SetCooldown = NOOP
		end

		if not noStack then
			local stack = (icon.Cooldown or icon):CreateFontString(nil, "OVERLAY", "NumberFontNormal")
			stack:SetAllPoints(icon.Texture or icon)
			stack:SetJustifyH("CENTER")
			stack:SetJustifyV("MIDDLE")
			stack:SetFont(NumberFontNormal:GetFont(), 10, "OUTLINE")
			stack:SetTextColor(1, 1, 1, 1)
			stack:SetShadowColor(0, 0, 0, 0)
			icon.Stack = stack
			icon.SetStack = SetStack
		else
			icon.SetStack = NOOP
		end

		if not noBorder then
			local border = CreateFrame("Frame", nil, icon)
			border:SetPoint("TOPLEFT", icon, "TOPLEFT", -BORDER_WIDTH, BORDER_WIDTH)
			border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", BORDER_WIDTH, -BORDER_WIDTH)
			border:SetBackdrop(borderBackdrop)
			border:SetBackdropColor(0, 0, 0, 0)
			border:SetBackdropBorderColor(1, 1, 1, 1)
			border:Hide()
			icon.Border = border
			icon.SetColor = SetBackdropBorderColor
		else
			icon.SetColor = SetAlpha
		end

		if select('#', ...) > 0 then
			icon:SetPoint(...)
		end

		icon:Hide()
		return icon
	end)
end

oUF:RegisterMetaFunction('AddAuraIcon', function(self, icon, filter)
	assert(type(icon) == "table", "icon should be a table, not "..type(icon))
	local func = filters[tostring(filter)]
	if not func then return icon end -- FIXME
	assert(type(func) == "function", "unknown aura filter: "..type(filter))
	self.AuraIcons = self.AuraIcons or {}
	self.AuraIcons[icon] = func
	return icon
end)


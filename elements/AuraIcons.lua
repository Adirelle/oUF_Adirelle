--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
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
	local threshold = icon.blinkThreshold or self.iconBlinkThreshold
	if threshold and start and duration and duration > 0 and not icon.doNotBlink then
		blinkingFrame = blinkingFrame or CreateBlinkingFrame()
		blinkingFrame:RegisterIcon(icon, start, duration, threshold)
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
	if name == "none" then return end -- FIXME
	assert(not filters[name], "aura filter by the same name already exists: "..name)
	assert(type(func) == "function", "func should be a function, not "..type(func))
	filters[name] = func
	oUF.Debug("New aura filter:", name, func)
	return name
end

function oUF:HasAuraFilter(name)
	return type(filters[tostring(name)]) == "function"
end

oUF:RegisterMetaFunction('AddAuraIcon', function(self, icon, filter)
	assert(type(icon) == "table", "icon should be a table, not "..type(icon))
	if filter == "none" then return icon end
	local func = filters[tostring(filter)]
	if type(func) ~= "function" then
		geterrorhandler()("unknown aura filter: "..filter)
		icon:Hide()
		return icon
	end
	self.AuraIcons = self.AuraIcons or {}
	self.AuraIcons[icon] = func
	return icon
end)


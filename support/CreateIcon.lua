--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local _G, parent, ns = _G, ...
setfenv(1, ns)

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

local function SetBorderColor(self, r, g, b, a)
	r, g, b = tonumber(r), tonumber(g), tonumber(b)
	local border = self.Border
	if r and g and b then
		border:SetVertexColor(r, g, b)
		border:Show()
	else
		border:Hide()
	end
	return SetAlpha(self, r, g, b, a)
end

oUF:RegisterMetaFunction('CreateIcon', function(self, parent, size, noCooldown, noStack, noBorder, noTexture, ...)
	assert(parent and type(parent[0]) == "userdata", "CreateIcon: parent should be a Frame")
	assert(type(size) == "nil" or type(size) == "number", "CreateIcon: size should be a number")
	local	icon = CreateFrame("Frame", nil, parent)
	if size then
		icon:SetSize(size, size)
	end
	icon.alpha = 1.0

	if not noTexture then
		local texture = icon:CreateTexture(nil, "ARTWORK")
		texture:SetAllPoints(icon)
		texture:SetTexCoord(4/64, 60/64, 4/64, 60/64)
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
		stack:SetPoint("CENTER", icon.Texture or icon)
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
		local border = (icon.Cooldown or icon):CreateTexture(nil, "OVERLAY")
		border:SetAllPoints(icon)
		border:SetTexture([[Interface\AddOns\oUF_Adirelle\media\icon_border]])
		border:Hide()
		icon.Border = border
		icon.SetColor = SetBorderColor
	else
		icon.SetColor = SetAlpha
	end

	if select('#', ...) > 0 then
		icon:SetPoint(...)
	end

	icon:Hide()
	return icon
end)


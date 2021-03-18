--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]=]

local _, private = ...

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local CreateFrame = assert(_G.CreateFrame, "_G.CreateFrame is undefined")
local GetUnitPowerBarTextureInfo = assert(_G.GetUnitPowerBarTextureInfo, "_G.GetUnitPowerBarTextureInfo is undefined")
local hooksecurefunc = assert(_G.hooksecurefunc, "_G.hooksecurefunc is undefined")
local pairs = assert(_G.pairs, "_G.pairs is undefined")
local tonumber = assert(_G.tonumber, "_G.tonumber is undefined")
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local ALT_POWER_TEX_FILL = _G.ALT_POWER_TEX_FILL or 2
local SummonStatus = assert(_G.Enum.SummonStatus)

-- Import some values from oUF_Adirelle namespace
local backdrop = assert(oUF_Adirelle.backdrop)
local glowBorderBackdrop = assert(oUF_Adirelle.glowBorderBackdrop)

local CreateClassAuraIcons = assert(private.CreateClassAuraIcons)
local LayoutClassAuraIcons = assert(private.LayoutClassAuraIcons)

local WIDTH = private.WIDTH
local HEIGHT = private.HEIGHT
local INSET = private.INSET
local BORDER_WIDTH = private.BORDER_WIDTH
local ICON_SIZE = private.ICON_SIZE
local SMALL_ICON_SIZE = private.SMALL_ICON_SIZE
local borderBackdrop = private.borderBackdrop

-- ------------------------------------------------------------------------------
-- Status icon
-- ------------------------------------------------------------------------------

-- local function toStr(val)
-- 	return val and tostring(val) or ""
-- end

-- local function IconString(d)
-- 	if d.height == 0 and not d.width and d.left and d.right and d.top and d.bottom then
-- 		d.width = (d.right - d.left) / (d.bottom - d.top)
-- 	end
-- 	return format(
-- 		"|T%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s|t",
-- 		d.path,
-- 		toStr(d.height),
-- 		toStr(d.width),
-- 		toStr(d.offsetX),
-- 		toStr(d.offsetY),
-- 		toStr(d.textureWidth),
-- 		toStr(d.textureHeight),
-- 		toStr(d.left),
-- 		toStr(d.right),
-- 		toStr(d.top),
-- 		toStr(d.bottom),
-- 		toStr(d.r and (d.r * 255)),
-- 		toStr(d.g and (d.g * 255)),
-- 		toStr(d.b and (d.b * 255))
-- 	)
-- end

local statusIcons = {
	DEAD = {
		path = [[Interface\Navigation\IngameNavigationUI]],
		textureWidth = 64,
		textureHeight = 64,
		left = 2,
		right = 25,
		top = 2,
		bottom = 32,
	},
	GHOST = {
		path = [[Interface\MINIMAP\ObjectIconsAtlas]],
		textureWidth = 1024,
		textureHeight = 512,
		left = 252,
		right = 283,
		top = 77,
		bottom = 110,
	},
	DISCONNECTED = {
		path = [[Interface\CHARACTERFRAME\Disconnect-Icon]],
		textureWidth = 64,
		textureHeight = 64,
		left = 15,
		right = 47,
		top = 11,
		bottom = 49,
	},
	RESURRECTION = {
		path = [[Interface\RAIDFRAME\Raid-Icon-Rez]],
		textureWidth = 64,
		textureHeight = 64,
		left = 5,
		right = 58,
		top = 2,
		bottom = 59,
	},
	["SUMMON" .. SummonStatus.Pending] = {
		path = [[Interface\RAIDFRAME\Raid-Icon-SummonPending]],
		textureWidth = 32,
		textureHeight = 32,
		left = 7,
		right = 27,
		top = 7,
		bottom = 25,
	},
	["SUMMON" .. SummonStatus.Accepted] = {
		path = [[Interface\RAIDFRAME\Raid-Icon-SummonAccepted]],
		textureWidth = 32,
		textureHeight = 32,
		left = 7,
		right = 27,
		top = 7,
		bottom = 25,
	},
	["SUMMON" .. SummonStatus.Declined] = {
		path = [[Interface\RAIDFRAME\Raid-Icon-SummonDeclined]],
		textureWidth = 32,
		textureHeight = 32,
		left = 7,
		right = 27,
		top = 7,
		bottom = 25,
	},
}

local function Status_PostUpdate(element)
	local frame, status = element.__owner, element.status
	local icon = status and statusIcons[status]
	frame:Debug("Status_PostUpdate", status, icon)
	element:SetShown(icon ~= nil)
	if icon then
		element:SetTexture(icon.path)
		element:SetTexCoord(
			icon.left / icon.textureWidth,
			icon.right / icon.textureWidth,
			icon.top / icon.textureHeight,
			icon.bottom / icon.textureHeight
		)
		local aspect = (icon.right - icon.left) / (icon.bottom - icon.top)
		element:SetWidth(aspect * element:GetHeight())
	end
end

local function UpdateColor(element)
	local self, color = element.__owner, element.color
	if not color then
		return
	end
	local r, g, b = unpack(color)
	if self.invertedBar then
		self.Health.bg:SetVertexColor(r, g, b, 1)
		self.Health:SetStatusBarColor(0, 0, 0, 0.75)
	else
		self.Health.bg:SetVertexColor(0, 0, 0, 1)
		self.Health:SetStatusBarColor(r, g, b, 0.75)
	end
	self.Name:SetTextColor(r, g, b)
end

local function OnSizeChanged(self, width, height)
	width = width or self:GetWidth()
	height = height or self:GetHeight()
	if not width or not height then
		return
	end
	local w = BORDER_WIDTH / self:GetEffectiveScale()
	self.Border:SetSize(width + 2 * w, height + 2 * w)
	self.ReadyCheckIndicator:SetSize(height, height)
	self.WarningIconBuff:SetPoint("CENTER", self, "LEFT", width / 4, 0)
	self.WarningIconDebuff:SetPoint("CENTER", self, "RIGHT", -width / 4, 0)
end

local function AlternativePower_PostUpdate(bar, unit, cur, min, max)
	if unit ~= bar.__owner.unit or not cur or not min then
		return
	end
	local _, powerRed, powerGreen, powerBlue = GetUnitPowerBarTextureInfo(unit, ALT_POWER_TEX_FILL + 1)
	if powerRed and powerGreen and powerBlue then
		local r, g, b = oUF.ColorGradient(cur - min, max - min, powerRed, powerGreen, powerBlue, 1, 0, 0)
		bar:SetStatusBarColor(r, g, b)
	else
		bar:SetStatusBarColor(0.75, 0.75, 0.75)
	end
end

local function AlternativePower_Layout(bar)
	local self = bar.__owner
	if bar:IsShown() then
		self.Health:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 0)
	else
		self.Health:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
	end
end

local function OnRaidLayoutModified(self, _, layout)
	local small, big = layout.Raid.smallIconSize, layout.Raid.bigIconSize
	self.WarningIconBuff:SetSize(big, big)
	self.WarningIconDebuff:SetSize(big, big)
	self.RoleIcon:SetSize(small, small)
	self.TargetIcon:SetSize(small, small)
	for icon in pairs(self.AuraIcons) do
		if icon.big then
			icon:SetSize(big, big)
		else
			icon:SetSize(small, small)
		end
	end

	LayoutClassAuraIcons(self, layout)
end

local function OnThemeModified(self, _, _, theme)
	-- Update border settings
	local border = self.Border
	for k, v in pairs(theme.Border) do
		border[k] = v
	end
	border:ForceUpdate()

	-- Update health bar settings
	self.colorClass = theme.raid.Health.colorClass
	self.invertedBar = theme.raid.Health.invertedBar
	self.RaidColor:PostUpdate()

	-- Update low health threshold
	local lowHealth = self.LowHealth
	if lowHealth then
		local prefs = theme.LowHealth
		lowHealth.threshold = prefs.isPercent and -prefs.percent or prefs.amount
		lowHealth:ForceUpdate()
	end
end

local function CureableDebuff_SetColor(icon, r, g, b, a)
	local texture, border = icon.Texture, icon.Border
	r, g, b, a = tonumber(r), tonumber(g), tonumber(b), tonumber(a) or 1
	if r and g and b then
		texture:SetVertexColor(0.5 + 0.5 * r, 0.5 + 0.5 * g, 0.5 + 0.5 * b, a)
		border:SetVertexColor(r, g, b)
		border:Show()
	else
		texture:SetVertexColor(1, 1, 1, a)
		border:Hide()
	end
end

local function CreateCombatFlag(self, overlay)
	local combatFlag = self:SpawnTexture(overlay, SMALL_ICON_SIZE, "BOTTOMLEFT", INSET, INSET)
	combatFlag:Hide()

	local group = combatFlag:CreateAnimationGroup()
	group:SetScript("OnFinished", function()
		combatFlag:SetAlpha(0)
		combatFlag:SetScale(1)
	end)

	local scale1 = group:CreateAnimation("Scale")
	scale1:SetDuration(0.25)
	scale1:SetScale(3, 3)
	scale1:SetOrder(10)

	local scale2 = group:CreateAnimation("Scale")
	scale2:SetDuration(0.25)
	scale2:SetScale(1 / 3, 1 / 3)
	scale2:SetOrder(20)

	local alpha = group:CreateAnimation("Alpha")
	alpha:SetDuration(5.5)
	alpha:SetFromAlpha(1)
	alpha:SetToAlpha(0)
	alpha:SetOrder(30)

	local inCombat = false
	hooksecurefunc(combatFlag, "Show", function()
		if inCombat then
			return
		end
		inCombat = true
		combatFlag:SetScale(1)
		combatFlag:SetAlpha(1)
		group:Restart()
		group:Play()
	end)
	hooksecurefunc(combatFlag, "Hide", function()
		if not inCombat then
			return
		end
		inCombat = false
		group:Finish()
	end)

	return combatFlag
end

-- ------------------------------------------------------------------------------
-- Unit frame initialization
-- ------------------------------------------------------------------------------

local function InitFrame(self)
	self:RegisterForClicks("AnyDown")

	self:SetScript("OnEnter", oUF_Adirelle.Unit_OnEnter)
	self:SetScript("OnLeave", oUF_Adirelle.Unit_OnLeave)

	local backdropFrame = CreateFrame("Frame", nil, self, "BackdropTemplate")
	backdropFrame:SetFrameLevel(self:GetFrameLevel() - 1)
	backdropFrame:SetAllPoints()
	backdropFrame:SetBackdrop(backdrop)
	backdropFrame:SetBackdropColor(0, 0, 0, backdrop.bgAlpha)
	backdropFrame:SetBackdropBorderColor(0, 0, 0, 1)

	-- Let it have dispel click on mouse button 2
	self.CustomClick = {}

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints()
	hp.current, hp.max = 0, 0
	self.Health = hp
	self:RegisterStatusBarTexture(hp, "health")

	local hpbg = hp:CreateTexture(nil, "BACKGROUND", nil, -1)
	hpbg:SetAllPoints(hp)
	hpbg:SetAlpha(1)
	hp.bg = hpbg
	self:RegisterStatusBarTexture(hpbg, "health")

	-- Border
	local border = CreateFrame("Frame", nil, self, "BackdropTemplate")
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER")
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border:Hide()
	self.Border = border

	-- Status and color updates
	self.RaidColor = { PostUpdate = UpdateColor }

	-- Name
	local name = hp:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	name:SetPoint("TOPLEFT", 6, 0)
	name:SetPoint("BOTTOMRIGHT", -6, 0)
	name:SetJustifyH("CENTER")
	name:SetJustifyV("MIDDLE")
	self:RegisterFontString(name, "raid", 11, "")
	self:Tag(name, "[name]")
	self.Name = name

	-- LowHealth warning
	local lowHealth = hp:CreateTexture(nil, "OVERLAY", nil, 1)
	lowHealth:SetAllPoints(border)
	lowHealth:SetColorTexture(1, 0, 0, 0.5)
	self.LowHealth = lowHealth

	-- Range fading
	local xrange = hp:CreateTexture(nil, "OVERLAY", nil, -1)
	xrange:SetAllPoints(hp)
	xrange:SetColorTexture(0.5, 0.5, 0.5)
	xrange:SetBlendMode("MOD")
	self.XRange = xrange

	-- Heal prediction
	self:SpawnHealthPrediction(1.00)

	-- Indicator overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetAllPoints(self)
	overlay:SetFrameLevel(self:GetFrameLevel() + 10)
	self.Overlay = overlay

	-- Combat flag
	self.CombatFlag = CreateCombatFlag(self, overlay)

	-- ReadyCheck icon
	local rc = CreateFrame("Frame", self:GetName() .. "ReadyCheck", overlay)
	rc:SetFrameLevel(self:GetFrameLevel() + 5)
	rc:SetPoint("CENTER")
	rc.icon = rc:CreateTexture(rc:GetName() .. "Texture")
	rc.icon:SetAllPoints(rc)
	rc.SetTexture = function(_, ...)
		return rc.icon:SetTexture(...)
	end
	self.ReadyCheckIndicator = rc

	-- Other status icon
	local status = self:SpawnTexture(overlay, HEIGHT)
	status:SetPoint("TOPLEFT", self, 1, -1)
	status:SetPoint("BOTTOMLEFT", self, 1, 1)
	status.PostUpdate = Status_PostUpdate
	self.Status = status

	-- Have icons blinking 3 seconds before fading out
	self.iconBlinkThreshold = 3

	-- Important class buffs
	self.WarningIconBuff = self:CreateIcon(self.Overlay, ICON_SIZE, false, false, true, false, "CENTER", self, "LEFT", WIDTH * 0.25, 0) -- luacheck: no max line length

	-- Cureable debuffs
	local debuff = self:CreateIcon(self.Overlay, ICON_SIZE, false, false, false, false, "CENTER")
	debuff.big = true
	debuff.SetColor = CureableDebuff_SetColor
	self:AddAuraIcon(debuff, "CureableDebuff")

	-- Important debuffs
	self.WarningIconDebuff = self:CreateIcon(self.Overlay, ICON_SIZE, false, false, false, false, "CENTER", self, "RIGHT", -WIDTH * 0.25, 0) -- luacheck: no max line length
	self.WarningIconDebuff.noDispellable = true

	-- Class-specific icons
	CreateClassAuraIcons(self)

	-- Threat glow
	local threat = CreateFrame("Frame", nil, self, "BackdropTemplate")
	threat:SetAllPoints(self)
	threat:SetBackdrop(glowBorderBackdrop)
	threat:SetBackdropColor(0, 0, 0, 0)
	threat.SetVertexColor = threat.SetBackdropBorderColor
	threat:SetAlpha(glowBorderBackdrop.alpha)
	threat:SetFrameLevel(self:GetFrameLevel() + 2)
	threat.percentAsAlpha = true
	threat.lowAlpha = 0.3
	threat.highAlpha = 1.0
	self.SmartThreat = threat

	-- Role/Raid icon
	local roleIcon = overlay:CreateTexture(nil, "ARTWORK")
	roleIcon:SetSize(SMALL_ICON_SIZE, SMALL_ICON_SIZE)
	roleIcon:SetPoint("LEFT", self, "LEFT", INSET, 0)
	roleIcon.noDamager = true
	roleIcon.noCircle = true
	self.RoleIcon = roleIcon

	-- Target raid icon
	local targetIcon = overlay:CreateTexture(nil, "ARTWORK")
	targetIcon:SetSize(SMALL_ICON_SIZE, SMALL_ICON_SIZE)
	targetIcon:SetPoint("RIGHT", self, "RIGHT", -INSET, 0)
	self.TargetIcon = targetIcon

	-- AlternativePower
	local alternativePower = CreateFrame("StatusBar", nil, self, "BackdropTemplate")
	alternativePower:SetBackdrop(backdrop)
	alternativePower:SetBackdropColor(0, 0, 0, 1)
	alternativePower:SetBackdropBorderColor(0, 0, 0, 0)
	alternativePower:SetPoint("BOTTOMLEFT")
	alternativePower:SetPoint("BOTTOMRIGHT")
	alternativePower:SetHeight(5)
	alternativePower:Hide()
	alternativePower.PostUpdate = AlternativePower_PostUpdate
	alternativePower:SetScript("OnShow", AlternativePower_Layout)
	alternativePower:SetScript("OnHide", AlternativePower_Layout)
	alternativePower:SetFrameLevel(threat:GetFrameLevel() + 1)
	self:RegisterStatusBarTexture(alternativePower, "altpower")
	self.AlternativePower = alternativePower

	-- Setting callbacks
	self:RegisterMessage("OnSettingsModified", OnRaidLayoutModified)
	self:RegisterMessage("OnRaidLayoutModified", OnRaidLayoutModified)
	self:RegisterMessage("OnSettingsModified", function()
		self.RaidColor:PostUpdate()
	end)
	self:RegisterMessage("OnColorModified", function()
		self.RaidColor:PostUpdate()
	end)
	self:RegisterMessage("OnSettingsModified", OnThemeModified)
	self:RegisterMessage("OnThemeModified", OnThemeModified)

	-- Hook OnSizeChanged to layout internal on size change
	self:HookScript("OnSizeChanged", OnSizeChanged)
	OnSizeChanged(self, WIDTH, HEIGHT)
end

-- ------------------------------------------------------------------------------
-- Style and layout setup
-- ------------------------------------------------------------------------------

oUF:RegisterStyle("Adirelle_Raid", InitFrame)

oUF_Adirelle.RaidStyle = true

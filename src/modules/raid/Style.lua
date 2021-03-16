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
local GetSpellInfo = assert(_G.GetSpellInfo, "_G.GetSpellInfo is undefined")
local GetUnitPowerBarTextureInfo = assert(_G.GetUnitPowerBarTextureInfo, "_G.GetUnitPowerBarTextureInfo is undefined")
local gsub = assert(_G.gsub, "_G.gsub is undefined")
local hooksecurefunc = assert(_G.hooksecurefunc, "_G.hooksecurefunc is undefined")
local pairs = assert(_G.pairs, "_G.pairs is undefined")
local select = assert(_G.select, "_G.select is undefined")
local strmatch = assert(_G.strmatch, "_G.strmatch is undefined")
local tonumber = assert(_G.tonumber, "_G.tonumber is undefined")
local UnitClass = assert(_G.UnitClass, "_G.UnitClass is undefined")
local UnitName = assert(_G.UnitName, "_G.UnitName is undefined")
local UNKNOWN = assert(_G.UNKNOWN, "_G.UNKNOWN is undefined")
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local ALT_POWER_TEX_FILL = _G.ALT_POWER_TEX_FILL or 2

-- Import some values from oUF_Adirelle namespace
local GetFrameUnitState = assert(oUF_Adirelle.GetFrameUnitState)
local backdrop = assert(oUF_Adirelle.backdrop)
local glowBorderBackdrop = assert(oUF_Adirelle.glowBorderBackdrop)

-- Constants
local SCALE = 1.0
local WIDTH = 80
local SPACING = 2
local HEIGHT = 25
local BORDER_WIDTH = 1
local ICON_SIZE = 14
local INSET = 1
local SMALL_ICON_SIZE = 8

local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]],
	edgeSize = BORDER_WIDTH,
}

-- Export some constants
private.SCALE = SCALE
private.WIDTH = WIDTH
private.SPACING = SPACING
private.HEIGHT = HEIGHT
private.BORDER_WIDTH = BORDER_WIDTH
private.ICON_SIZE = ICON_SIZE

-- ------------------------------------------------------------------------------
-- Health bar and name updates
-- ------------------------------------------------------------------------------

-- Update health color
local function UpdateColor(self, event, unit)
	if unit and (unit ~= self.unit and unit ~= self.realUnit) then
		return
	end
	local refUnit = (self.realUnit or self.unit):gsub("pet", "")
	if refUnit == "" then
		refUnit = "player"
	end -- 'pet'
	local class = self.colorClass and UnitName(refUnit) ~= UNKNOWN and select(2, UnitClass(refUnit))
	local state = GetFrameUnitState(self, true) or class or ""
	if state ~= self.__stateColor or not event then
		self.__stateColor = state
		local r, g, b
		if class then
			r, g, b = unpack(oUF.colors.class[class])
		else
			r, g, b = unpack(oUF.colors.health)
		end
		if state == "DEAD" or state == "DISCONNECTED" then
			r, g, b = unpack(oUF.colors.disconnected)
		elseif state == "CHARMED" then
			r, g, b = unpack(oUF.colors.charmed.background)
		elseif state == "INVEHICLE" then
			r, g, b = unpack(oUF.colors.vehicle.background)
		end
		self.bgColor[1], self.bgColor[2], self.bgColor[3] = r, g, b
		if self.invertedBar then
			self.Health.bg:SetVertexColor(r, g, b, 1)
			self.Health:SetStatusBarColor(0, 0, 0, 0.75)
		else
			self.Health.bg:SetVertexColor(0, 0, 0, 1)
			self.Health:SetStatusBarColor(r, g, b, 0.75)
		end
	end
end

-- Add a pseudo-element to update the color
do
	local function UNIT_PET(self, event, unit)
		if unit == "player" then
			return UpdateColor(self, event, "pet")
		elseif unit then
			return UpdateColor(self, event, gsub(unit, "(%d*)$", "pet%1"))
		end
	end

	oUF:AddElement("Adirelle_Raid:UpdateColor", UpdateColor, function(self)
		if self.Health and self.bgColor and self.style == "Adirelle_Raid" then
			self:RegisterEvent("UNIT_NAME_UPDATE", UpdateColor)
			if self.unit and strmatch(self.unit, "pet") then
				self:RegisterEvent("UNIT_PET", UNIT_PET)
			end
			return true
		end
	end, function()
	end)
end

-- Layout internal frames on size change
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

-- ------------------------------------------------------------------------------
-- Aura icon initialization
-- ------------------------------------------------------------------------------

do
	local GetAnyAuraFilter = private.GetAnyAuraFilter

	local band = _G.bit.band
	local LPS = oUF_Adirelle.GetLib("LibPlayerSpells-1.0")
	local requiredFlags = oUF_Adirelle.playerClass .. " AURA"
	local rejectedFlags = "INTERRUPT DISPEL BURST SURVIVAL HARMFUL"
	local INVERT_AURA = LPS.constants.INVERT_AURA
	local UNIQUE_AURA = LPS.constants.UNIQUE_AURA

	local anchors = { "TOPLEFT", "TOPRIGHT", "BOTTOMRIGHT", "BOTTOMLEFT", "TOP", "RIGHT", "BOTTOM", "LEFT" }

	local filters = {}
	local defaultAnchors = {}
	local count = 0

	local ExpandFlags
	do
		local C = LPS.constants

		local function expandSimple2(flags, n, ...)
			if not n then
				return
			end
			local v = C[n]
			if band(flags, v) ~= 0 then
				return n, expandSimple2(flags, ...)
			else
				return expandSimple2(flags, ...)
			end
		end

		local function expandSimple(flags, n, ...)
			if not n then
				if band(flags, C.DISPEL) ~= 0 then
					return expandSimple2(flags, "CURSE", "DISEASE", "MAGIC", "POISON")
				end
				if band(flags, C.CROWD_CTRL) ~= 0 then
					return expandSimple2(flags, "DISORIENT", "INCAPACITATE", "ROOT", "STUN", "TAUNT")
				end
				return expandSimple2(
					flags,
					"DEATHKNIGHT",
					"DEMONHUNTER",
					"DRUID",
					"HUNTER",
					"MAGE",
					"MONK",
					"PALADIN",
					"PRIEST",
					"ROGUE",
					"SHAMAN",
					"WARLOCK",
					"WARRIOR",
					"RACIAL"
				)
			end
			local v = C[n]
			if band(flags, v) ~= 0 then
				return n, expandSimple(flags, ...)
			else
				return expandSimple(flags, ...)
			end
		end

		function ExpandFlags(flags)
			return expandSimple(
				flags,
				"DISPEL",
				"CROWD_CTRL",
				"HELPFUL",
				"HARMFUL",
				"PERSONAL",
				"PET",
				"AURA",
				"INVERT_AURA",
				"UNIQUE_AURA",
				"COOLDOWN",
				"SURVIVAL",
				"BURST",
				"POWER_REGEN",
				"IMPORTANT",
				"INTERRUPT",
				"KNOCKBACK",
				"SNARE"
			)
		end
	end

	for spellId, flags in LPS:IterateSpells("HELPFUL PET", requiredFlags, rejectedFlags) do
		local auraFilter = band(flags, INVERT_AURA) ~= 0 and "HARMFUL" or "HELPFUL"
		if band(flags, UNIQUE_AURA) == 0 then
			auraFilter = auraFilter .. " PLAYER"
		end
		oUF_Adirelle.Debug(
			"Watching buff",
			spellId,
			GetSpellInfo(spellId),
			"with filter",
			auraFilter,
			"flags: ",
			ExpandFlags(flags)
		)

		filters[spellId] = GetAnyAuraFilter(spellId, auraFilter)
		count = (count % #anchors) + 1
		defaultAnchors[spellId] = anchors[count]
	end

	oUF_Adirelle.ClassAuraIcons = {
		filters = filters,
		defaultAnchors = defaultAnchors,
	}
end

local function CreateClassAuraIcons(self)
	self.ClassAuraIcons = {}
	for id, filter in pairs(oUF_Adirelle.ClassAuraIcons.filters) do
		local icon = self:CreateIcon(self.Overlay, SMALL_ICON_SIZE, true, true, true, false)
		self.ClassAuraIcons[id] = icon
		self:AddAuraIcon(icon, filter)
	end
end

local function LayoutClassAuraIcons(self, layout)
	for id, icon in pairs(self.ClassAuraIcons) do
		local anchor = layout.Raid.classAuraIcons[id] or oUF_Adirelle.ClassAuraIcons.defaultAnchors[id]
		icon:ClearAllPoints()
		if anchor and anchor ~= "HIDDEN" then
			local xOffset = strmatch(anchor, "LEFT") and INSET or strmatch(anchor, "RIGHT") and -INSET or 0
			local yOffset = strmatch(anchor, "BOTTOM") and INSET or strmatch(anchor, "TOP") and -INSET or 0
			icon:SetPoint(anchor, xOffset, yOffset)
		end
	end
end

-- ------------------------------------------------------------------------------
-- Alternate Power Bar
-- ------------------------------------------------------------------------------

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
	UpdateColor(self)

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

local function AttachFadeOutAnimation(region)
	local group = region:CreateAnimationGroup()
	group:SetScript("OnFinished", function()
		region:SetAlpha(0)
	end)

	local alpha = group:CreateAnimation("Alpha")
	alpha:SetStartDelay(1)
	alpha:SetDuration(3)
	alpha:SetFromAlpha(1)
	alpha:SetToAlpha(0)

	hooksecurefunc(region, "Show", function()
		region:SetAlpha(1)
		group:Restart()
		group:Play()
	end)
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

	-- Health bar
	self.bgColor = { 1, 1, 1 }
	self.nameColor = { 1, 1, 1 }

	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetPoint("TOPLEFT")
	hp:SetPoint("BOTTOMRIGHT")
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

	-- Name
	local name = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal", 3)
	name:SetPoint("TOPLEFT", 6, 0)
	name:SetPoint("BOTTOMRIGHT", -6, 0)
	name:SetJustifyH("CENTER")
	name:SetJustifyV("MIDDLE")
	self:RegisterFontString(name, "raid", 11, "")
	self:Tag(name, "[$>statusIcon<$ ][raidcolor][name]|r")

	-- LowHealth warning
	local lowHealth = hp:CreateTexture(nil, "OVERLAY", 2)
	lowHealth:SetAllPoints(border)
	lowHealth:SetColorTexture(1, 0, 0, 0.5)
	self.LowHealth = lowHealth

	-- Range fading
	local xrange = hp:CreateTexture(nil, "OVERLAY", 1)
	xrange:SetAllPoints(self)
	xrange:SetColorTexture(0.4, 0.4, 0.4)
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
	local combatFlag = self:SpawnTexture(overlay, SMALL_ICON_SIZE, "BOTTOMLEFT", INSET, INSET)
	combatFlag:Hide()
	AttachFadeOutAnimation(combatFlag)
	self.CombatFlag = combatFlag

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
	self:RegisterMessage("OnSettingsModified", UpdateColor)
	self:RegisterMessage("OnColorModified", UpdateColor)
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

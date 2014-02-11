--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local abs = _G.abs
local ALTERNATE_POWER_INDEX = _G.ALTERNATE_POWER_INDEX
local CreateFrame = _G.CreateFrame
local floor = _G.floor
local format = _G.format
local GetTime = _G.GetTime
local gsub = _G.gsub
local huge = _G.math.huge
local pairs = _G.pairs
local SecureButton_GetUnit = _G.SecureButton_GetUnit
local select = _G.select
local strmatch = _G.strmatch
local strsub = _G.strsub
local tostring = _G.tostring
local UnitAlternatePowerInfo = _G.UnitAlternatePowerInfo
local UnitAlternatePowerTextureInfo = _G.UnitAlternatePowerTextureInfo
local UnitClass = _G.UnitClass
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitName = _G.UnitName
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UNKNOWN = _G.UNKNOWN
local unpack = _G.unpack
--GLOBALS>
local mmin, mmax = _G.min, _G.max

-- Import some values from oUF_Adirelle namespace
local GetFrameUnitState = oUF_Adirelle.GetFrameUnitState
local backdrop, glowBorderBackdrop = oUF_Adirelle.backdrop, oUF_Adirelle.glowBorderBackdrop

-- Constants
local SCALE = 1.0
local WIDTH = 80
local SPACING = 2
local HEIGHT = 25
local BORDER_WIDTH = 1
local ICON_SIZE = 14
local INSET = 1
local SMALL_ICON_SIZE = 8
local borderBackdrop = { edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]], edgeSize = BORDER_WIDTH }

-- Export some constants
oUF_Adirelle.SCALE, oUF_Adirelle.WIDTH, oUF_Adirelle.SPACING, oUF_Adirelle.HEIGHT, oUF_Adirelle.BORDER_WIDTH, oUF_Adirelle.ICON_SIZE = SCALE, WIDTH, SPACING, HEIGHT, BORDER_WIDTH, ICON_SIZE

-- ------------------------------------------------------------------------------
-- Health bar and name updates
-- ------------------------------------------------------------------------------

-- Health point formatting
local function SmartHPValue(value)
	if abs(value) >= 1000 then
		return format("%.1fk",value/1000)
	else
		return format("%d", value)
	end
end

-- Update name
local function UpdateName(self, event, unit)
	if not unit then
		unit = self.unit
	elseif unit ~= self.unit and unit ~= self.realUnit then
		return
	end
	local healthBar = self.Health
	local r, g, b = 0.5, 0.5, 0.5
	if self.nameColor then
		r, g, b = unpack(self.nameColor)
	end
	if UnitCanAssist('player', unit) then
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		local incHeal = UnitGetIncomingHeals(unit) or 0
		local absorb = UnitGetTotalAbsorbs(unit) or 0
		local healAbsorb = UnitGetTotalHealAbsorbs(unit) or 0
		local threshold = maxHealth * 0.25
		if healAbsorb > 0 and health - healAbsorb <= threshold then
			r, g, b = unpack(oUF.colors.healPrediction.healAbsorb)
		elseif health - healAbsorb + incHeal >= maxHealth + threshold then
			r, g, b = unpack(oUF.colors.healPrediction.self)
		end
	end
	self.Name:SetTextColor(r, g, b, 1)
	self.Name:SetText(unit and UnitName(unit) or UNKNOWN)
end

-- Update health and name color
local function UpdateColor(self, event, unit)
	if unit and (unit ~= self.unit and unit ~= self.realUnit) then return end
	local refUnit = (self.realUnit or self.unit):gsub('pet', '')
	if refUnit == '' then refUnit = 'player' end -- 'pet'
	local class = UnitName(refUnit) ~= UNKNOWN and select(2, UnitClass(refUnit))
	local state = GetFrameUnitState(self, true) or class or ""
	if state ~= self.__stateColor then
		self.__stateColor = state
		local r, g, b = 0.5, 0.5, 0.5
		if class then
			r, g, b = unpack(oUF.colors.class[class])
		end
		local nR, nG, nB = r, g, b
		if state == "DEAD" or state == "DISCONNECTED" then
			r, g, b = unpack(oUF.colors.disconnected)
		elseif state == "CHARMED" then
			r, g, b = unpack(oUF.colors.charmed.background)
			nR, nG, nB = unpack(oUF.colors.charmed.name)
		elseif state == "INVEHICLE" then
			r, g, b = unpack(oUF.colors.vehicle.background)
			nR, nG, nB = unpack(oUF.colors.vehicle.name)
		end
		self.bgColor[1], self.bgColor[2], self.bgColor[3] = r, g, b
		self.Health.bg:SetVertexColor(r, g, b, 1)
		self.nameColor[1], self.nameColor[2], self.nameColor[3] = nR, nG, nB
	end
	return UpdateName(self)
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

	oUF:AddElement('Adirelle_Raid:UpdateColor',
		UpdateColor,
		function(self)
			if self.Health and self.bgColor and self.style == "Adirelle_Raid" then
				self:RegisterEvent('UNIT_NAME_UPDATE', UpdateColor)
				self:RegisterEvent('UNIT_HEAL_PREDICTION', UpdateName)
				self:RegisterEvent('UNIT_MAXHEALTH', UpdateName)
				self:RegisterEvent('UNIT_HEALTH', UpdateName)
				self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', UpdateName)
				self:RegisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', UpdateName)
				if self.unit and strmatch(self.unit, 'pet') then
					self:RegisterEvent('UNIT_PET', UNIT_PET)
				end
				return true
			end
		end,
		function() end
	)
end

-- Layout internal frames on size change
local function OnSizeChanged(self, width, height)
	width = width or self:GetWidth()
	height = height or self:GetHeight()
	if not width or not height then return end
	local w = BORDER_WIDTH / self:GetEffectiveScale()
	self.Border:SetSize(width + 2 * w, height + 2 * w)
	self.ReadyCheck:SetSize(height, height)
	self.StatusIcon:SetSize(height*2, height)
	self.WarningIconBuff:SetPoint("CENTER", self, "LEFT", width / 4, 0)
	self.WarningIconDebuff:SetPoint("CENTER", self, "RIGHT", -width / 4, 0)
end

-- ------------------------------------------------------------------------------
-- Aura icon initialization
-- ------------------------------------------------------------------------------

local CreateClassAuraIcons
do
	local playerClass = oUF_Adirelle.playerClass
	local GetOwnAuraFilter, GetOwnStackedAuraFilter, GetAnyAuraFilter = private.GetOwnAuraFilter, private.GetOwnStackedAuraFilter, private.GetAnyAuraFilter

	local function SpawnSmallIcon(self, ...) return self:CreateIcon(self.Overlay, SMALL_ICON_SIZE, true, true, true, false, ...)	end

	-- Create the specific icons depending on player class
	if playerClass == "DRUID" then
		function CreateClassAuraIcons(self)
			-- Rejuvenation
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPLEFT", self, "TOPLEFT", INSET, -INSET),
				GetOwnAuraFilter(774, 0.6, 0, 1)
			)
			-- Regrowth
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOP", self, "TOP", 0, -INSET),
				GetOwnAuraFilter(8936, 0, 0.6, 0)
			)
			-- Lifebloom
			local prev
			for i = 1, 3 do
				local icon = SpawnSmallIcon(self)
				icon.blinkThreshold = 4
				if i == 1 then
					icon:SetPoint("TOPRIGHT", -INSET, -INSET)
				else
					icon:SetPoint("TOPRIGHT", prev, "TOPLEFT", -INSET, 0)
				end
				prev = icon
				self:AddAuraIcon(icon, GetOwnStackedAuraFilter(33763, i, 0, 1, 0))
			end
			-- Wild Growth
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET),
				GetOwnAuraFilter(48438, 0, 1, 0)
			)

			-- Symbiosis
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMRIGHT", self, "BOTTOMRIGHT", INSET, INSET),
				GetOwnAuraFilter(110309, 0, 1, 0)
			)
		end

	elseif playerClass == 'PALADIN' then
		function CreateClassAuraIcons(self)
			-- Beacon of light
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
				GetOwnAuraFilter(53563)
			)
		end

	elseif playerClass == "SHAMAN" then
		function CreateClassAuraIcons(self)
			-- Earth Shield
			local prev
			for i = 1, 6 do
				local icon = SpawnSmallIcon(self)
				if i == 1 then
					icon:SetPoint("BOTTOMRIGHT", -INSET, -INSET)
				else
					icon:SetPoint("BOTTOMRIGHT", prev, "BOTTOMLEFT", -INSET, 0)
				end
				prev = icon
				self:AddAuraIcon(icon, GetOwnStackedAuraFilter(974, i))
			end
			-- Riptide
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
				GetOwnAuraFilter(61295)
			)
		end

	elseif playerClass == 'WARLOCK' then
		function CreateClassAuraIcons(self)
			-- Soulstones
			self:AddAuraIcon(SpawnSmallIcon(self, "BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET), GetAnyAuraFilter(20707, "HELPFUL"))
		end

	elseif playerClass == 'PRIEST' then
		function CreateClassAuraIcons(self)
			-- PW:Shield or Weakened Soul
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPLEFT", self, "TOPLEFT", INSET, -INSET),
				"PW:Shield"
			)
			-- Renew
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
				GetOwnAuraFilter(139)
			).blinkThreshold = 4
			-- Prayer of Mending
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -INSET, INSET),
				GetOwnAuraFilter(33076)
			)
			-- Lightwell Renew
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET),
				GetOwnAuraFilter(7001)
			)
		end

	elseif playerClass == 'MONK' then
		function CreateClassAuraIcons(self)
			-- Enveloping Mist
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPLEFT", self, "TOPLEFT", INSET, -INSET),
				GetOwnAuraFilter(132120)
			)
			-- Renewing mists
			local prev
			for i = 1, 3 do
				local icon = SpawnSmallIcon(self)
				if i == 1 then
					icon:SetPoint("TOPRIGHT", -INSET, -INSET)
				else
					icon:SetPoint("TOPRIGHT", prev, "TOPLEFT", -INSET, 0)
				end
				prev = icon
				self:AddAuraIcon(icon, GetOwnStackedAuraFilter(119611, i))
			end
			-- Soothing Mist from the Jade Serpent Statue
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET),
				GetOwnAuraFilter(125950)
			)
			-- Zen Sphere
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMRIGHT", self, "BOTTOMRIGHT", INSET, INSET),
				GetOwnAuraFilter(124081)
			)
		end

	end
end

-- ------------------------------------------------------------------------------
-- Alternate Power Bar
-- ------------------------------------------------------------------------------

local function AltPowerBar_SetValue(bar, value)
	if bar.alert or value ~= bar:GetValue() or bar.highlight ~= bar._highlight then
		local r, g, b = bar.red or 1, bar.green or 1, bar.blue or 1
		if bar.alert then
			local f = 2 * (GetTime() % 1)
			if f > 1 then
				f = 2 - f
			end
			r, g, b = oUF.ColorGradient(f, 1, r, g, b, 1, 0, 0)
		end
		bar:SetStatusBarColor(mmax(r, bar.highlight), mmax(g, bar.highlight), mmax(b, bar.highlight))
		bar._highlight = bar.highlight
	end
	return bar:_SetValue(value)
end

local function AltPowerBar_OnUpdate(bar, elapsed)
	local value, target = floor(bar:GetValue()+0.5), bar.target
	if target > value then
		value = mmin(value + bar.range * elapsed / 3, target)
	else
		if bar.highlight > 0 then
			bar.highlight = mmax(bar.highlight - elapsed / 0.3, 0)
		end
		if target < value then
			value = mmax(value - bar.range * elapsed / 3, target)
		end
	end
	bar:SetValue(value)
	if not bar.alert and value == target and bar.highlight == 0 then
		bar:SetScript('OnUpdate', nil)
	end
end

local function AltPowerBar_Override(self, event, unit, powerType)
	if unit and self.unit ~= unit or powerType and powerType ~= 'ALTERNATE' then return end
	unit = self.unit

	local bar, _ = self.AltPowerBar
	if event == "ForceUpdate" or event == "UNIT_MAXPOWER" then
		_, bar.min, _, _, bar.smooth = UnitAlternatePowerInfo(unit)
		bar.max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
		bar.red, bar.green, bar.blue = select(2, UnitAlternatePowerTextureInfo(unit, 2))
		bar.range = bar.max - bar.min
		bar:SetMinMaxValues(bar.min, bar.max)
		bar:SetValue(bar.min)
	end

	local cur = mmin(mmax(UnitPower(unit, ALTERNATE_POWER_INDEX), bar.min), bar.max)
	if cur > bar.target then
		bar.highlight = 1
	end
	bar.target = cur
	bar.alert = (cur-bar.min)/bar.range > 0.8
	if not bar.smooth then
		bar:SetValue(cur)
	end
	if bar.alert or bar.highlight > 0 or abs(bar:GetValue()-bar.target) > 0.01 then
		bar:SetScript('OnUpdate', AltPowerBar_OnUpdate)
	end
end

local function AltPowerBar_Layout(bar)
	local self = bar.__owner
	if bar:IsShown() then
		self.Health:SetPoint("BOTTOMRIGHT", bar, "TOPRIGHT", 0, 0)
		bar.highlight, bar.target = 0, 0
	else
		self.Health:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
	end
end

local function XRange_PostUpdate(xrange, event, unit, inRange)
	xrange.__owner:SetAlpha(inRange and 1 or oUF.colors.outOfRange[4])
end

local function OnRaidLayoutModified(self, event, layout)
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
end

local function OnThemeModified(self, event, layout, theme)
	-- Update border settings
	local border = self.Border
	for k, v in pairs(theme.Border) do
		border[k] = v
	end
	border:ForceUpdate()

	-- Update low health threshold
	local lowHealth = self.LowHealth
	if lowHealth then
		local prefs = theme.LowHealth
		lowHealth.threshold = prefs.isPercent and -prefs.percent or prefs.amount
		lowHealth:ForceUpdate()
	end
end

local function OnColorModified(self)
	self.XRange.Texture:SetTexture(unpack(oUF.colors.outOfRange, 1, 3))
	self.XRange:ForceUpdate()
	return UpdateColor(self)
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

-- ------------------------------------------------------------------------------
-- Unit frame initialization
-- ------------------------------------------------------------------------------

local function InitFrame(self, unit)
	self:RegisterForClicks("AnyDown")

	self:SetScript("OnEnter", oUF_Adirelle.Unit_OnEnter)
	self:SetScript("OnLeave", oUF_Adirelle.Unit_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, backdrop.bgAlpha)
	self:SetBackdropBorderColor(0, 0, 0, 1)

	-- Let have custom click
	self.CustomClick = {}

	-- Health bar
	local hp = CreateFrame("StatusBar", nil, self)
	hp.Update = Health_Update
	hp.current, hp.max = 0, 0
	hp:SetPoint("TOPLEFT")
	hp:SetPoint("BOTTOMRIGHT")
	hp.frequentUpdates = true
	self.Health = hp
	self:RegisterStatusBarTexture(hp)
	hp:SetStatusBarColor(0, 0, 0, 0.75)

	self.bgColor = { 1, 1, 1 }
	self.nameColor = { 1, 1, 1 }

	local hpbg = hp:CreateTexture(nil, "BACKGROUND", nil, -1)
	hpbg:SetAllPoints(hp)
	hpbg:SetAlpha(1)
	hp.bg = hpbg
	self:RegisterStatusBarTexture(hpbg)

	-- Heal prediction
	self:SpawnHealPrediction(1.00)

	-- Border
	local border = CreateFrame("Frame", nil, self)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER")
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border:Hide()
	self.Border = border

	-- Indicator overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetAllPoints(self)
	overlay:SetFrameLevel(border:GetFrameLevel()+3)
	self.Overlay = overlay

	-- Name
	local name = overlay:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	name:SetPoint("TOPLEFT", 6, 0)
	name:SetPoint("BOTTOMRIGHT", -6, 0)
	name:SetJustifyH("CENTER")
	name:SetJustifyV("MIDDLE")
	self:RegisterFontString(name, "raid", 11, "")
	self.Name = name

	-- Big status icon
	local status = overlay:CreateTexture(nil, "BORDER", nil, 1)
	status:SetPoint("CENTER")
	status:SetAlpha(0.75)
	status:SetBlendMode("ADD")
	status:Hide()
	status.PostUpdate = UpdateColor
	self.StatusIcon = status

	-- ReadyCheck icon
	local rc = CreateFrame("Frame", self:GetName().."ReadyCheck", overlay)
	rc:SetFrameLevel(self:GetFrameLevel()+5)
	rc:SetPoint('CENTER')
	rc:SetAlpha(1)
	rc:Hide()
	rc.icon = rc:CreateTexture(rc:GetName().."Texture")
	rc.icon:SetAllPoints(rc)
	rc.SetTexture = function(_, ...) return rc.icon:SetTexture(...) end
	self.ReadyCheck = rc

	-- Have icons blinking 3 seconds before fading out
	self.iconBlinkThreshold = 3

	-- Important class buffs
	self.WarningIconBuff = self:CreateIcon(self.Overlay, ICON_SIZE, false, false, true, false, "CENTER", self, "LEFT", WIDTH * 0.25, 0)

	-- Cureable debuffs
	local debuff = self:CreateIcon(self.Overlay, ICON_SIZE, false, false, false, false, "CENTER")
	debuff.big = true
	debuff.SetColor = CureableDebuff_SetColor
	self:AddAuraIcon(debuff, "CureableDebuff")

	-- Important debuffs
	self.WarningIconDebuff = self:CreateIcon(self.Overlay, ICON_SIZE, false, false, false, false, "CENTER", self, "RIGHT", -WIDTH * 0.25, 0)
	self.WarningIconDebuff.noDispellable = true

	-- Class-specific icons
	if CreateClassAuraIcons then
		CreateClassAuraIcons(self)
	end

	-- Threat glow
	local threat = CreateFrame("Frame", nil, self)
	threat:SetAllPoints(self)
	threat:SetBackdrop(glowBorderBackdrop)
	threat:SetBackdropColor(0,0,0,0)
	threat.SetVertexColor = threat.SetBackdropBorderColor
	threat:SetAlpha(glowBorderBackdrop.alpha)
	threat:SetFrameLevel(self:GetFrameLevel()+2)
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

	-- LowHealth warning
	local lowHealth = hp:CreateTexture(nil, "OVERLAY")
	lowHealth:SetAllPoints(border)
	lowHealth:SetTexture(1, 0, 0, 0.5)
	self.LowHealth = lowHealth

	-- AltPowerBar
	local altPowerBar = CreateFrame("StatusBar", nil, self)
	altPowerBar:SetBackdrop(backdrop)
	altPowerBar:SetBackdropColor(0, 0, 0, 1)
	altPowerBar:SetBackdropBorderColor(0, 0, 0, 0)
	altPowerBar:SetPoint("BOTTOMLEFT")
	altPowerBar:SetPoint("BOTTOMRIGHT")
	altPowerBar:SetHeight(5)
	altPowerBar:Hide()
	altPowerBar.showOthersAnyway = true
	altPowerBar._SetValue = altPowerBar.SetValue
	altPowerBar.SetValue = AltPowerBar_SetValue
	altPowerBar.Override = AltPowerBar_Override
	altPowerBar:SetScript('OnShow', AltPowerBar_Layout)
	altPowerBar:SetScript('OnHide', AltPowerBar_Layout)
	altPowerBar:SetFrameLevel(threat:GetFrameLevel()+1)
	altPowerBar.highlight, altPowerBar.target = 0, huge
	self:RegisterStatusBarTexture(altPowerBar)
	self.AltPowerBar = altPowerBar

	-- Setting callbacks
	self:RegisterMessage('OnSettingsModified', OnRaidLayoutModified)
	self:RegisterMessage('OnRaidLayoutModified', OnRaidLayoutModified)
	self:RegisterMessage('OnSettingsModified', OnColorModified)
	self:RegisterMessage('OnColorModified', OnColorModified)
	self:RegisterMessage('OnSettingsModified', OnThemeModified)
	self:RegisterMessage('OnThemeModified', OnThemeModified)

	-- Range fading
	local xrange = CreateFrame("Frame", nil, overlay)
	xrange:SetAllPoints(self)
	xrange:SetFrameLevel(overlay:GetFrameLevel()+10)
	xrange.PostUpdate = XRange_PostUpdate

	local tex = xrange:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints(self)
	tex:SetTexture(0.4, 0.4, 0.4)
	tex:SetBlendMode("MOD")

	xrange.Texture = tex
	self.XRange = xrange

	-- Hook OnSizeChanged to layout internal on size change
	self:HookScript('OnSizeChanged', OnSizeChanged)
	OnSizeChanged(self, WIDTH, HEIGHT)
end

-- ------------------------------------------------------------------------------
-- Style and layout setup
-- ------------------------------------------------------------------------------

oUF:RegisterStyle("Adirelle_Raid", InitFrame)

oUF_Adirelle.RaidStyle = true


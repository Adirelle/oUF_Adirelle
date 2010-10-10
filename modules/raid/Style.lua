--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]
local UnitClass = UnitClass
local UnitName = UnitName
local GetTime = GetTime
local strformat = string.format
local strsub = string.sub
local mmin = math.min
local mmax = math.max
local abs = math.abs
local tostring = tostring
local unpack = unpack

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

SCALE = 1.0
WIDTH = 80
SPACING = 2
HEIGHT = 25
BORDER_WIDTH = 1
ICON_SIZE = 14

local borderBackdrop = { edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]], edgeSize = BORDER_WIDTH }

-- ------------------------------------------------------------------------------
-- Health bar and name updates
-- ------------------------------------------------------------------------------

-- Return the truncated name of unit
local function GetShortUnitName(unit)
	return unit and strsub(tostring(UnitName(unit)),1,10) or UNKNOWN
end

-- Health point formatting
local function SmartHPValue(value)
	if abs(value) >= 1000 then
		return strformat("%.1fk",value/1000)
	else
		return strformat("%d", value)
	end
end

-- Update name
local function UpdateName(self)
	local healthBar = self.Health
	local r, g, b = 0.5, 0.5, 0.5
	if self.bgColor then
		r, g, b = unpack(self.bgColor)
	end
	local text
	local healBar = self.IncomingHeal
	if healBar then
		local max = healBar.max
		if max > 0 then
			local overHeal = healBar.current + healBar.incoming + healBar.incomingOthers - max
			local f = overHeal / max
			if f > 0.1 then
				r, g, b = 0, 1, 0
				if f > 0.3 then
					text = "+"..SmartHPValue(overHeal)
				end
			end
		end
	end
	self.Name:SetTextColor(r, g, b, 1)
	self.Name:SetText(text or GetShortUnitName(SecureButton_GetUnit(self) or self.unit))
end

-- Update name and health bar on health change
local function Health_Update(self, event, unit)
	if self.unit ~= unit then return end
	local bar, max = self.Health, UnitHealthMax(unit) or 0
	bar.unit, bar.disconnected = unit, not UnitIsConnected(unit)
	local current = (bar.disconnected or UnitIsDeadOrGhost(unit)) and max or UnitHealth(unit) or 0
	if current ~= bar.current or max ~= bar.max then
		bar.current, bar.max = current, max
		bar:SetMinMaxValues(0, max)
		bar:SetValue(current)
		if bar.PostUpdate then
			bar:PostUpdate(unit, current, max)
		end
		return UpdateName(self)
	end
end

local IncomingHeal_PostUpdate, Health_PostUpdate
if oUF.HasIncomingHeal then
	-- Update incoming heal display
	local function UpdateHealBar(bar, unit, current, max, incoming, incomingOthers)
		if bar.current ~= current or bar.max ~= max or bar.incoming ~= incoming or bar.incomingOthers ~= incomingOthers then
			bar.current, bar.max, bar.incoming, bar.incomingOthers = current, max, incoming, incomingOthers
			local health = bar:GetParent()
			local self = health:GetParent()
			if max == 0 or current >= max then
				bar:Hide()
				self.IncomingOthersHeal:Hide()
				return
			end
			local pixelPerHP = health:GetWidth() / max
			if incomingOthers > 0 then
				local othersBar = self.IncomingOthersHeal
				local newCurrent = math.min(current + incomingOthers, max)
				othersBar:SetPoint('LEFT', health, 'LEFT', current * pixelPerHP, 0)
				othersBar:SetWidth((newCurrent-current) * pixelPerHP)
				othersBar:Show()
				current = newCurrent
			else
				self.IncomingOthersHeal:Hide()
			end
			if incoming > 0 and current < max then
				bar:SetPoint('LEFT', health, 'LEFT', current * pixelPerHP, 0)
				bar:SetWidth(math.min(max-current, incoming) * pixelPerHP)
				bar:Show()
			else
				bar:Hide()
			end
		end
	end

	function IncomingHeal_PostUpdate(bar, event, unit, incoming, incomingOthers)
		UpdateHealBar(bar, unit, bar.current, bar.max, incoming or 0, incomingOthers or 0)
		return UpdateName(bar:GetParent():GetParent())
	end

	function Health_PostUpdate(health, unit, current, max)
		local bar = health:GetParent().IncomingHeal
		return UpdateHealBar(bar, unit, current, max, bar.incoming, bar.incomingOthers)
	end
end

-- Update health and name color
local function UpdateColor(self, event, unit)
	if unit and unit ~= self.unit then return end
	local refUnit = (self.realUnit or self.unit):gsub('pet', '')
	if refUnit == '' then refUnit = 'player' end -- 'pet'
	local class = UnitName(refUnit) ~= UNKNOWN and select(2, UnitClass(refUnit))
	local state = oUF_Adirelle.GetFrameUnitState(self, true) or class or ""
	if state == self.__stateColor then return end
	self.__stateColor = state
	--self:Debug('UpdateColor', event, unit, state)
	local r, g, b = 0.5, 0.5, 0.5
	if state == "DEAD" or state == "DISCONNECTED" then
		r, g, b = unpack(self.colors.disconnected)
	elseif state == "CHARMED" then
		r, g, b = 1, 0.3, 0
	elseif state == "INVEHICLE" then
		r, g, b = 0.2, 0.6, 0
	elseif class then
		r, g, b = unpack(self.colors.class[class])
	end
	self.bgColor[1], self.bgColor[2], self.bgColor[3] = r, g, b
	self.Health.bg:SetVertexColor(r, g, b, 1)
	return UpdateName(self)
end

-- Add a pseudo-element to update the color
oUF:AddElement('Adirelle_Raid:UpdateColor',
	UpdateColor,
	function(self)
		if self.Health and self.bgColor and self.style == "Adirelle_Raid" then
			self:RegisterEvent('UNIT_NAME_UPDATE', UpdateColor)
			self:RegisterEvent('RAID_ROSTER_UPDATE', UpdateColor)
			self:RegisterEvent('PARTY_MEMBERS_CHANGED', UpdateColor)
			return true
		end
	end,
	function() end
)

-- Statusbar texturing
local function HealthBar_PostTextureUpdate(self)
	self:SetStatusBarColor(0, 0, 0, 0.75)
end

-- Layout internal frames on size change
local function OnSizeChanged(self, width, height)
	width = width or self:GetWidth()
	height = height or self:GetHeight()
	self.Border:SetWidth(width + 2 * BORDER_WIDTH)
	self.Border:SetHeight(height + 2 * BORDER_WIDTH)
	self.ReadyCheck:SetWidth(height)
	self.ReadyCheck:SetHeight(height)
	if self.DeathIcon then
		self.DeathIcon:SetWidth(height*2)
		self.DeathIcon:SetHeight(height)
	end
	if self.StatusIcon then
		self.StatusIcon:SetWidth(height*2)
		self.StatusIcon:SetHeight(height)
	end
end

-- ------------------------------------------------------------------------------
-- Aura icon initialization
-- ------------------------------------------------------------------------------

local CreateAuraIcons
do
	local INSET, SMALL_ICON_SIZE = 1, 8
	local function SpawnSmallIcon(self, ...) return self:SpawnAuraIcon(self.Overlay, SMALL_ICON_SIZE, true, true, true, false, ...)	end

	-- Create the specific icons depending on player class
	local CreateClassAuraIcons
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
			for i = 1, 3 do
				self:AddAuraIcon(
					SpawnSmallIcon(self, "TOPRIGHT", self, "TOPRIGHT", -INSET - SMALL_ICON_SIZE*(i-1), -INSET),
					GetOwnStackedAuraFilter(33763, i, 0, 1, 0)
				)
			end
			-- Wild Growth
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET),
				GetOwnAuraFilter(53248, 0, 1, 0)
			)
			-- Abolish Poison
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -INSET, INSET),
				GetOwnAuraFilter(2893)
			)
			-- Display cureable debuffs
			return true
		end

	elseif playerClass == 'PALADIN' then
		function CreateClassAuraIcons(self)
			-- Beacon of light
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
				GetOwnAuraFilter(53563)
			)
			-- Sacred Shield
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPLEFT", self, "TOPLEFT", INSET, -INSET),
				GetOwnAuraFilter(53601)
			)
			-- Display cureable debuffs
			return true
		end

	elseif playerClass == "SHAMAN" then
		function CreateClassAuraIcons(self)
			-- Earth Shield
			for i = 1, 6 do
				self:AddAuraIcon(
					SpawnSmallIcon(self, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -INSET - SMALL_ICON_SIZE*(i-1), INSET),
					GetOwnStackedAuraFilter(49284, i)
				)
			end
			-- Riptide
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
				GetOwnAuraFilter(61301)
			)
			-- Display cureable debuffs
			return true
		end

	elseif playerClass == 'WARLOCK' then
		function CreateClassAuraIcons(self)
			-- Soulstone
			self:AddAuraIcon(SpawnSmallIcon(self, "BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET), GetAnyAuraFilter(20763, "HELPFUL"))
			-- Display magic debuffs (for the Felhunter)
			return GetDebuffTypeFilter("Magic")
		end

	elseif playerClass == 'MAGE' then
		function CreateClassAuraIcons(self)
			-- Display curses
			return GetDebuffTypeFilter("Curse")
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
			)
			-- Prayer of Mending
			self:AddAuraIcon(
				SpawnSmallIcon(self, "BOTTOMRIGHT", self, "BOTTOMRIGHT", -INSET, INSET),
				GetOwnAuraFilter(48113)
			)
			-- Display cureable debuffs
			return true
		end

	end

	-- Main creation function
	function CreateAuraIcons(self)
		self.iconBlinkThreshold = 3

		-- Show important class buffs
		local importantBuff = self:SpawnAuraIcon(self.Overlay, ICON_SIZE)
		self:AddAuraIcon(importantBuff, "ClassImportantBuff")

		-- Show important debuffs
		local importantDebuff = self:SpawnAuraIcon(self.Overlay, ICON_SIZE)
		self:AddAuraIcon(importantDebuff, "ImportantDebuff")

		local cureableDebuffFilter = CreateClassAuraIcons and CreateClassAuraIcons(self)
		if cureableDebuffFilter then
			-- Show cureable debuffs
			local debuff = self:SpawnAuraIcon(self.Overlay, ICON_SIZE)
			self:AddAuraIcon(debuff, type(cureableDebuffFilter) == "string" and cureableDebuffFilter or "CureableDebuff")

			-- Layout icons
			importantBuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.25, 0)
			debuff:SetPoint("CENTER")
			importantDebuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.75, 0)
		else
			-- Layout icons
			importantBuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.33, 0)
			importantDebuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.66, 0)
		end

	end
end

-- ------------------------------------------------------------------------------
-- Unit frame initialization
-- ------------------------------------------------------------------------------

local function InitFrame(self, unit)
	self:RegisterForClicks("anyup")

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, backdrop.bgAlpha)
	self:SetBackdropBorderColor(0, 0, 0, 1)

	-- Health bar
	local hp = CreateFrame("StatusBar", nil, self)
	hp.Update = Health_Update
	hp.current, hp.max = 0, 0
	hp:SetAllPoints(self)
	self:RegisterStatusBarTexture(hp, HealthBar_PostTextureUpdate)
	self.Health = hp

	self.bgColor = { 1, 1, 1 }

	local hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetAllPoints(hp)
	hpbg:SetAlpha(1)
	self:RegisterStatusBarTexture(hpbg)
	hp.bg = hpbg

	-- Incoming heals
	if oUF.HasIncomingHeal then
		local heal = hp:CreateTexture(nil, "OVERLAY")
		heal:SetTexture(0, 1, 0, 0.5)
		heal:SetBlendMode("BLEND")
		heal:SetPoint("TOP")
		heal:SetPoint("BOTTOM")
		heal:Hide()
		heal.PostUpdate = IncomingHeal_PostUpdate
		heal.current, heal.max, heal.incoming, heal.incomingOthers = 0, 0, 0, 0
		self.IncomingHeal = heal

		local othersHeal = hp:CreateTexture(nil, "OVERLAY")
		othersHeal:SetTexture(0.5, 0, 1, 0.5)
		othersHeal:SetBlendMode("BLEND")
		othersHeal:SetPoint("TOP")
		othersHeal:SetPoint("BOTTOM")
		othersHeal:Hide()
		self.IncomingOthersHeal = othersHeal

		hp.PostUpdate = Health_PostUpdate
	end

	-- Indicator overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetAllPoints(self)
	overlay:SetFrameLevel(hp:GetFrameLevel()+3)
	self.Overlay = overlay

	-- Name
	local name = overlay:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	name:SetAllPoints(self)
	name:SetJustifyH("CENTER")
	name:SetJustifyV("MIDDLE")
	name:SetFont(GameFontNormal:GetFont(), 11)
	name:SetTextColor(1, 1, 1, 1)
	self.Name = name

	-- Border
	local border = CreateFrame("Frame", nil, self)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER", self)
	border:SetWidth(WIDTH + 2 * BORDER_WIDTH)
	border:SetHeight(HEIGHT + 2 * BORDER_WIDTH)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border:Hide()
	self.Border = border

	-- Big status icon
	local status = overlay:CreateTexture(nil, "OVERLAY")
	status:SetWidth(HEIGHT)
	status:SetHeight(HEIGHT)
	status:SetAlpha(0.75)
	status:SetPoint("CENTER")
	status:SetBlendMode("ADD")
	status:Hide()
	status.PostUpdate = UpdateColor
	self.StatusIcon = status

	-- ReadyCheck icon
	local rc = CreateFrame("Frame", nil, overlay)
	rc:SetFrameLevel(self:GetFrameLevel()+5)
	rc:SetPoint('CENTER', self)
	rc:SetWidth(HEIGHT)
	rc:SetHeight(HEIGHT)
	rc:SetAlpha(1)
	rc:Hide()
	rc.icon = rc:CreateTexture()
	rc.icon:SetAllPoints(rc)
	self.ReadyCheck = rc

	-- Aura icons
	CreateAuraIcons(self)

	-- Threat glow
	local threat = CreateFrame("Frame", nil, self)
	threat:SetAllPoints(self)
	threat:SetBackdrop(glowBorderBackdrop)
	threat:SetBackdropColor(0,0,0,0)
	threat.SetVertexColor = threat.SetBackdropBorderColor
	threat:SetAlpha(glowBorderBackdrop.alpha)
	threat:SetFrameLevel(self:GetFrameLevel()+2)
	self.Threat = threat

	-- Role/Raid icon
	local roleIcon = overlay:CreateTexture(nil, "OVERLAY")
	roleIcon:SetWidth(8)
	roleIcon:SetHeight(8)
	roleIcon:SetPoint("LEFT", self, INSET, 0)
	roleIcon.noDamager = true
	self.RoleIcon = roleIcon

	-- Hook OnSizeChanged to layout internal on size change
	self:HookScript('OnSizeChanged', OnSizeChanged)

	-- Range fading
	self.XRange = true
	self.inRangeAlpha = 1.0
	self.outsideRangeAlpha = 0.40
end

-- ------------------------------------------------------------------------------
-- Style and layout setup
-- ------------------------------------------------------------------------------

oUF:RegisterStyle("Adirelle_Raid", InitFrame)

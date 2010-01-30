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

-- Update name display
local function UpdateName(self)
	local r, g ,b = unpack(self.bgColor)
	local text
	local max = self.maxHealth or 0
	if not self.StatusIcon.currentState and max > 0 then
		local overHeal = self.currentHealth + self.incomingHeal + self.incomingOthersHeal - max
		local f = overHeal / max
		if f > 0.1 then
			r, g, b = 0, 1, 0
			if f > 0.3 then
				text = "+"..SmartHPValue(overHeal)
			end
		end
	end
	self.Name:SetTextColor(r, g, b, 1)
	self.Name:SetText(text or GetShortUnitName(self.realUnit or self.unit))
end

-- Update incoming heal display
local function UpdateHealBar(self)
	local current, max = self.currentHealth, self.maxHealth
	local healBar, othersHealBar = self.IncomingHeal, self.IncomingOthersHeal
	if max == 0 or current >= max then
		healBar:Hide()
		othersHealBar:Hide()
		return
	end
	local healthBar = self.Health
	local pixelPerHP = healthBar:GetWidth() / max
	local incomingHeal, incomingOthersHeal = self.incomingHeal, self.incomingOthersHeal
	if incomingOthersHeal > 0 then
		local newCurrent = mmin(current + incomingOthersHeal, max)
		othersHealBar:SetPoint('LEFT', healthBar, 'LEFT', current * pixelPerHP, 0)
		othersHealBar:SetWidth((newCurrent-current) * pixelPerHP)
		othersHealBar:Show()
		current = newCurrent
	else
		othersHealBar:Hide()
	end
	if incomingHeal > 0 and current < max then
		healBar:SetPoint('LEFT', healthBar, 'LEFT', current * pixelPerHP, 0)
		healBar:SetWidth(mmin(max-current, incomingHeal) * pixelPerHP)
		healBar:Show()
	else
		healBar:Hide()
	end
end

-- Update name and health bar on health change
local function UpdateHealth(self, event, unit, bar, current, max)
	self.currentHealth = current or 0
	self.maxHealth = max or 0
	return UpdateName(self)
end

-- Update name and incoming heal bar on incoming heal change
local function UpdateIncomingHeal(self, event, unit, heal, incomingHeal, incomingOthersHeal)
	self.incomingHeal = incomingHeal or 0
	self.incomingOthersHeal = incomingOthersHeal or 0
	UpdateHealBar(self)
	return UpdateName(self)
end

-- Cleaning up health on certain status changes
local function PostStatusIconUpdate(self, event, unit, state)
	if unit ~= self.unit then return end
	local r, g, b = 0.5, 0.5, 0.5
	if state == "DEAD" or state == "DISCONNECTED" then
		self.Health:SetValue(self.maxHealth)
		r, g, b = unpack(self.colors.disconnected)
	elseif state == "CHARMED" then
		r, g, b = 1, 0.3, 0
	elseif state == "INVEHICLE" then
		r, g, b = 0.2, 0.6, 0
	elseif UnitName(unit) ~= UNKNOWN then
		local refUnit = unit
		if not UnitIsPlayer(refUnit) and refUnit:match('pet') then
			refUnit = (refUnit == 'pet') and 'player' or refUnit:gsub('pet', '')
		end
		local class = select(2, UnitClass(refUnit))
		if class then
			r, g, b = unpack(self.colors.class[class])
		end
	end
	self.bgColor[1], self.bgColor[2], self.bgColor[3] = r, g, b
	self.Health.bg:SetVertexColor(r, g, b, 1)
	return UpdateName(self)
end

-- Statusbar texturing
local function PostHealthBareTextureUpdate(self)
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
			-- Sated/Exhausted
			self:AddAuraIcon(
				SpawnSmallIcon(self, "TOPLEFT", self, "TOPLEFT", INSET, -INSET),
				GetAnyAuraFilter((UnitFactionGroup("player") == "Alliance") and 29650 or 57724, "HARMFUL")
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

local function InitFrame(settings, self)
	self:EnableMouse(true)
	self:RegisterForClicks("anyup")

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0, 1)

	-- Health bar
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	self:RegisterStatusBarTexture(hp, PostHealthBareTextureUpdate)
	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth

	self.bgColor = { 1, 1, 1 }
	self.currentHealth, self.maxHealth, self.incomingHeal, self.incomingOthersHeal = 0, 0, 0, 0

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
		self.IncomingHeal = heal

		local othersHeal = hp:CreateTexture(nil, "OVERLAY")
		othersHeal:SetTexture(0.5, 0, 1, 0.5)
		othersHeal:SetBlendMode("BLEND")
		othersHeal:SetPoint("TOP")
		othersHeal:SetPoint("BOTTOM")
		othersHeal:Hide()
		self.IncomingOthersHeal = othersHeal

		self.UpdateIncomingHeal = UpdateIncomingHeal
		self.PostUpdateHealth = UpdateHealBar
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
	self.StatusIcon = status
	self.PostStatusIconUpdate = PostStatusIconUpdate

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

	--[[ Crowd control icon
	-- Now handled by the "ImportantDebuff" filter
	local header = self:GetParent()
	if oUF:HasAuraFilter("PvPDebuff") and header.isParty and not header.isPets then
		local ccicon = self:SpawnAuraIcon(self, 32)
		ccicon:SetPoint("TOP", self, "BOTTOM", 0, -SPACING)
		ccicon.doNotBlink = true
		self:AddAuraIcon(ccicon, "PvPDebuff")
	end
	--]]

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

if playerClass == 'ROGUE' or playerClass == 'WARRIOR' or playerClass == 'MAGE' or playerClass == 'WARLOCK'
	or playerClass == 'HUNTER' then
	HEIGHT = 20
end

raid_style = setmetatable(
	{
		["initial-width"] = WIDTH,
		["initial-height"] = HEIGHT,
	}, {
		__call = InitFrame,
	}
)

oUF:RegisterStyle("Adirelle_Raid", raid_style)



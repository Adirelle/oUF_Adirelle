--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local WIDTH = 80
local HEIGHT = 25
local BORDER_WIDTH = 2
local ICON_SIZE = 14
local SQUARE_SIZE = 5
local SPACING = 4

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
local lsm = LibStub('LibSharedMedia-3.0', true)

local statusbarTexture = lsm and lsm:Fetch("statusbar", false) or [[Interface\TargetingFrame\UI-StatusBar]]

local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], 
	tile = true, 
	tileSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\white16x16]],
	edgeSize = BORDER_WIDTH,
	insets = {left = BORDER_WIDTH, right = BORDER_WIDTH, top = BORDER_WIDTH, bottom = BORDER_WIDTH},
}

local squareBackdrop = {
	bgFile = [[Interface\Addons\oUF_Adirelle\white16x16]], tile = true, tileSize = 16,
}

local UnitClass = UnitClass
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitName = UnitName
local UnitAura = UnitAura
local UnitIsUnit = UnitIsUnit
local GetTime = GetTime
local strformat = string.format
local strsub = string.sub
local mmin = math.min

-- ------------------------------------------------------------------------------
-- Health bar and name updates
-- ------------------------------------------------------------------------------

local function GetShortUnitName(unit)
	return strsub(UnitName(unit),1,12)
end

local function UpdateName(self, unit, current, max)
	current = current or UnitHealth(unit)
	max = max or UnitHealthMax(max)
	local incomingHeal = self.incomingHeal or 0
	local r, g, b = 0.5, 0.5, 0.5
	if self.bgColor then
		r, g, b = unpack(self.bgColor)
	end
	local unitName = GetShortUnitName(unit)
	if isDead then
		unitName, r, g, b = "MORT", 1, 0, 0
	elseif not isDisconnected then
		if incomingHeal > 0 then
			unitName, r, g, b = strformat("+%.1fk", incomingHeal/1000), 0, 1, 0
		elseif current < max then
			local hpPercent = current/max
			if hpPercent < 0.9 then
				unitName = strformat("-%.1fk", (max-current)/1000)
				if hpPercent < 0.4 then
					r, g, b = 1, 0, 0
				end
			end
		end
	end
	self.Name:SetText(unitName)
	self.Name:SetTextColor(r, g, b, 1)	
end

local function UpdateHealth(self, event, unit, bar, current, max)
	local isDisconnected, isDead = not UnitIsConnected(unit), UnitIsDeadOrGhost(unit)
	local name = self.Name
	
	local r, g, b = 0.5, 0.5, 0.5
	local color = isDisconnected and self.colors.disconnected or self.colors.class[select(2, UnitClass(unit))]
	if color then
		r, g, b = unpack(color)
		self.bgColor = color or self.bgColor
	end
	bar.bg:SetVertexColor(r, g, b, 1)
	if isDisconnected or isDead then
		bar:SetValue(max)
	end
	UpdateName(self, unit, current, max)
end

local function PreUpdateHealth(self, unit)
	self:UpdateElement('IncomingHeal')
end

local function UpdateIncomingHeal(self, event, unit, heal, current, max, incomingHeal)
	if self.incomingHeal ~= incomingHeal then
		self.incomingHeal = incomingHeal
		UpdateName(self, unit, current, max)
	end
	if incomingHeal > 0 and current < max then
		local bar = self.Health
		local pixelPerHP = bar:GetWidth() / max
		heal:SetPoint('LEFT', bar, 'LEFT', current * pixelPerHP, 0)
		heal:SetPoint('RIGHT', bar, 'LEFT', mmin(current + incomingHeal, max) * pixelPerHP, 0)
		heal:Show()
	else
		heal:Hide()
	end
end

-- ------------------------------------------------------------------------------
-- Aura indicators
-- ------------------------------------------------------------------------------

local SpawnIcon, SpawnSquare
do
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
		local cooldown = self.Cooldown
		if start and duration then
			cooldown:SetCooldown(start, duration)
			cooldown:Show()
		else
			cooldown:Hide()
		end
	end

	local function SetStack(self, count)
		local stack = self.Stack
		if count and count > 1 then
			stack:SetText(count)
			stack:Show()
		else
			stack:Hide()
		end
	end

	local function SetBackdropBorderColor(self, r, g, b)
		local border = self.Border
		if r and g and b then
			border:SetBackdropBorderColor(r, g, b)
			border:Show()
		else
			border:Hide()
		end
	end

	function SpawnIcon(self, size, noCooldown, noStack, noBorder, noTexture)
		local	icon = CreateFrame("Frame", nil, self)
		size = size or ICON_SIZE
		icon:SetWidth(size)
		icon:SetHeight(size)

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
			cooldown:SetReverse(true)
			icon.Cooldown = cooldown
			icon.SetCooldown = SetCooldown
		else
			icon.SetCooldown = NOOP
		end

		if not noStack then
			local stack = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			stack:SetAllPoints(icon.Texture or icon)
			stack:SetJustifyH("CENTER")
			stack:SetJustifyV("MIDDLE")
			stack:SetFont(GameFontNormal:GetFont(), 10, "OUTLINE")
			stack:SetTextColor(1, 1, 1, 1)
			icon.Stack = stack
			icon.SetStack = SetStack
		else
			icon.SetStack = NOOP
		end

		if not noBorder then
			local border = CreateFrame("Frame", nil, icon)
			border:SetPoint("CENTER", icon)
			border:SetWidth(size + 2)
			border:SetHeight(size + 2)
			border:SetBackdrop(borderBackdrop)
			border:SetBackdropColor(0, 0, 0, 0)
			border:SetBackdropBorderColor(1, 1, 1, 1)
			border:Hide()
			icon.Border = border
			icon.SetColor = SetBackdropBorderColor
		else
			icon.SetColor = NOOP
		end

		icon:Hide()
		return icon
	end
	
	local function SetSquareColor(self, r, g, b)
		self:SetBackdropColor(r, g, b, 1)
	end

	function SpawnSquare(self, size)
		local	square = CreateFrame("Frame", nil, self)
		size = size or SQUARE_SIZE
		square:SetWidth(size)
		square:SetHeight(size)
		square:SetBackdrop(squareBackdrop)
		square:SetBackdropBorderColor(0,0,0,0)
		square:SetFrameLevel(self.Health:GetFrameLevel() + 5)
				
		square.SetTexture = NOOP
		square.SetCooldown = NOOP
		square.SetStack = NOOP
		square.SetColor = SetSquareColor

		square:Hide()
		return square
	end
end

-- ------------------------------------------------------------------------------
-- Aura detection
-- ------------------------------------------------------------------------------

local function IsMeOrMine(caster)
	return caster and (UnitIsUnit('player', caster) or UnitIsUnit('pet', caster) or UnitIsUnit('vehicle', caster))
end

local function TestMyAura(spellId, r, g, b)
	local spellName = GetSpellInfo(spellId)
	assert(spellName, "invalid spell id: "..spellId)
	return function(unit)
		local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName)
		if name and IsMeOrMine(caster) then
			return texture, count, expirationTime-duration, duration, r, g, b
		end
	end
end

local function TestAnyAura(spellId, filter, r, g, b)
	local spellName = GetSpellInfo(spellId)
	assert(spellName, "invalid spell id: "..spellId)
	return function(unit)
		local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName, nil, filter)
		if name then
			return texture, count, expirationTime-duration, duration, r, g, b
		end
	end
end

local function TestMyAuraCount(spellId, wanted, r, g, b)
	local spellName = GetSpellInfo(spellId)
	assert(spellName, "invalid spell id: "..spellId)
	return function(unit)
		local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName)
		if name and IsMeOrMine(caster) and count >= wanted then
			return texture, 1, expirationTime-duration, duration, r, g, b
		end
	end
end

local function GetCureableDebuff(unit)
	local name, _, texture, count, debuffType, duration, expirationTime = UnitAura(unit, 1, "HARMFUL|RAID")
	if name then
		local color = DebuffTypeColor[debuffType or "none"]
		return texture, count, expirationTime-duration, duration, color.r, color.g, color.b
	end
end

local function GetDebuffByType(wanted, r, g, b)
	assert(wanted)
	return function(unit)
		for i = 1, 40 do
			local name, _, texture, count, debuffType, duration, expirationTime = UnitAura(unit, i, "HARMFUL")
			if name and debuffType == wanted then
				return texture, count, expirationTime-duration, duration, r, g, b
			end
		end
	end
end

-- ------------------------------------------------------------------------------
-- Statusbar texturing
-- ------------------------------------------------------------------------------

local function UpdateTextures(self)
	local bar = self.Health
	bar:SetStatusBarTexture(statusbarTexture)
	bar:SetStatusBarColor(0, 0, 0, 0.75)
	bar.bg:SetTexture(statusbarTexture)
end

-- ------------------------------------------------------------------------------
-- Unit frame initialization
-- ------------------------------------------------------------------------------

local function Unit_OnEnter(...)
	if not InCombatLockdown() then
		return UnitFrame_OnEnter(...)
	end
end

local function InitFrame(settings, self, unit)
	self:EnableMouse(true)
	self:RegisterForClicks("anyup")

	self:SetScript("OnEnter", Unit_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0, 1)

	-- Health bar
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	hp.frequentUpdates = true

	local hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetAllPoints(hp)
	hpbg:SetAlpha(1)
	hp.bg = hpbg

	-- Incoming heals
	if oUF.HasIncomingHeal then
		local heal = hp:CreateTexture(nil, "OVERLAY")
		heal:SetTexture(0, 0.5, 0, 0.5)
		heal:SetBlendMode("BLEND")
		heal:SetPoint("LEFT")
		heal:SetPoint("TOP")
		heal:SetPoint("BOTTOM")
		heal:Hide()
		self.IncomingHeal = heal
		self.PreUpdateHealth = PreUpdateHealth
		self.UpdateIncomingHeal = UpdateIncomingHeal
	end

	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth

	UpdateTextures(self)

	if lsm then
		lsm.RegisterCallback(self, 'LibSharedMedia_SetGlobal', function(_, media, value)
			if media == "statusbar" then
				statusbarTexture = lsm:Fetch("statusbar", value)
				UpdateTextures(self)
			end
		end)
	end

	-- Name
	local name = hp:CreateFontString(nil, "ARTWORK", "GameFontNormal")
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

	-- ReadyCheck icon
	local rc = self:CreateTexture(nil, 'OVERLAY')
	rc:SetPoint('CENTER')
	rc:SetWidth(HEIGHT)
	rc:SetHeight(HEIGHT)
	rc:SetAlpha(1)
	self.ReadyCheck = rc

	-- Per-class aura icons
	local _, class = UnitClass("player")
	if class == "HUNTER" then
		local misdirection = SpawnIcon(self)
		misdirection:SetPoint("CENTER")
		self:AuraIcon(misdirection, TestAnyAura(34477, "HELPFUL"))

	elseif class == "DRUID" then
		--[[
		local rejuv = SpawnIcon(self, false, false, true)
		rejuv:SetPoint("CENTER", self, "LEFT", WIDTH * 0.2, 0)
		self:AuraIcon(rejuv, TestMyAura(774))

		local regrowth = SpawnIcon(self, false, false, true)
		regrowth:SetPoint("CENTER", self, "LEFT", WIDTH * 0.4, 0)
		self:AuraIcon(regrowth, TestMyAura(8936))

		local lifebloom = SpawnIcon(self, false, false, true)
		lifebloom:SetPoint("CENTER", self, "LEFT", WIDTH * 0.6, 0)
		self:AuraIcon(lifebloom, TestMyAura(33763))
		--]]
		
		local INSET = 1
		local size = 8
		local spawn = function(self, size)
			return SpawnIcon(self, size, true, true, true)
		end
		
		local rejuv = spawn(self, size)
		rejuv:SetPoint("TOPLEFT", self, "TOPLEFT", INSET, -INSET)
		self:AuraIcon(rejuv, TestMyAura(774, 6, 0, 1))

		local regrowth = spawn(self, size)
		regrowth:SetPoint("TOP", self, "TOP", 0, -INSET)
		self:AuraIcon(regrowth, TestMyAura(8936, 0, 0.6, 0))

		for i = 1, 3 do
			local lifebloom = spawn(self, size)
			lifebloom:SetPoint("TOPRIGHT", self, "TOPRIGHT", -INSET - size*(i-1), -INSET)
			self:AuraIcon(lifebloom, TestMyAuraCount(33763, i, 0, 1, 0))
		end

		local wildGrowth = spawn(self, size)
		wildGrowth:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET)
		self:AuraIcon(wildGrowth, TestMyAura(53248, 0, 1, 0))

		local abolishPoison = spawn(self, size)
		local c = DebuffTypeColor.Poison
		abolishPoison:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -INSET, INSET)
		self:AuraIcon(abolishPoison, TestMyAura(2893, c.r, c.g, c.b))

		local debuff = SpawnIcon(self)
		debuff:SetPoint("CENTER")
		self:AuraIcon(debuff, GetCureableDebuff)

	elseif class == 'PALADIN' then
		local beacon = SpawnIcon(self)
		beacon:SetPoint("CENTER", self, "LEFT", WIDTH * 0.2, 0)
		self:AuraIcon(beacon, TestMyAura(53563))

		local sacredShield = SpawnIcon(self)
		sacredShield:SetPoint("CENTER", self, "LEFT", WIDTH * 0.4, 0)
		self:AuraIcon(sacredShield, TestMyAura(53601))

		local flashLight = SpawnIcon(self)
		flashLight:SetPoint("CENTER", self, "LEFT", WIDTH * 0.6, 0)
		self:AuraIcon(flashLight, TestMyAura(48785))

		local debuff = SpawnIcon(self)
		debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.8, 0)
		self:AuraIcon(debuff, GetCureableDebuff)

	elseif class == 'SHAMAN' or class == 'MAGE' or class == 'PRIEST' then
		local debuff = SpawnIcon(self)
		debuff:SetPoint("CENTER")
		self:AuraIcon(debuff, GetCureableDebuff)
		
	elseif class == 'WARLOCK' then
		local debuff = SpawnIcon(self)
		debuff:SetPoint("CENTER")
		self:AuraIcon(debuff, GetDebuffByType("Magic"))
		
	end
	self.iconBlinkThreshold = 3

	-- Range fading
	self.Range = true
	self.inRangeAlpha = 1.0
	self.outsideRangeAlpha = 0.25
end

-- ------------------------------------------------------------------------------
-- Style and layout setup
-- ------------------------------------------------------------------------------

local style = setmetatable(
	{
		["initial-width"] = WIDTH,
		["initial-height"] = HEIGHT,
	}, {
		__call = InitFrame,
	}
)

oUF:RegisterStyle("Adirelle", style)
oUF:SetActiveStyle("Adirelle")

-- Raid groups
local raid = {}
for group = 1, 8 do
	local header = oUF:Spawn("header", "oUF_Raid" .. group)
	header:SetManyAttributes(
		"showRaid", true,
		"groupFilter", group,
		"point", "LEFT",
		"xOffset", SPACING
	)
	if group > 1 then
		header:SetPoint("BOTTOMLEFT", raid[group - 1], "TOPLEFT", 0, SPACING)
	end
	header:Show()
	raid[group] = header
end

do
	-- Party pets
	local header = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
	header:SetManyAttributes(
		"showParty", true,
		"showPlayer", true,
		"showSolo", true,
		"groupFilter", 1,
		"point", "LEFT",
		"xOffset", SPACING
	)
	header:SetPoint("BOTTOMLEFT", raid[1], "TOPLEFT", 0, SPACING)
	header:Show()
	raid['PartyPets'] = header
	
	local visibilityFrame = CreateFrame("Frame")
	visibilityFrame:SetScript('OnEvent', function()
		if InCombatLockdown() then return end
		if GetNumRaidMembers() == 0 then
			header:Show()
		else
			header:Hide()
		end
	end)
	visibilityFrame:RegisterEvent('PARTY_MEMBERS_CHANGED')
	visibilityFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
end

-- First raid group (or party)
raid[1]:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
raid[1]:SetManyAttributes(
	"showParty", true,
	"showPlayer", true,
	"showSolo", true
)


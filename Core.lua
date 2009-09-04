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
	return strsub(UnitName(unit),1,10)
end

local function UpdateName(self, unit, current, max, incomingHeal)
	local r, g, b = 0.5, 0.5, 0.5
	if self.bgColor then
		r, g, b = unpack(self.bgColor)
	end
	local unitName = GetShortUnitName(unit)
	if UnitIsDeadOrGhost(unit) then
		unitName, r, g, b = "MORT", 1, 0, 0
	elseif UnitIsConnected(unit) then
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

local function UpdateHealBar(self, current, max, incomingHeal)
	local heal = self.IncomingHeal
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
	self.currentHealth, self.maxHealth = current, max
	UpdateName(self, unit, current, max, self.incomingHeal)
end

local function UpdateIncomingHeal(self, event, unit, heal, incomingHeal)
	local current, max = self.currentHealth, self.maxHealth
	self.incomingHeal = incomingHeal
	UpdateName(self, unit, current, max, incomingHeal)
	UpdateHealBar(self, current, max, incomingHeal)
end

local function PostUpdateHealth(self, event, unit, bar, current, max)
	UpdateHealBar(self, current, max, self.incomingHeal)
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

local GetImportantBuff
do
	local commonBuffs = {
		[19752] = 99, -- Divine Intervention	
		[ 1022] = 70, -- Hand of Protection
		[33206] = 50, -- Pain Suppression
		[47788] = 50, -- Guardian Spirit
		[29166] = 20, -- Innervate
	}
	
	local tmp = {}
	local function compare(a, b)
		return tmp[a] > tmp[b]
	end
	local function BuildClassBuffs(classBuffs)
		wipe(tmp)
		local buffs = {}
		for _, t in pairs({classBuffs, commonBuffs}) do
			for id, prio in pairs(t) do
				local name = assert(GetSpellInfo(id), "invalid spell id: "..id)
				tmp[name] = prio
				tinsert(buffs, name)
			end
		end
		table.sort(buffs, compare)
		return buffs
	end

	local importantBuffs = {
		HUNTER = BuildClassBuffs{
			[19263] = 40, -- Deterrence
			[ 5384] = 10, -- Feign Death
		},
		MAGE = BuildClassBuffs{
			[45438] = 80, -- Ice Block
		},
		DRUID = BuildClassBuffs{
			[61336] = 60, -- Survival Instincts
			[22812] = 50, -- Barkskin
			[22842] = 30, -- Frenzied Regeneration	
		},
		PALADIN = BuildClassBuffs{
			[64205] = 90, -- Divine Sacrifice
			[  642] = 80, -- Divine Shield
			[  498] = 50, -- Divine Protection
		},
		WARRIOR = BuildClassBuffs{
			[12975] = 60, -- Last Stand
			[  871] = 50, -- Shield Wall
			[55694] = 30, -- Enraged Regeneration
			[ 2565] = 20, -- Shield Block
		},
		DEATHKNIGHT = BuildClassBuffs{
			[48792] = 50, -- Icebound Fortitude
			[51271] = 50, -- Unbreakable Armor
			[48707] = 40, -- Anti-Magic Shell
			-- [49222] = 20, -- Bone Shield
		},
		ROGUE = BuildClassBuffs{
			[31224] = 60, -- Cloak of Shadows
		},
		WARLOCK = BuildClassBuffs{
			[47986] = 40, -- Sacrifice
		},		
		PRIEST = BuildClassBuffs{
			[20711] = 99, -- Spirit of Redemption
		},
		SHAMAN = BuildClassBuffs{},		
	}

	function GetImportantBuff(unit)
		if not UnitIsPlayer(unit) then return end
		local buffs = importantBuffs[select(2, UnitClass(unit))]
		if not buffs then return print('no important buff for', UnitName(unit)) end
		for i, spellName in ipairs(buffs) do
			local name, _, texture, count, _, duration, expirationTime = UnitAura(unit, spellName, nil, "HELPFUL")
			if name then
				return texture, count, expirationTime-duration, duration
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
		self.UpdateIncomingHeal = UpdateIncomingHeal
		self.PostUpdateHealth = PostUpdateHealth
	end

	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth
	self.incomingHeal = 0

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
	local importantBuff = SpawnIcon(self)
	importantBuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.4, 0)
	self:AuraIcon(importantBuff, GetImportantBuff)
	
	local debuff = SpawnIcon(self)
	debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.6, 0)
	self:AuraIcon(debuff, GetCureableDebuff)
	
	local _, class = UnitClass("player")
	if class == "HUNTER" then
		local misdirection = SpawnIcon(self)
		misdirection:SetPoint("CENTER", self, "LEFT", WIDTH * 0.25, 0)
		self:AuraIcon(misdirection, TestAnyAura(34477, "HELPFUL"))

		importantBuff:SetPoint("CENTER")
		debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.75, 0)
		
	elseif class == "DRUID" then
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
		
	elseif class == 'PALADIN' then
		local beacon = SpawnIcon(self)
		beacon:SetPoint("CENTER", self, "LEFT", WIDTH * 0.2, 0)
		self:AuraIcon(beacon, TestMyAura(53563))

		local sacredShield = SpawnIcon(self)
		sacredShield:SetPoint("CENTER", self, "LEFT", WIDTH * 0.4, 0)
		self:AuraIcon(sacredShield, TestMyAura(53601))

		importantBuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.6, 0)
		debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.8, 0)

	elseif class == 'WARLOCK' then
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
end

local function UpdateLayout()
	if InCombatLockdown() then return end
	if GetNumRaidMembers() == 0 then
		raid.PartyPets:Show()
	else
		raid.PartyPets:Hide()
	end
	local width = 0
	for _, frame in pairs(raid) do
		if frame:IsShown() then
			width = math.max(width, math.floor(frame:GetWidth()))
		end
	end
	raid[1]:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -width/2, 230)
end

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript('OnEvent', UpdateLayout)
updateFrame:RegisterEvent('PARTY_MEMBERS_CHANGED')
updateFrame:RegisterEvent('PLAYER_REGEN_ENABLED')

raid[1]:SetManyAttributes(
	"showParty", true,
	"showPlayer", true,
	"showSolo", true
)
UpdateLayout()


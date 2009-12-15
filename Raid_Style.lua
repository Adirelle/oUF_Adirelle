--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

oUF.colors.power.MANA = { 0.3, 0.5, 1.0 }

local LibStub = LibStub
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
local tostring = tostring
local unpack = unpack

SCALE = 1.0
WIDTH = 80
SPACING = 2
HEIGHT = 25
BORDER_WIDTH = 1
ICON_SIZE = 14
SQUARE_SIZE = 5

local _, playerClass = UnitClass("player")

backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	tile = true,
	tileSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]],
	edgeSize = BORDER_WIDTH,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local squareBackdrop = {
	bgFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]], tile = true, tileSize = 16,
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
local mmax = math.max
local abs = math.abs

-- ------------------------------------------------------------------------------
-- Health bar and name updates
-- ------------------------------------------------------------------------------

local function GetShortUnitName(unit)
	return strsub(tostring(UnitName(unit)),1,10)
end

local function SmartHPValue(value)
	if abs(value) >= 1000 then
		return strformat("%.1fk", value/1000)
	else
		return strformat("%d", value)
	end
end

local function UpdateName(self, unit, current, max, incomingHeal)
	local r, g, b = unpack(self.bgColor)
	local unitName = GetShortUnitName(SecureButton_GetUnit(self))
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
		local overHeal = current + incomingHeal - max
		if overHeal > 0 then
			unitName, r, g, b = "+"..SmartHPValue(overHeal), 0, 1, 0
		elseif current < 0.4 * max then
			unitName, r, g, b = SmartHPValue(current), 1, 0, 0
		end
	end
	self.Name:SetText(unitName)
	self.Name:SetTextColor(r, g, b, 1)
end

local function UpdateHealBar(self, event, current, max, incomingHeal, incomingOthersHeal)
	local healBar, othersHealBar = self.IncomingHeal, self.IncomingOthersHeal
	if max == 0 or current >= max then
		healBar:Hide()
		othersHealBar:Hide()
		return
	end
	local healthBar = self.Health
	local pixelPerHP = healthBar:GetWidth() / max
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

local function UpdateHealth(self, event, unit, bar, current, max)
	local isDisconnected, isDead = not UnitIsConnected(unit), UnitIsDeadOrGhost(unit)
	local r, g, b = 0.5, 0.5, 0.5
	if isDisconnected or isDead then
		bar:SetValue(max)
		r, g, b = unpack(self.colors.disconnected)
	elseif UnitHasVehicleUI(SecureButton_GetUnit(self)) then
		r, g, b = 0.2, 0.6, 0
	elseif UnitName(unit) ~= UNKNOWN then
		local classUnit = unit
		if not UnitIsPlayer(classUnit) then
			classUnit = (classUnit == 'pet') and 'player' or classUnit:gsub('pet', '')
		end
		local unitClass = select(2, UnitClass(classUnit))
		if unitClass then
			r, g, b = unpack(self.colors.class[unitClass])
		end
	end
	self.bgColor[1], self.bgColor[2], self.bgColor[3] = r, g, b
	bar.bg:SetVertexColor(r, g, b, 1)
	--[[if isDead then
		self.DeathIcon:Show()
	else
		self.DeathIcon:Hide()
	end]]
	self.currentHealth, self.maxHealth = current, max
	UpdateName(self, unit, current, max, (self.incomingHeal or 0) + (self.incomingOthersHeal or 0))
end

local function UpdateIncomingHeal(self, event, unit, heal, incomingHeal, incomingOthersHeal)
	local current, max = self.currentHealth or 0, self.maxHealth or 0
	self.incomingHeal = incomingHeal
	self.incomingOthersHeal = incomingOthersHeal
	UpdateName(self, unit, current, max, incomingHeal + incomingOthersHeal)
	UpdateHealBar(self, event, current, max, incomingHeal, incomingOthersHeal)
end

local function PostUpdateHealth(self, event, unit, bar, current, max)
	UpdateHealBar(self, event, current, max, self.incomingHeal or 0, self.incomingOthersHeal or 0)
end

local function UnitFlagChanged(self, event, unit)
	if unit and unit ~= self.unit then return end
	UpdateHealth(self, event, unit, self.Health, self.currentHealth, self.maxHealth)
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
			cooldown:SetDrawEdge(true)
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
		if not buffs then return end
		for i, spellName in ipairs(buffs) do
			local name, _, texture, count, _, duration, expirationTime = UnitAura(unit, spellName, nil, "HELPFUL")
			if name then
				return texture, count, expirationTime-duration, duration
			end
		end
	end
end

local drdata, drdata_minor = LibStub('DRData-1.0', true)
local GetCCIcon
if drdata then
	--print('DRData-1.0 version', drdata_minor, 'support enabled')

	local IGNORED = -1
	local SPELL_CATEGORIES = {}
	local DEFAULT_PRIORITIES = {
		["banish"] = 100,
		["cyclone"] = 100,
		["mc"] = 100,
		["ctrlstun"] = 90,
		["rndstun"] = 90,
		["cheapshot"] = 90,
		["charge"] = 90,
		["fear"] = 80,
		["horror"] = 80,
		["sleep"] = 60,
		["disorient"] = 60,
		["scatters"] = 60,
		["silence"] = 50,
		["disarm"] = 50,
		["ctrlroot"] = 40,
		["rndroot"] = 40,
		["entrapment"] = 40,
	}
	local CLASS_PRIORITIES = {
		HUNTER = {
			silence = IGNORED,
		},
		WARRIOR = {
			silence = IGNORED,
		},
		ROGUE = {
			silence = IGNORED,
		},
		DRUID = {
			disarm = IGNORED,
		},
		PRIEST = {
			disarm = IGNORED,
		},
		WARLOCK = {
			disarm = IGNORED,
		},
		MAGE = {
			disarm = IGNORED,
		},
	}
	for id, cat in pairs(drdata:GetSpells()) do
		local name = GetSpellInfo(id)
		if name and DEFAULT_PRIORITIES[cat] then
			SPELL_CATEGORIES[name] = cat
		end
	end
	do
		local meta = { __index = DEFAULT_PRIORITIES }
		for name, t in pairs(CLASS_PRIORITIES) do
			CLASS_PRIORITIES[name] = setmetatable(t, meta)
		end
	end

	function GetCCIcon(unit)
		if not UnitIsPVP(unit) or GetNumRaidMembers() > 5 then return end
		local _, className = UnitClass(unit)
		local classPriorities = CLASS_PRIORITIES[className] or DEFAULT_PRIORITIES
		local curPrio, curTexture, curCount, curExpTime, curDuration, curDebuffType = IGNORED
		for index = 1, 256 do
			local name, _, icon, count, debuffType, duration, expirationTime = UnitDebuff(unit, index)
			if not name then break end
			local priority = classPriorities[SPELL_CATEGORIES[name] or false]
			if priority and priority > curPrio then
				curPrio, curTexture, curCount, curExpTime, curDuration, curDebuffType = priority, icon, count, expirationTime, duration, debuffType
			end
		end
		if curTexture then
			local color = DebuffTypeColor[curDebuffType or "none"]
			return curTexture, curCount, curExpTime-curDuration, curDuration, color.r, color.g, color.b
		end
	end
end

-- ------------------------------------------------------------------------------
-- Statusbar texturing
-- ------------------------------------------------------------------------------

local function PostHealthBareTextureUpdate(self)
	self:SetStatusBarColor(0, 0, 0, 0.75)
end

-- ------------------------------------------------------------------------------
-- Unit frame initialization
-- ------------------------------------------------------------------------------

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

local function InitFrame(settings, self)
	self:EnableMouse(true)
	self:RegisterForClicks("anyup")

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0, 1)

	self.SpawnIcon = SpawnIcon
	self.SpawnSquare = SpawnSquare

	self.bgColor = { 1, 1, 1 }


	-- Health bar
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	hp.frequentUpdates = true
	self:RegisterStatusBarTexture(hp, PostHealthBareTextureUpdate)

	local hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetAllPoints(hp)
	hpbg:SetAlpha(1)
	self:RegisterStatusBarTexture(hpbg)
	hp.bg = hpbg

	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetAllPoints(self)
	overlay:SetFrameLevel(hp:GetFrameLevel()+2)
	self.Overlay = overlay

	-- Death icon
	--[=[
	local death = overlay:CreateTexture(nil, "OVERLAY")
	death:SetWidth(HEIGHT*2)
	death:SetHeight(HEIGHT)
	death:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Skull]])
	death:SetTexCoord(0, 1, 0.30, 0.80)
	death:SetAlpha(0.5)
	death:SetPoint("CENTER")
	death:Hide()
	self.DeathIcon = death
	--]=]
	
	local status = overlay:CreateTexture(nil, "OVERLAY")
	status:SetWidth(HEIGHT)
	status:SetHeight(HEIGHT)
	status:SetAlpha(0.75)
	status:SetPoint("CENTER")
	status:SetBlendMode("ADD")
	status:Hide()
	self.StatusIcon = status
	
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
		self.PostUpdateHealth = PostUpdateHealth
	end

	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth
	self.incomingHeal = 0

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

	-- Per-class aura icons
	local importantBuff = SpawnIcon(overlay)
	importantBuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.4, 0)
	self:AuraIcon(importantBuff, GetImportantBuff)

	local debuff = SpawnIcon(overlay)
	debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.6, 0)
	self:AuraIcon(debuff, GetCureableDebuff)

	local INSET, SMALL_ICON_SIZE = 1, 8
	local function SpawnSmallIcon(...)
		local icon = SpawnIcon(overlay, SMALL_ICON_SIZE, true, true, true)
		icon:SetPoint(...)
		return icon
	end

	if playerClass == "HUNTER" then
		local misdirection = SpawnIcon(overlay)
		misdirection:SetPoint("CENTER", self, "LEFT", WIDTH * 0.25, 0)
		self:AuraIcon(misdirection, TestAnyAura(34477, "HELPFUL"))

		importantBuff:SetPoint("CENTER")
		debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.75, 0)

	elseif playerClass == "DRUID" then

		-- Rejuvenation
		self:AuraIcon(
			SpawnSmallIcon("TOPLEFT", self, "TOPLEFT", INSET, -INSET),
			TestMyAura(774, 6, 0, 1)
		)

		-- Regrowth
		self:AuraIcon(
			SpawnSmallIcon("TOP", self, "TOP", 0, -INSET),
			TestMyAura(8936, 0, 0.6, 0)
		)

		-- Lifebloom
		for i = 1, 3 do
			self:AuraIcon(
				SpawnSmallIcon("TOPRIGHT", self, "TOPRIGHT", -INSET - SMALL_ICON_SIZE*(i-1), -INSET),
				TestMyAuraCount(33763, i, 0, 1, 0)
			)
		end

		-- Wild Growth
		self:AuraIcon(
			SpawnSmallIcon("BOTTOMLEFT", self, "BOTTOMLEFT", INSET, INSET),
			TestMyAura(53248, 0, 1, 0)
		)

		-- Abolish Poison
		self:AuraIcon(
			SpawnSmallIcon("BOTTOMRIGHT", self, "BOTTOMRIGHT", -INSET, INSET),
			TestMyAura(2893)
		)

	elseif playerClass == 'PALADIN' then
	
		-- Beacon of light
		self:AuraIcon(
			SpawnSmallIcon("TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
			TestMyAura(53563)
		)

		-- Sacred Shield
		self:AuraIcon(
			SpawnSmallIcon("TOPLEFT", self, "TOPLEFT", INSET, -INSET),
			TestMyAura(53601)
		)

	elseif playerClass == "SHAMAN" then
		local earthShield = SpawnIcon(overlay)
		earthShield:SetPoint("CENTER", self, "LEFT", WIDTH * 0.25, 0)
		self:AuraIcon(earthShield, TestMyAura(49284))

		importantBuff:SetPoint("CENTER")
		debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.75, 0)

		-- Riptide
		self:AuraIcon(
			SpawnSmallIcon("TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
			TestMyAura(61301)
		)

		-- Sated/Exhausted
		self:AuraIcon(
			SpawnSmallIcon("TOPLEFT", self, "TOPLEFT", INSET, -INSET),
			TestAnyAura((UnitFactionGroup("player") == "Alliance") and 29650 or 57724, "HARMFUL")
		)

	elseif playerClass == 'WARLOCK' then
		self:AuraIcon(debuff, GetDebuffByType("Magic"))

	elseif playerClass == 'PRIEST' then
		-- PW:Shield or Weakened Soul
		local PWSHIELD, WEAKENEDSOUL = GetSpellInfo(17), GetSpellInfo(6788)
		self:AuraIcon(
			SpawnSmallIcon("TOPLEFT", self, "TOPLEFT", INSET, -INSET),
			function(unit)
				local texture, _, _, duration, expirationTime = select(3, UnitBuff(unit, PWSHIELD))
				if not texture then
					duration, expirationTime = select(6, UnitDebuff(unit, WEAKENEDSOUL))
					if duration then
						-- Display a red X in place of the weakened soul icon
						texture = [[Interface\RaidFrame\ReadyCheck-NotReady]]
					end
				end
				if texture then
					return texture, 1, expirationTime-duration, duration
				end
			end
		)

		-- Renew
		self:AuraIcon(
			SpawnSmallIcon("TOPRIGHT", self, "TOPRIGHT", -INSET, -INSET),
			TestMyAura(139)
		)

		-- Prayer of Mending
		self:AuraIcon(
			SpawnSmallIcon("BOTTOMRIGHT", self, "BOTTOMRIGHT", -INSET, INSET),
			TestMyAura(48113)
		)

	end

	--[[ Targetting thing
	local tc = SpawnSquare(self, 5)
	tc:SetPoint("LEFT", self ,"LEFT", 1, 0)
	self.TargetColor = tc
	--]]
	
	-- 

	-- Crowd control icon
	local header = self:GetParent()
	if GetCCIcon and header.isParty and not header.isPets then
		local ccicon = SpawnIcon(self, 32)
		ccicon:SetPoint("TOP", self, "BOTTOM", 0, -SPACING)
		ccicon.doNotBlink = true
		self:AuraIcon(ccicon, GetCCIcon)
	end
	
	-- Aura icon blinking setting
	self.iconBlinkThreshold = 3

	-- RaidIcon
	local raidIcon = overlay:CreateTexture(nil, "OVERLAY")
	raidIcon = overlay:CreateTexture(nil, "OVERLAY")
	raidIcon:SetWidth(8)
	raidIcon:SetHeight(8)
	raidIcon:SetPoint("LEFT", self, INSET, 0)
	self.RaidIcon = raidIcon
	
	-- Event requiring to update name and color
	self:RegisterEvent('UNIT_FLAGS', UnitFlagChanged)
	self:RegisterEvent('UNIT_ENTERED_VEHICLE', UnitFlagChanged)
	self:RegisterEvent('UNIT_EXITED_VEHICLE', UnitFlagChanged)

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




--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

if oUF_Adirelle.SingleStyle then return end

--<GLOBALS
local _G = _G
local CreateFrame = _G.CreateFrame
local floor = _G.floor
local GameFontNormal = _G.GameFontNormal
local gsub = _G.gsub
local huge = _G.math.huge
local InCombatLockdown = _G.InCombatLockdown
local ipairs = _G.ipairs
local pairs = _G.pairs
local select = _G.select
local setmetatable = _G.setmetatable
local tsort = _G.table.sort
local strmatch = _G.strmatch
local tinsert = _G.tinsert
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitAlternatePowerInfo = _G.UnitAlternatePowerInfo
local UnitAlternatePowerTextureInfo = _G.UnitAlternatePowerTextureInfo
local UnitAura = _G.UnitAura
local UnitCanAssist = _G.UnitCanAssist
local UnitCanAttack = _G.UnitCanAttack
local UnitClass = _G.UnitClass
local UnitFrame_OnEnter = _G.UnitFrame_OnEnter
local UnitFrame_OnLeave = _G.UnitFrame_OnLeave
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local unpack = _G.unpack
--GLOBALS>
local mmin, mmax = _G.min, _G.max

local GAP, BORDER_WIDTH, TEXT_MARGIN = private.GAP, private.BORDER_WIDTH, private.TEXT_MARGIN
local FRAME_MARGIN, AURA_SIZE = private.FRAME_MARGIN, private.AURA_SIZE

local backdrop, glowBorderBackdrop = oUF_Adirelle.backdrop, oUF_Adirelle.glowBorderBackdrop

local borderBackdrop = { edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]], edgeSize = BORDER_WIDTH }

local SpawnTexture, SpawnText, SpawnStatusBar = private.SpawnTexture, private.SpawnText, private.SpawnStatusBar
local CreateName = private.CreateName

local function Auras_PreSetPosition(icons, numIcons)
	return 1, numIcons
end

local function Auras_PostCreateIcon(icons, button)
	local cd, count, overlay = button.cd, button.count, button.overlay
	button.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	overlay:SetTexture([[Interface\AddOns\oUF_Adirelle\media\icon_border]])
	overlay:SetTexCoord(0, 1, 0, 1)
	cd.noCooldownCount = true
	cd:SetReverse(true)
	button.expires, button.priority, button.bigger = 0, 0, false
end

local function Auras_PostUpdateIcon(icons, unit, icon, index, offset)
	if not select(5, UnitAura(unit, index, icon.filter)) then
		icon.overlay:Hide()
	end
end

local LibDispellable = oUF_Adirelle.GetLib("LibDispellable-1.0")

local function IsMine(unit)
	return unit == "player" or unit == "vehicle" or unit == "pet"
end

local function IsAlly(unit)
	return unit and UnitCanAssist(unit, "player") and not IsMine(unit)
end

local IsEncounterDebuff = oUF_Adirelle.IsEncounterDebuff

local canSteal = select(2, UnitClass("player")) == "MAGE"

local function Buffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura)
	icon.expires = (expires ~= 0) and expires or huge
	local priority, bigger = 2, false
	if IsEncounterDebuff(spellID) then
		priority, bigger = 6, true
	else
		local inCombat, filter = InCombatLockdown(), oUF_Adirelle.layoutDB.profile.Single.Auras.buffFilter
		if inCombat and (
			(filter.consolidated and shouldConsolidate) or
			(filter.permanent and duration == 0) or
			(filter.allies and IsAlly(caster))
		) then
			return false
		elseif UnitCanAttack("player", unit) then
			if (canSteal and isStealable) or LibDispellable:CanDispel(unit, true, dtype, spellID) then
				priority, bigger = 5, true
			elseif inCombat and filter.undispellable then
				return false
			end
		elseif UnitCanAssist("player", unit) then
			bigger = IsMine(caster)
			priority = bigger and 5 or canApplyAura and 4 or shouldConsolidate and 1 or 3
		end
		if duration == 0 then
			priority = priority - 1
		end
	end
	icon.priority, icon.bigger = priority, bigger
	return true
end

local function Debuffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, expires, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
	icon.expires = (expires ~= 0) and expires or huge
	local priority = 0
	if isBossDebuff or IsEncounterDebuff(spellID) then
		priority = 5
	else
		local inCombat, filter = InCombatLockdown(), oUF_Adirelle.layoutDB.profile.Single.Auras.buffFilter
		if inCombat and (
			(filter.permanent and duration == 0) or 
			(filter.allies and IsAlly(caster)) or
			(filter.unknown and not canApplyAura)
		) then
			return false
		elseif UnitCanAttack("player", unit) then
			priority = IsMine(caster) and 3 or canApplyAura and 2 or 1
		elseif UnitCanAssist("player", unit) then
			if LibDispellable:CanDispel(unit, false, dtype, spellID) then
				priority = 3
			elseif inCombat and filter.undispellable then
				return false
			end
		end
	end
	icon.priority, icon.bigger = priority, priority >= 3
	return true
end

local Auras_SetPosition
do
	local function CompareIcons(a, b)
		if a.bigger and not b.bigger then
			return true
		elseif not a.bigger and b.bigger then
			return false
		elseif a.priority == b.priority then
			if a.expires == b.expires then
				return a:GetID() < b:GetID()
			else
				return a.expires < b.expires
			end
		else
			return a.priority > b.priority
		end
	end

	local tmp = {}
	function Auras_SetPosition(icons)
		if not icons then return end
		local num = #icons
		if num == 0 then return end
		local spacing = icons.spacing or 1
		local width, height = icons:GetSize()
		local size = icons.size
		local anchor = icons.initialAnchor or "BOTTOMLEFT"
		local growthx = icons.growthx or 1
		local growthy = icons.growthy or 1

		-- Sort auras
		for i = 1, mmax(num, #tmp) do
			tmp[i] = icons[i]
		end
		tsort(tmp, CompareIcons)

		local shown = 0
		local visible = icons.maxNum
		oUF.Debug('Auras_SetPosition', num, 'icons', visible, 'visible', 'maxNum=', icons.maxNum)

		-- Icon sizes
		local enlarge = icons.enlarge
		local bigSize = enlarge and mmax(8, mmin(size * 3 / 2, width, height)) or 0
		size = mmax(8, mmin(size, width, height))

		local i = 1
		local x, y = 0, 0

		-- Layout large icons
		if enlarge then
			local step = bigSize + spacing
			while i <= num and shown < visible and tmp[i].bigger do
				local button = tmp[i]
				if button:IsShown() then
					button:SetSize(bigSize, bigSize)
					button:ClearAllPoints()
					button:SetPoint(anchor, icons, anchor, growthx * x, 0)
					x = x + step
					shown = shown + 1
				end
				i = i + 1
			end
		end

		-- Layout normal-sized icons
		local baseX, step = x, size + spacing
		local maxx, maxy = mmax(1, width - size), mmax(1, height - size)
		while i <= num and shown < visible do
			local button = tmp[i]
			if button:IsShown() then
				while x > maxx do
					y = y + step
					x = (y >= bigSize) and 0 or baseX
				end
				button:SetSize(size, size)
				button:ClearAllPoints()
				button:SetPoint(anchor, icons, anchor, growthx * x, growthy * y)
				shown = shown + 1
				x = x + step
			end
			i = i + 1
		end

		-- Hide remaining icons
		while i <= num do
			tmp[i]:Hide()
			i = i + 1
		end
	end
end

local function Auras_ForceUpdate(self, event, unit)
	if unit and unit ~= self.unit then return end
	if self.Buffs then
		self.Buffs:ForceUpdate()
	end
	if self.Debuffs then
		self.Debuffs:ForceUpdate()
	end
end

local function Power_PostUpdate(power, unit, min, max)
	if power.disconnected or UnitIsDeadOrGhost(unit) then
		power:SetValue(0)
	end
end

local function AltPowerBar_PostUpdate(bar, min, cur, max)
	local unit = bar.__owner.unit
	if not unit then return end
	bar.Label:SetText(select(10, UnitAlternatePowerInfo(unit)))
	local _, powerRed, powerGreen, powerBlue = UnitAlternatePowerTextureInfo(unit, 2)
	if powerRed and powerGreen and powerBlue then
		local r, g, b = oUF.ColorGradient(cur-min, max-min, powerRed, powerGreen, powerBlue, 1, 0, 0)
		bar:SetStatusBarColor(r, g, b)
	else
		bar:SetStatusBarColor(0.75, 0.75, 0.75)
	end
end

local function HighlightBurningEmbers(bar, unit, current, max)
	if not current then return end
	local lr, lg, lb, hr, hg, hb = unpack(oUF.colors.power.BURNING_EMBERS)
	for i = 1, bar.numItems do
		local r, g, b
		if current >= 10 then
			r, g, b = hr, hg, hb
		else
			r, g, b = lr, lg, lb
		end
		bar[i]:SetStatusBarColor(r, g, b)
		current = current - 10
	end
end

local function HighlightHolyPower(bar, unit, current, max)
	local state = current >= 3 and 3 or 2
	local r, g, b = unpack(oUF.colors.power.HOLY_POWER)
	bar:SetStatusBarColor(oUF.ColorGradient(state, 3, 0, 0, 0, r, g, b))
end

-- Additional auxiliary bars
local function LayoutAuxiliaryBars(self)
	local bars = self.AuxiliaryBars
	if not bars then return end
	local anchor, offset = self, 0
	if self.Buffs and self.Buffs.side == "BOTTOM" then
		offset = - self.Buffs:GetHeight()
	end
	for i, bar in ipairs(bars) do
		if bar:IsShown() then
			bar:SetPoint("TOP", anchor, "BOTTOM", 0, -FRAME_MARGIN+offset)
			anchor, offset = bar, 0
		end
	end
end

local function LayoutAuxiliaryBars_Hook(bar)
	 return LayoutAuxiliaryBars(bar.__mainFrame)
end

local function AddAuxiliaryBar(self, bar)
	if not self.AuxiliaryBars then
		self.AuxiliaryBars = {}
	end
	tinsert(self.AuxiliaryBars, bar)
	bar.__mainFrame = self
	bar:HookScript('OnShow', LayoutAuxiliaryBars_Hook)
	bar:HookScript('OnHide', LayoutAuxiliaryBars_Hook)
end

-- General bar layout
local function LayoutBars(self)
	local width, height = self:GetSize()
	if not width or not height or width == 0 or height == 0 then return end
	self.Border:SetSize(width + 2 * BORDER_WIDTH, height + 2 * BORDER_WIDTH)
	if self.Portrait then
		self.Portrait:SetSize(height, height)
	end
	self.WarningIcon:SetSize(height, height)
	if self.AuxiliaryBars then
		LayoutAuxiliaryBars(self)
	end
end

local function CastBar_Update(castbar)
	local height = castbar:GetHeight()
	if height then
		castbar.Icon:SetSize(height, height)
	end
end

local function XRange_PostUpdate(xrange, event, unit, inRange)
	xrange.__owner:SetAlpha(inRange and 1 or oUF.colors.outOfRange[4])
end

local function ApplyAuraPosition(self, target, initialAnchor, anchorTo, growthx, growthy, dx, dy)
	self:Debug('ApplyAuraPosition', target, initialAnchor, anchorTo, growthx, growthy, dx, dy)
	target.initialAnchor = initialAnchor
	target.growthx = growthx
	target.growthy = growthy
	target:ClearAllPoints()
	target:SetPoint(initialAnchor, self, anchorTo, dx * FRAME_MARGIN, dy * FRAME_MARGIN)
end

local function OnAuraLayoutModified(self, event, layout)
	local width, height = self:GetSize()
	local buffs, debuffs = self.Buffs, self.Debuffs

	local auras = layout.Single.Auras
	local size, spacing, side = auras.size, auras.spacing, auras.sides[self.baseUnit]
	buffs.size, buffs.spacing, buffs.enlarge, buffs.side = size, spacing, auras.enlarge, side
	if debuffs then
		debuffs.size, debuffs.spacing, debuffs.enlarge, debuffs.side = size, spacing, auras.enlarge, side
	end

	-- Apply position
	if side == 'LEFT' or side == 'RIGHT' then
		-- Left or right
		local dx, opposite
		if side == 'LEFT' then
			dx, opposite = -1, 'RIGHT'
		else
			dx, opposite = 1, 'LEFT'
		end
		ApplyAuraPosition(self, buffs, 'BOTTOM'..opposite, 'BOTTOM'..side, dx, -1, dx, 0)

		-- Ensure we can display at least maxNum large icons
		local maxNum = max(auras.numBuffs, auras.enlarge and auras.numDebuffs or 0)
		local auraWidth = (size * (auras.enlarge and 1.5 or 1)) * maxNum + spacing * (maxNum - 1)

		-- Share the available space
		if auras.numBuffs > 0 then
			if debuffs and auras.numDebuffs > 0 then
				ApplyAuraPosition(self, debuffs, 'TOP'..opposite, 'TOP'..side, dx, 1, dx, 0)
				buffs:SetSize(auraWidth, height / 2)
				debuffs:SetSize(auraWidth, height / 2)
			else
				buffs:SetSize(auraWidth, height)
			end
		elseif debuffs and auras.numDebuffs > 0 then
			ApplyAuraPosition(self, debuffs, 'TOP'..opposite, 'TOP'..side, dx, 1, dx, 0)
			debuffs:SetSize(auraWidth, height)
		end
	else
		-- Top or bottom
		local dy, opposite
		if side == 'TOP' then
			dy, opposite = 1, 'BOTTOM'
		else
			dy, opposite = -1, 'TOP'
		end

		-- Ensure we can display at least two rows of normal icons, or a row of large ones plus a row of normal ones
		local auraHeight = size * 2 + spacing
		if auras.enlarge then
			auraHeight = mmax(auraHeight, mmin(size * 1.5, width) + spacing + size)
		end

		if auras.numBuffs > 0 then
			ApplyAuraPosition(self, buffs, opposite..'LEFT', side..'LEFT', 1, dy, 0, dy)
			if debuffs and auras.numDebuffs > 0 then
				ApplyAuraPosition(self, debuffs, opposite..'RIGHT', side..'RIGHT', -1, dy, 0, dy)
				buffs:SetSize(width / 2, auraHeight)
				debuffs:SetSize(width / 2, auraHeight)
			else
				buffs:SetSize(width, auraHeight)
			end
		elseif debuffs and auras.numDebuffs > 0 then
			ApplyAuraPosition(self, debuffs, opposite..'RIGHT', side..'RIGHT', -1, dy, 0, dy)
			debuffs:SetSize(width, auraHeight)
		end
	end

	-- Update the number of icons and update them
	buffs.maxNum = auras.numBuffs
	buffs:ForceUpdate()
	if debuffs then
		debuffs.maxNum = auras.numDebuffs
		debuffs:ForceUpdate()
	end

	-- Update auxiliary bars, just in case
	return LayoutAuxiliaryBars(self)
end

local function OnSingleLayoutModified(self, event, layout, theme)
	local width, height = layout.Single.width, layout.Single['height'..self.heightType]
	if self.heightFactor then
		height = height * self.heightFactor
	end
	if self:CanChangeProtectedState() and (self:GetWidth() ~= width or self:GetHeight() ~= height) then
		self:SetSize(width, height)
	end
end

local function OnSingleThemeModified(self, event, layout, theme)
	-- Update health coloring flags
	local health = self.Health
	for k,v in pairs(theme.Health) do
		health[k] = v
	end
	if self.baseUnit == "arena" then
		health.colorSmooth = false
	end
	health:ForceUpdate()

	-- Update power coloring flags
	local power = self.Power
	if power then
		for k,v in pairs(theme.Power) do
			power[k] = v
		end
		power:ForceUpdate()
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

local function OnColorModified(self, event, layout, theme)
	self.LowHealth:SetTexture(unpack(oUF.colors.lowHealth, 1, 4))
	if self.XRange then
		self.XRange:SetTexture(unpack(oUF.colors.outOfRange, 1, 3))
		self.XRange:ForceUpdate()
	end
	self.Health:ForceUpdate()
	if self.Power then
		self.Power:ForceUpdate()
	end
end

local DRAGON_TEXTURES = {
	rare  = { [[Interface\Addons\oUF_Adirelle\media\rare_graphic]],  6/128, 123/128, 17/128, 112/128, },
	elite = { [[Interface\Addons\oUF_Adirelle\media\elite_graphic]], 6/128, 123/128, 17/128, 112/128, },
}

local function InitFrame(settings, self, unit)
	local unit = gsub(unit or self.unit, "%d+", "")
	local isArenaUnit = strmatch(unit, "arena")
	self.baseUnit, self.isArenaUnit = unit, isArenaUnit
	self.heightType = settings.heightType

	self:SetSize(settings['initial-width'], settings['initial-height'])
	if unit == "pet" then
		self.heightFactor = 40/47
	end

	self:RegisterForClicks("AnyDown")

	self:SetScript("OnEnter", oUF_Adirelle.Unit_OnEnter)
	self:SetScript("OnLeave", oUF_Adirelle.Unit_OnLeave)

	if self:CanChangeAttribute() then
		self:SetAttribute("type", "target")
		self:SetAttribute("*type2", "togglemenu")
	end

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,backdrop.bgAlpha)
	self:SetBackdropBorderColor(0,0,0,0)

	-- Register setting callbacks early
	self:RegisterMessage('OnSingleLayoutModified', OnSingleLayoutModified)
	self:RegisterMessage('OnSettingsModified', OnSingleLayoutModified)
	self:RegisterMessage('OnSingleThemeModified', OnSingleThemeModified)
	self:RegisterMessage('OnSettingsModified', OnSingleThemeModified)
	self:RegisterMessage('OnColorModified', OnColorModified)
	self:RegisterMessage('OnSettingsModified', OnColorModified)
	self:RegisterMessage('OnSettingsModified', OnThemeModified)
	self:RegisterMessage('OnThemeModified', OnThemeModified)

	-- Border
	local border = CreateFrame("Frame", CreateName(self, "Border"), self)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER", self)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border.blackByDefault = true
	border.noTarget = not isArenaUnit and not strmatch(unit, "boss")
	self.Border = border

	local left, right, dir = "LEFT", "RIGHT", 1
	if settings.mirroredFrame then
		left, right, dir = "RIGHT", "LEFT", -1
	end

	-- Bar container
	local barContainer = private.SpawnBarLayout(self)
	self.BarContainer = barContainer

	-- Create an icon displaying important debuffs (either PvP or PvE)
	local importantDebuff = self:CreateIcon(self)
	importantDebuff.minPriority = 20
	local stack = importantDebuff.Stack
	stack:ClearAllPoints()
	stack:SetPoint("BOTTOMRIGHT", importantDebuff, -1, 1)
	self:RegisterFontString(importantDebuff.Stack, "number", 14, "OUTLINE")
	self.WarningIcon = importantDebuff

	-- Portrait
	if not settings.noPortrait then
		-- Spawn the player model
		local portrait = CreateFrame("PlayerModel", CreateName(self, "Portrait"), self)
		portrait:SetPoint(left)
		self.Portrait = portrait

		-- Display important (de)buff all over the portrait
		importantDebuff:SetFrameLevel(portrait:GetFrameLevel()+1)
		importantDebuff:SetAllPoints(portrait)

		-- Spawn a container frame that spans remaining space
		barContainer:SetPoint("TOP"..left, portrait, "TOP"..right, GAP*dir, 0)
		barContainer:SetPoint("BOTTOM"..right)

		-- Have the bars cover the whole frame if the portrait is disabled
		portrait:SetScript('OnShow', function() barContainer:SetPoint("TOP"..left, portrait, "TOP"..right, GAP*dir, 0) end)
		portrait:SetScript('OnHide', function() barContainer:SetPoint("TOP"..left, self, "TOP"..left, 0, 0) end)
	else
		barContainer:SetAllPoints(self)

		-- Display the on the side
		importantDebuff:SetPoint(left, self, right, GAP*dir, 0)
	end

	-- Health bar
	local health = SpawnStatusBar(self, false)
	health:SetPoint("TOPRIGHT", barContainer)
	health.frequentUpdates = true
	self.Health = health
	barContainer:AddWidget(health, 10, 4)

	-- Name
	local name = SpawnText(self, health, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0, "text")
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", TEXT_MARGIN)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, (unit == "player" or unit == "pet" or unit == "boss" or isArenaUnit) and "[name]" or "[name][ <>status<>]")
	self.Name = name

	-- Low health indicator
	local lowHealth = self:CreateTexture(CreateName(self, "LowHealth"), "OVERLAY")
	lowHealth:SetPoint("TOPLEFT", self, -2, 2)
	lowHealth:SetPoint("BOTTOMRIGHT", self, 2, -2)
	self.LowHealth = lowHealth

	-- Heal precitions
	self:SpawnHealPrediction(1.05)

	-- Used for some overlays
	local indicators = CreateFrame("Frame", CreateName(self, "Indicators"), self)
	indicators:SetAllPoints(self)
	indicators:SetFrameLevel(health:GetFrameLevel()+3)
	self.Indicators = indicators

	-- Power bar
	if not settings.noPower then
		local power = SpawnStatusBar(self, false)
		power.frequentUpdates = true
		power.PostUpdate = Power_PostUpdate
		self.Power = power
		barContainer:AddWidget(power, 20, 4)

		local powers = {}
		-- Additional power bars that requires specialization information
		if unit == 'player' or unit == 'target' or unit == 'focus' or unit == 'pet' then
			powers.MANA = private.SpawnStatusBar(self)
			powers.SOUL_SHARDS = private.SpawnHybridBar(self, 4, 100, [[Interface\Addons\oUF_Adirelle\media\white16x16]])
			powers.BURNING_EMBERS = private.SpawnHybridBar(self, 4, MAX_POWER_PER_EMBER)
			powers.BURNING_EMBERS.PostUpdate = HighlightBurningEmbers
			powers.DEMONIC_FURY = private.SpawnStatusBar(self)
			powers.SHADOW_ORBS = private.SpawnDiscreteBar(self, 4, false, [[Interface\Addons\oUF_Adirelle\media\white16x16]])
		end
		-- Additional power bars available only on players
		if unit == 'player' or unit == 'target' or unit == 'focus' or unit == 'pet' or unit == 'arena' then
			powers.CHI = private.SpawnDiscreteBar(self, 5, false, [[Interface\Addons\oUF_Adirelle\media\white16x16]])
			powers.HOLY_POWER = private.SpawnDiscreteBar(self, 5, false, [[Interface\Addons\oUF_Adirelle\media\white16x16]])
			powers.HOLY_POWER.PostUpdate = HighlightHolyPower
		end
		if next(powers) then
			for powerType, bar in pairs(powers) do
				barContainer:AddWidget(bar, 30 + _G['SPELL_POWER_'..powerType], 2)
			end
			powers.frequentUpdates = true
			self.Powers = powers
		end

		-- Special bars
		if unit == 'player' and private.SetupSecondaryPowerBar then
			local bar = private.SetupSecondaryPowerBar(self)
			barContainer:AddWidget(bar, 50, 2)
		end

		-- Unit level and class (or creature family)
		if unit ~= "player" and unit ~= "pet" then
			local classif = SpawnText(self, power, "OVERLAY", nil, nil, nil, nil, "text")
			classif:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -GAP)
			classif:SetPoint("BOTTOM", barContainer)
			classif:SetPoint("RIGHT", power.Text, "LEFT")
			self:Tag(classif, "[smartlevel][ >smartclass<]")
		end

		-- Casting Bar
		if unit ~= 'player' then
			local castbar = CreateFrame("StatusBar", CreateName(self, "CastBar"), self)
			castbar:Hide()
			castbar.__owner = self
			castbar:SetPoint('BOTTOMRIGHT', power)
			castbar.PostCastStart = function() castbar:SetStatusBarColor(1.0, 0.7, 0.0) end
			castbar.PostChannelStart = function() castbar:SetStatusBarColor(0.0, 1.0, 0.0) end
			castbar:SetScript('OnSizeChanged', CastBar_Update)
			castbar:SetScript('OnShow', CastBar_Update)
			self:RegisterStatusBarTexture(castbar)
			self.Castbar = castbar

			local icon = castbar:CreateTexture(CreateName(castbar, "Icon"), "ARTWORK")
			icon:SetPoint('TOPLEFT', power)
			icon:SetTexCoord(4/64, 60/64, 4/64, 60/64)
			castbar.Icon = icon

			local spellText = SpawnText(self, castbar, "OVERLAY", nil, nil, nil, nil, "text")
			spellText:SetPoint('TOPLEFT', castbar, 'TOPLEFT', TEXT_MARGIN, 0)
			spellText:SetPoint('BOTTOMRIGHT', castbar, 'BOTTOMRIGHT', -TEXT_MARGIN, 0)
			castbar.Text = spellText

			local bg = castbar:CreateTexture(CreateName(castbar, "Background"), "BACKGROUND")
			bg:SetTexture(0,0,0,1)
			bg:SetPoint('TOPLEFT', icon)
			bg:SetPoint('BOTTOMRIGHT', castbar)

			castbar:SetPoint("TOPLEFT", icon, "TOPRIGHT", GAP, 0)
			castbar:SetFrameLevel(power:GetFrameLevel() + 5)
			CastBar_Update(castbar)
		end
	end

	-- Threat Bar
	if unit == "target" then
		-- Add a simple threat bar on the target
		local threatBar = SpawnStatusBar(self, false)
		threatBar:SetBackdrop(backdrop)
		threatBar:SetBackdropColor(0,0,0,backdrop.bgAlpha)
		threatBar:SetBackdropBorderColor(0,0,0,1)
		threatBar:SetWidth(190*0.5)
		threatBar:SetHeight(14)
		threatBar:SetMinMaxValues(0, 100)
		threatBar.PostUpdate = function(self, event, unit, bar, isTanking, status, scaledPercent, rawPercent, threatValue)
			if not bar.Text then return end
			if threatValue then
				local value, unit = threatValue / 100, ""
				if value > 1000000 then
					value, unit = value / 1000000, "m"
				elseif value > 1000 then
					value, unit = value / 1000, "k"
				end
				bar.Text:SetFormattedText("%d%% (%.1f%s)", scaledPercent, value, unit)
				bar.Text:Show()
			else
				bar.Text:Hide()
			end
		end
		self.ThreatBar = threatBar
		AddAuxiliaryBar(self, threatBar)
	end

	-- Raid target icon
	self.RaidIcon = SpawnTexture(indicators, 16)
	self.RaidIcon:SetPoint("CENTER", barContainer)

	-- Threat glow
	local threat = CreateFrame("Frame", CreateName(self, "ThreatGlow"), self)
	threat:SetAllPoints(self.Border)
	threat:SetBackdrop(glowBorderBackdrop)
	threat:SetBackdropColor(0,0,0,0)
	threat.SetVertexColor = threat.SetBackdropBorderColor
	threat:SetAlpha(glowBorderBackdrop.alpha)
	threat:SetFrameLevel(self:GetFrameLevel()+2)
	self.SmartThreat = threat

	if unit ~= "boss" and not isArenaUnit then
		-- Various indicators
		self.Leader = SpawnTexture(indicators, 16, "TOP"..left)
		self.Assistant = SpawnTexture(indicators, 16, "TOP"..left)
		self.MasterLooter = SpawnTexture(indicators, 16, "TOP"..left, 16*dir)
		self.Combat = SpawnTexture(indicators, 16, "BOTTOM"..left)

		-- Indicators around the portrait, if there is one
		if self.Portrait then
			-- Group role icons
			self.RoleIcon = SpawnTexture(indicators, 16)
			self.RoleIcon:SetPoint("CENTER", self.Portrait, "TOP"..right)
			self.RoleIcon.noRaidTarget = true

			-- PvP flag
			local pvp = SpawnTexture(indicators, 16)
			pvp:SetTexCoord(0, 0.6, 0, 0.6)
			pvp:SetPoint("CENTER", self.Portrait, "BOTTOM"..right)
			self.PvP = pvp

			-- PvP timer
			if unit == "player" then
				local timer = CreateFrame("Frame", CreateName(indicators, "PvPTimer"), indicators)
				timer:SetAllPoints(pvp)
				timer.text = SpawnText(self, timer, "OVERLAY", nil, nil, nil, nil, "number")
				timer.text:SetPoint("CENTER", pvp)
				self.PvPTimer = timer
			end
		end
	end

	if unit == "player" then
		-- Player resting status
		self.Resting = SpawnTexture(indicators, 16, "BOTTOMLEFT")

	elseif unit == "target" then
		-- Combo points
		local DOT_SIZE = 10
		local cpoints = CreateFrame("Frame", CreateName(indicators, "ComboPoints"), indicators)
		cpoints:SetPoint("BOTTOM", health, 0, -DOT_SIZE/2)
		cpoints:SetSize((DOT_SIZE + GAP) * MAX_COMBO_POINTS - GAP, DOT_SIZE);
		for i =  1, MAX_COMBO_POINTS  do
			local cpoint = SpawnTexture(cpoints, DOT_SIZE)
			cpoint:SetTexture([[Interface\AddOns\oUF_Adirelle\media\combo]])
			cpoint:SetTexCoord(3/16, 13/16, 5/16, 15/16)
			cpoint:SetPoint("LEFT", (i-1)*(DOT_SIZE+GAP), 0)
			cpoint:Hide()
			tinsert(cpoints, cpoint)
		end
		self.CPoints = cpoints
	end

	-- Auras
	local buffs, debuffs
	if unit == "pet" then
		buffs = CreateFrame("Frame", CreateName(self, "Buffs"), self)
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, FRAME_MARGIN)
		buffs.initialAnchor = "BOTTOMLEFT"
		buffs.growthx = 1
		buffs.growthy = -1

	elseif (unit == "target" or unit == "focus" or unit == "boss" or unit == "arena") and settings.heightType ~= 'Small'then
		buffs = CreateFrame("Frame", CreateName(self, "Buffs"), self)
		buffs:SetPoint("BOTTOM"..right, self, "BOTTOM"..left, -FRAME_MARGIN*dir, 0)
		buffs.showType = true
		buffs.initialAnchor = "BOTTOM"..right
		buffs.growthx = (left == "LEFT") and -1 or 1
		buffs.growthy = 1

		debuffs = CreateFrame("Frame", CreateName(self, "Debuffs"), self)
		debuffs:SetPoint("TOP"..right, self, "TOP"..left, -FRAME_MARGIN*dir, 0)
		debuffs.showType = true
		debuffs.initialAnchor = "TOP"..right
		debuffs.growthx = (left == "LEFT") and -1 or 1
		debuffs.growthy = -1
	end

	if buffs then
		buffs.size = AURA_SIZE
		buffs.num = 12
		buffs:SetSize(AURA_SIZE * 12, AURA_SIZE)
		buffs.CustomFilter = Buffs_CustomFilter
		buffs.PreSetPosition = Auras_PreSetPosition
		buffs.SetPosition = Auras_SetPosition
		buffs.PostCreateIcon = Auras_PostCreateIcon
		buffs.PostUpdateIcon = Auras_PostUpdateIcon
		self.Buffs = buffs
	end
	if debuffs then
		debuffs.size = AURA_SIZE
		debuffs.num = 12
		debuffs:SetSize(AURA_SIZE * 12, AURA_SIZE)
		debuffs.CustomFilter = Debuffs_CustomFilter
		debuffs.PreSetPosition = Auras_PreSetPosition
		debuffs.SetPosition = Auras_SetPosition
		debuffs.PostCreateIcon = Auras_PostCreateIcon
		debuffs.PostUpdateIcon = Auras_PostUpdateIcon
		self.Debuffs = debuffs
	end

	if buffs or debuffs then
		self:RegisterEvent('UNIT_FACTION', Auras_ForceUpdate)
		self:RegisterEvent('UNIT_TARGETABLE_CHANGED', Auras_ForceUpdate)
		self:RegisterMessage('OnSettingsModified', OnAuraLayoutModified)
		self:RegisterMessage('OnSingleLayoutModified', OnAuraLayoutModified)
	end

	-- Classification dragon
	if not settings.noPortrait and (unit == "target" or unit == "focus" or unit == "boss") then
		local dragon = indicators:CreateTexture(CreateName(self, "Classification"), "ARTWORK")
		local DRAGON_HEIGHT = 45*95/80+2
		dragon:SetWidth(DRAGON_HEIGHT*117/95)
		dragon:SetHeight(DRAGON_HEIGHT)
		dragon:SetPoint('TOPLEFT', self, 'TOPLEFT', -44*DRAGON_HEIGHT/95-1, 15*DRAGON_HEIGHT/95+1)
		dragon.elite = DRAGON_TEXTURES.elite
		dragon.rare = DRAGON_TEXTURES.rare
		self.Dragon = dragon
	end

	-- Experience Bar for player
	if unit == "player" then
		local xpFrame = CreateFrame("Frame", CreateName(self, "XP"), self)
		xpFrame:SetPoint("TOP")
		xpFrame:SetPoint("RIGHT")
		xpFrame:SetHeight(12)
		xpFrame:SetBackdrop(backdrop)
		xpFrame:SetBackdropColor(0,0,0,backdrop.bgAlpha)
		xpFrame:SetBackdropBorderColor(0,0,0,1)
		xpFrame:EnableMouse(false)

		local xpBar = SpawnStatusBar(self, true)
		xpBar:SetParent(xpFrame)
		xpBar:SetAllPoints(xpFrame)
		xpBar.Show = function() return xpFrame:Show() end
		xpBar.Hide = function() return xpFrame:Hide() end
		xpBar.IsShown = function() return xpFrame:IsShown() end
		xpBar:EnableMouse(false)

		local restedBar = SpawnStatusBar(self, true)
		restedBar:SetParent(xpFrame)
		restedBar:SetAllPoints(xpFrame)
		restedBar:EnableMouse(false)

		local levelText = SpawnText(self, xpBar, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
		levelText:SetPoint("BOTTOMLEFT", xpBar, "BOTTOMLEFT", TEXT_MARGIN, 0)

		local xpText = SpawnText(self, xpBar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
		xpText:SetPoint("BOTTOMRIGHT", xpBar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)

		local smartValue = private.smartValue
		xpBar.UpdateText = function(self, bar, current, max, rested, level)
			levelText:SetFormattedText(level)
			if rested and rested > 0 then
				xpText:SetFormattedText("%s(+%s)/%s", smartValue(current), smartValue(rested), smartValue(max))
			else
				xpText:SetFormattedText("%s/%s", smartValue(current), smartValue(max))
			end
		end

		xpBar.Rested = restedBar
		xpBar:SetFrameLevel(restedBar:GetFrameLevel()+1)

		self.ExperienceBar = xpBar
		AddAuxiliaryBar(self, xpFrame)
	end

	-- Range indicator
	if unit ~= "player" then
		local xrange = indicators:CreateTexture(CreateName(indicators, "Range"), "BACKGROUND")
		xrange:SetAllPoints(self)
		xrange:SetTexture(0.4, 0.4, 0.4)
		xrange:SetBlendMode("MOD")
		xrange.PostUpdate = XRange_PostUpdate
		self.XRange = xrange
	end

	-- Special events
	if unit == "boss" then
		self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", self.UpdateAllElements)
	end
	self:RegisterEvent("UNIT_TARGETABLE_CHANGED", function(_, event, unit)
		if unit == self.unit then return self:UpdateAllElements(event)	end
	end)

	-- Altenate power bar (e.g. sound on Atramedes, or poison on Isorath)
	if unit == "player" or unit == "target" then

		local altPowerBar = SpawnStatusBar(self)
		altPowerBar:SetBackdrop(backdrop)
		altPowerBar:SetBackdropColor(0,0,0,backdrop.bgAlpha)
		altPowerBar:SetBackdropBorderColor(0,0,0,1)
		altPowerBar:SetPoint("LEFT")
		altPowerBar:SetPoint("RIGHT")
		altPowerBar:SetHeight(12)
		altPowerBar.showOthersAnyway = true
		altPowerBar.textureColor = { 1, 1, 1, 1 }
		altPowerBar.PostUpdate = AltPowerBar_PostUpdate

		local label = SpawnText(self, altPowerBar, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
		label:SetPoint("RIGHT", altPowerBar.Text, "LEFT", -TEXT_MARGIN, 0)
		altPowerBar.Label = label

		self.AltPowerBar = altPowerBar
		AddAuxiliaryBar(self, altPowerBar)
	end

	-- Update layout at least once
	self:HookScript('OnSizeChanged', LayoutBars)
	LayoutBars(self)
end

local single_style = setmetatable({
	["initial-width"] = 190,
	["initial-height"] = 47,
	heightType = 'Big',
}, {
	__call = InitFrame,
})

oUF:RegisterStyle("Adirelle_Single", single_style)

local single_style_right = setmetatable({
	mirroredFrame = true
}, {
	__call = InitFrame,
	__index = single_style,
})

oUF:RegisterStyle("Adirelle_Single_Right", single_style_right)

local single_style_health = setmetatable({
	["initial-height"] = 20,
	heightType = 'Small',
	noPower = true,
	noPortrait = true,
	noDragon = true
}, {
	__call = InitFrame,
	__index = single_style,
})

oUF:RegisterStyle("Adirelle_Single_Health", single_style_health)

oUF_Adirelle.SingleStyle = true

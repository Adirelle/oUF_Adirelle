--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local moduleName, private = ...

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

local BORDER_WIDTH = 2
local TEXT_MARGIN = 2
local GAP = 2
local FRAME_MARGIN = BORDER_WIDTH + GAP
local AURA_SIZE = 22

local borderBackdrop = { edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]], edgeSize = BORDER_WIDTH }

local SpawnTexture, SpawnText, SpawnStatusBar = private.SpawnTexture, private.SpawnText, private.SpawnStatusBar

local function UpdateHealBar(bar, unit, current, max, incoming)
	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		current, incoming  = 0, 0
	end
	if bar.incoming ~= incoming or bar.current ~= current or bar.max ~= max then
		bar.incoming, bar.current, bar.max = incoming, current, max
		local health = bar:GetParent()
		if current and max and incoming and incoming > 0 and max > 0 and current < max then
			local width = health:GetWidth()
			bar:SetPoint("LEFT", width * current / max, 0)
			bar:SetWidth(width * math.min(incoming, max-current) / max)
			bar:Show()
		else
			bar:Hide()
		end
	end
end

local function IncomingHeal_PostUpdate(bar, event, unit, incoming)
	return UpdateHealBar(bar, unit, bar.current, bar.max, incoming or 0)
end

local function Health_PostUpdate(healthBar, unit, current, max)
	local bar = healthBar:GetParent().IncomingHeal
	return UpdateHealBar(bar, unit, current, max, bar.incoming)
end

local function Auras_PostCreateIcon(icons, button)
	local cd, count, overlay = button.cd, button.count, button.overlay
	button.icon:SetTexCoord(5/64, 59/64, 5/64, 59/64)
	count:SetParent(cd)
	count:SetAllPoints(button)
	count:SetJustifyH("RIGHT")
	count:SetJustifyV("BOTTOM")
	overlay:SetParent(cd)
	overlay:SetTexture([[Interface\AddOns\oUF_Adirelle\media\icon_border]])
	overlay:SetTexCoord(0, 1, 0, 1)
	cd.noCooldownCount = true
	cd:SetReverse(true)
	cd:SetDrawEdge(true)
end

local function Auras_PostUpdateIcon(icons, unit, icon, index, offset)
	if not select(5, UnitAura(unit, index, icon.filter)) then
		icon.overlay:Hide()
	end
end

local LibDispellable = GetLib("LibDispellable-1.0")

local function IsMine(unit)
	return unit and (UnitIsUnit(unit, 'player') or UnitIsUnit(unit, 'pet') or UnitIsUnit(unit, 'vehicle'))
end

local canSteal = select(2, UnitClass("player")) == "MAGE"
local function Buffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura)
	if UnitCanAttack("player", unit) then
		icon.bigger = LibDispellable:CanDispel(unit, true, dtype, spellID) or (canSteal and isStealable)
		return true
	elseif UnitCanAssist("player", unit) then
		icon.bigger = IsMine(caster)
		if UnitAffectingCombat("player") then
			return duration > 0 and (icon.bigger or canApplyAura or not shouldConsolidate)
		else
			return true
		end
	end
	return true
end

local function Debuffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
	if UnitCanAttack("player", unit) then
		icon.bigger = IsMine(caster)
	elseif UnitCanAssist("player", unit) then
		icon.bigger = isBossDebuff or IsMine(caster) or LibDispellable:CanDispel(unit, false, dtype, spellID)
	end
	return true
end

local Auras_SetPosition
do
	local function CompareIcons(a, b)
		if a.bigger and not b.bigger then
			return true
		elseif not a.bigger and b.bigger then
			return false
		else
			return a:GetID() < b:GetID()
		end
	end

	function Auras_SetPosition(icons, numIcons)
		if not icons or numIcons == 0 then return end
		local spacing = icons.spacing or 1
		local size = icons.size or 16
		local anchor = icons.initialAnchor or "BOTTOMLEFT"
		local growthx = (icons["growth-x"] == "LEFT" and -1) or 1
		local growthy = (icons["growth-y"] == "DOWN" and -1) or 1
		local x = 0
		local y = 0
		local rowSize = 0
		local width = math.floor(icons:GetWidth() / size) * size
		local height = math.floor(icons:GetHeight() / size) * size

		table.sort(icons, CompareIcons)
		for i = 1, #icons do
			local button = icons[i]
			if button:IsShown() then
				local iconSize = button.bigger and size or size * 0.75
				rowSize = math.max(rowSize, iconSize)
				button:ClearAllPoints()
				button:SetWidth(iconSize)
				button:SetHeight(iconSize)
				button:SetPoint(anchor, icons, anchor, x * growthx, y * growthy)
				x = x + iconSize + spacing
				if x >= width then
					y = y + rowSize + spacing
					x = 0
					rowSize = 0
					if y >= height then
						for j = i+1, #icons do
							icons[j]:Hide()
						end
						return
					end
				end
			end
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
	local r, g, b = oUF.ColorGradient((cur-min)/(max-min), powerRed, powerGreen, powerBlue, 1, 0, 0)
	bar:SetStatusBarColor(r, g, b)
end

-- Additional auxiliary bars
local function LayoutAuxiliaryBars(self)
	local bars = self.AuxiliaryBars
	local anchor = self
	for i, bar in ipairs(self.AuxiliaryBars) do
		if bar:IsShown() then
			bar:SetPoint("TOP", anchor, "BOTTOM", 0, -FRAME_MARGIN)
			anchor = bar
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

-- General bar layuot
local function LayoutBars(self)
	local width, height = self:GetSize()
	if width == 0 or height == 0 then return end
	self.Border:SetWidth(width + 2 * BORDER_WIDTH)
	self.Border:SetHeight(height + 2 * BORDER_WIDTH)
	local portrait = self.Portrait
	if portrait then
		portrait:SetSize(height, height)
	end
	local power = self.Power
	if power then
		local totalPowerHeight = height * 0.45 - GAP
		local powerHeight = totalPowerHeight		
		if self.SecondaryPowerBar and self.SecondaryPowerBar:IsShown() then
			powerHeight = (totalPowerHeight - GAP) / 2	
		end
		power:SetHeight(powerHeight)
		height = height - totalPowerHeight - GAP
	end
	self.Health:SetHeight(height)
	if self.AuxiliaryBars then
		LayoutAuxiliaryBars(self)
	end
end

local DRAGON_TEXTURES = {
	rare  = { [[Interface\Addons\oUF_Adirelle\media\rare_graphic]],  6/128, 123/128, 17/128, 112/128, },
	elite = { [[Interface\Addons\oUF_Adirelle\media\elite_graphic]], 6/128, 123/128, 17/128, 112/128, },
}

local function OoC_UnitFrame_OnEnter(...)
	if not InCombatLockdown() then return UnitFrame_OnEnter(...) end
end

local function InitFrame(settings, self, unit)
	local unit = gsub(unit or self.unit, "%d+", "")

	self:SetSize(settings['initial-width'], settings['initial-height'])

	self:RegisterForClicks("AnyDown")

	self:SetScript("OnEnter", OoC_UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	if self:CanChangeAttribute() then
		self:SetAttribute("type", "target")
	end

	private.SetupUnitDropdown(self, unit)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,backdrop.bgAlpha)
	self:SetBackdropBorderColor(0,0,0,0)

	-- Border
	local border = CreateFrame("Frame", nil, self)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER", self)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border.blackByDefault = true
	border.noTarget = true
	self.Border = border

	local barContainer
	local left, right, dir = "LEFT", "RIGHT", 1
	if settings.mirroredFrame then
		left, right, dir = "RIGHT", "LEFT", -1
	end

	-- Portrait
	if not settings.noPortrait then
		-- Spawn the player model
		local portrait = CreateFrame("PlayerModel", nil, self)
		portrait:SetPoint(left)
		self.Portrait = portrait

		-- Create an icon displaying important debuffs (either PvP or PvE) all over the portrait
		local importantDebuff = self:CreateIcon(portrait)
		importantDebuff:SetAllPoints(portrait)
		local stack = importantDebuff.Stack
		stack:ClearAllPoints()
		stack:SetPoint("BOTTOMRIGHT", importantDebuff, -1, 1)
		importantDebuff.Stack:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
		self.WarningIcon = importantDebuff

		-- Spawn a container frame that spans remaining space
		barContainer = CreateFrame("Frame", nil, self)
		barContainer:SetPoint("TOP"..left, portrait, "TOP"..right, GAP*dir, 0)
		barContainer:SetPoint("BOTTOM"..right)
	else
		barContainer = self
	end
	self.BarContainer = barContainer

	-- Dynamic bar layout
	local UpdateLayout = function()
		local width, height = self:GetWidth(), self:GetHeight()
		if width and height then
			return LayoutBars(self, width, height)
		end
	end

	-- Health bar
	local health = SpawnStatusBar(self, false, "TOPLEFT", barContainer)
	health:SetPoint("TOPRIGHT", barContainer)
	health.barSizePercent = 55
	health.colorTapping = true
	health.colorDisconnected = true
	health.colorHappiness = true
	health.colorClass = true
	health.colorSmooth = true
	health.frequentUpdates = true
	self.Health = health

	-- Name
	local name = SpawnText(health, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN)
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", TEXT_MARGIN)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, (unit == "player" or unit == "pet" or unit == "boss") and "[name]" or "[name][ <>status<>]")
	self.Name = name

	if unit ~= "boss" then
		-- Low health indicator
		local lowHealth = self:CreateTexture(nil, "OVERLAY")
		lowHealth:SetPoint("TOPLEFT", self, -2, 2)
		lowHealth:SetPoint("BOTTOMRIGHT", self, 2, -2)
		lowHealth:SetTexture(1, 0, 0, 0.4)
		self.LowHealth = lowHealth

		-- Incoming heals
		local incomingHeal = health:CreateTexture(nil, "OVERLAY")
		incomingHeal:SetTexture([[Interface\AddOns\oUF_Adirelle\media\white16x16]])
		incomingHeal:SetVertexColor(0, 1, 0, 0.5)
		incomingHeal:SetBlendMode("ADD")
		incomingHeal:SetPoint("TOP", health)
		incomingHeal:SetPoint("BOTTOM", health)
		incomingHeal.PostUpdate = IncomingHeal_PostUpdate
		incomingHeal.current, incomingHeal.max, incomingHeal.incoming = 0, 0, 0
		self.IncomingHeal = incomingHeal

		health.PostUpdate = Health_PostUpdate
	end

	-- Used for some overlays
	local indicators = CreateFrame("Frame", nil, self)
	indicators:SetAllPoints(self)
	indicators:SetFrameLevel(health:GetFrameLevel()+3)
	self.Indicators = indicators

	-- Power bar
	if not settings.noPower then
		local power = SpawnStatusBar(self, false, "TOPLEFT", health, "BOTTOMLEFT", 0, -GAP)
		power:SetPoint('RIGHT', barContainer)
		power.colorDisconnected = true
		power.colorPower = true
		power.frequentUpdates = true
		power.PostUpdate = Power_PostUpdate
		self.Power = power

		if unit == "player" and private.SetupSecondaryPowerBar then
			-- Add player specific secondary power bar
			local bar = private.SetupSecondaryPowerBar(self)
			if bar then
				bar:Hide()
				bar:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 0, -GAP)
				bar:SetPoint('BOTTOMRIGHT', self.BarContainer)	
				local LayoutScript = function() return LayoutBars(self) end
				bar:HookScript('OnShow', LayoutScript)
				bar:HookScript('OnHide', LayoutScript)
				self.SecondaryPowerBar = bar
			end
		end

		-- Unit level and class (or creature family)
		if unit ~= "player" and unit ~= "pet" then
			local classif = SpawnText(power, "OVERLAY")
			classif:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -GAP)
			classif:SetPoint("BOTTOM", barContainer)
			classif:SetPoint("RIGHT", power.Text, "LEFT")
			self:Tag(classif, "[smartlevel][ >smartclass<]")
		end

		-- Casting Bar
		if unit ~= 'player' then
			local castbar = CreateFrame("StatusBar", nil, self)
			castbar:Hide()
			castbar:SetPoint('BOTTOMRIGHT', power)
			self:RegisterStatusBarTexture(castbar)
			self.Castbar = castbar

			castbar.PostCastStart = function()
				castbar:SetStatusBarColor(1.0, 0.7, 0.0)
			end
			castbar.PostChannelStart = function()
				castbar:SetStatusBarColor(0.0, 1.0, 0.0)
			end

			local icon = castbar:CreateTexture(nil, "ARTWORK")
			icon:SetPoint('TOPRIGHT', castbar, 'TOPLEFT', -GAP, 0)
			icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
			castbar.Icon = icon

			local spellText = SpawnText(castbar, "OVERLAY")
			spellText:SetPoint('TOPLEFT', castbar, 'TOPLEFT', TEXT_MARGIN, 0)
			spellText:SetPoint('BOTTOMRIGHT', castbar, 'BOTTOMRIGHT', -TEXT_MARGIN, 0)
			castbar.Text = spellText

			local UpdateSize = function()
				local height = castbar:GetHeight()
				if height and height ~= castbar.__height then
					castbar.__height = height
					castbar:SetPoint('TOPLEFT', power, 'TOPLEFT', GAP + height, 0)
					icon:SetWidth(height)
					icon:SetHeight(height)
				end
			end
			castbar:SetScript('OnSizeChanged', UpdateSize)
			castbar:SetScript('OnShow', function() power:Hide() UpdateSize() end)
			castbar:SetScript('OnHide', function() power:Show() end)
			UpdateSize()

			local ptFrame = CreateFrame("Frame", nil, self)
			ptFrame:SetAllPoints(power)
			ptFrame:SetFrameLevel(castbar:GetFrameLevel()+1)
			power.Text:SetParent(ptFrame)

			-- Enable the element depending on a CVar
			self.OptionalCastbar = true
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

	if unit ~= "boss" and not strmatch(unit, "arena") then
		-- Threat glow
		local threat = CreateFrame("Frame", nil, self)
		threat:SetAllPoints(self.Border)
		threat:SetBackdrop(glowBorderBackdrop)
		threat:SetBackdropColor(0,0,0,0)
		threat.SetVertexColor = threat.SetBackdropBorderColor
		threat:SetAlpha(glowBorderBackdrop.alpha)
		threat:SetFrameLevel(self:GetFrameLevel()+2)
		self.Threat = threat
	
		-- Various indicators
		self.Leader = SpawnTexture(indicators, 16, "TOP"..left)
		self.Assistant = SpawnTexture(indicators, 16, "TOP"..left)
		self.MasterLooter = SpawnTexture(indicators, 16, "TOP"..left, 16*dir)
		self.Combat = SpawnTexture(indicators, 16, "BOTTOM"..left)

		-- Assigned/guessed raid/party icons, if we have a portrait
		if self.Portrait then
			self.RoleIcon = SpawnTexture(indicators, 16)
			self.RoleIcon:SetPoint("CENTER", self.Portrait, "TOP"..right)
			self.RoleIcon.noRaidTarget = true
		end

		-- PvP flag
		if self.Portrait then
			local pvp = SpawnTexture(indicators, 12)
			pvp:SetTexCoord(0, 0.6, 0, 0.6)
			pvp:SetPoint("CENTER", self.Portrait, "BOTTOM"..right)
			self.PvP = pvp
		end
	end

	if unit == "pet" then
		-- Pet happiness
		self.Happiness = SpawnTexture(indicators, 16, "BOTTOMRIGHT")

	elseif unit == "player" then
		-- Player resting status
		self.Resting = SpawnTexture(indicators, 16, "BOTTOMLEFT")

	elseif unit == "target" then
		-- Combo points
		local DOT_SIZE = 10
		local cpoints = {}
		for i = 0, 4 do
			local cpoint = SpawnTexture(indicators, DOT_SIZE)
			cpoint:SetTexture([[Interface\AddOns\oUF_Adirelle\media\combo]])
			cpoint:SetTexCoord(3/16, 13/16, 5/16, 15/16)
			cpoint:SetPoint("LEFT", health, "BOTTOMLEFT", i*(DOT_SIZE+GAP), 0)
			cpoint:Hide()
			tinsert(cpoints, cpoint)
		end
		self.ComboPoints = cpoints
	end

	-- Auras
	local buffs, debuffs
	if unit == "pet" then
		buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, FRAME_MARGIN)
		buffs.initialAnchor = "BOTTOMLEFT"
		buffs['growth-x'] = "RIGHT"
		buffs['growth-y'] = "UP"

	elseif unit == "target" or unit == "focus" or unit == "boss" or unit == "arena" then
		buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOM"..right, self, "BOTTOM"..left, -FRAME_MARGIN*dir, 0)
		buffs.showType = true
		buffs.initialAnchor = "BOTTOM"..right
		buffs['growth-x'] = left
		buffs['growth-y'] = "UP"

		debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint("TOP"..right, self, "TOP"..left, -FRAME_MARGIN*dir, 0)
		debuffs.showType = true
		debuffs.initialAnchor = "TOP"..right
		debuffs['growth-x'] = left
		debuffs['growth-y'] = "DOWN"
	end

	if buffs then
		buffs.size = AURA_SIZE
		buffs.num = 12
		buffs:SetWidth(AURA_SIZE * 12)
		buffs:SetHeight(AURA_SIZE)
		buffs.CustomFilter = Buffs_CustomFilter
		buffs.SetPosition = Auras_SetPosition
		buffs.PostCreateIcon = Auras_PostCreateIcon
		buffs.PostUpdateIcon = Auras_PostUpdateIcon
		self.Buffs = buffs
	end
	if debuffs then
		debuffs.size = AURA_SIZE
		debuffs.num = 12
		debuffs:SetWidth(AURA_SIZE * 12)
		debuffs:SetHeight(AURA_SIZE)
		debuffs.CustomFilter = Debuffs_CustomFilter
		debuffs.SetPosition = Auras_SetPosition
		debuffs.PostCreateIcon = Auras_PostCreateIcon
		debuffs.PostUpdateIcon = Auras_PostUpdateIcon
		self.Debuffs = debuffs
	end
	
	if buffs or debuffs then
		self:RegisterEvent('UNIT_FACTION', Auras_ForceUpdate)
		self:RegisterEvent('UNIT_TARGETABLE_CHANGED', Auras_ForceUpdate)
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Auras_ForceUpdate)
		self:RegisterEvent('PLAYER_REGEN_DISABLED', Auras_ForceUpdate)
	end

	-- Classification dragon
	if unit == "target" or unit == "focus" or unit == "boss" then
		local dragon = indicators:CreateTexture(nil, "ARTWORK")
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
		local xpFrame = CreateFrame("Frame", nil, self)
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

		local levelText = SpawnText(xpBar, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
		levelText:SetPoint("BOTTOMLEFT", xpBar, "BOTTOMLEFT", TEXT_MARGIN, 0)

		local xpText = SpawnText(xpBar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
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

	-- Range fading
	self.XRange = true

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

		local label = SpawnText(altPowerBar, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
		label:SetPoint("RIGHT", altPowerBar.Text, "LEFT", -TEXT_MARGIN, 0)
		altPowerBar.Label = label

		self.AltPowerBar = altPowerBar
		AddAuxiliaryBar(self, altPowerBar)
	end

	-- Update layout at least once
	self:HookScript('OnSizeChanged', UpdateLayout)
	UpdateLayout()
end

local single_style = setmetatable({
	["initial-width"] = 190,
	["initial-height"] = 47,
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
	noPower = true,
	noPortrait = true
}, {
	__call = InitFrame,
	__index = single_style,
})

oUF:RegisterStyle("Adirelle_Single_Health", single_style_health)

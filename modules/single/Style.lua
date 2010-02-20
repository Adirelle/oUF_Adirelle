--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

local BORDER_WIDTH = 2
local TEXT_MARGIN = 2
local GAP = 2
local FRAME_MARGIN = BORDER_WIDTH + GAP
local AURA_SIZE = 15

local borderBackdrop = { edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]], edgeSize = BORDER_WIDTH }

local floor = math.floor
local strformat = string.format

local function smartValue(value)
	if value >= 10000000 then
		return strformat("%.1fm", value/1000000)
	elseif value >= 10000 then
		return strformat("%.1fk", value/1000)
	else
		return tostring(value)
	end
end

local function OnStatusBarUpdate(bar)
	if not bar:IsShown() then return end
	local text = bar.Text
	if not text then return end
	local value, min, max = bar:GetValue(), bar:GetMinMaxValues()
	if max == 100 then
		text:SetFormattedText("%d%%", floor(value))
	elseif max == 0 then
		return text:Hide()
	else
		local perValue = ((value < max) and UnitClassification(bar:GetParent().unit) ~= 'normal') and strformat("%d%% ", floor(value/max*100)) or ""
		local maxValue = smartValue(max)
		local curValue = value < max and (smartValue(value).."/") or ""
		text:SetText(perValue..curValue..maxValue)
	end
	text:Show()
end

local fontPath, fontSize, fontFlags = GameFontWhiteSmall:GetFont()
local lsm = GetLib('LibSharedMedia-3.0')
if lsm then
	local altFont = lsm:Fetch("font", "ABF", true)
	if altFont then
		fontPath, fontSize, fontFlags = altFont, 12, ""
	end
end

local function SetFont(fs, size, flags)
	fs:SetFont(fontPath, size or fontSize, flags or fontFlags)
	fs:SetTextColor(1, 1, 1, 1)
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
end

local function SpawnTexture(object, size, to, xOffset, yOffset)
	local texture = object:CreateTexture(nil, "OVERLAY")
	texture:SetWidth(size)
	texture:SetHeight(size)
	texture:SetPoint("CENTER", object, to or "CENTER", xOffset or 0, yOffset or 0)
	return texture
end

local function SpawnText(object, layer, from, to, xOffset, yOffset)
	local text = object:CreateFontString(nil, layer)
	SetFont(text)
	text:SetWidth(0)
	text:SetHeight(0)
	text:SetJustifyV("MIDDLE")
	if from then
		text:SetPoint(from, object, to or from, xOffset or 0, yOffset or 0)
		if from:match("RIGHT") then
			text:SetJustifyH("RIGHT")
		elseif from:match("LEFT") then
			text:SetJustifyH("LEFT")
		else
			text:SetJustifyH("CENTER")
		end
	else
		text:SetJustifyH("LEFT")
	end
	return text
end

local function SpawnStatusBar(self, noText, from, anchor, to, xOffset, yOffset)
	local bar = CreateFrame("StatusBar", nil, self)
	if not noText then
		local text = SpawnText(bar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
		text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
		bar.Text = text
		bar:SetScript('OnShow', OnStatusBarUpdate)
		bar:SetScript('OnValueChanged', OnStatusBarUpdate)
		bar:SetScript('OnMinMaxChanged', OnStatusBarUpdate)
	end
	if from then
		bar:SetPoint(from, anchor or self, to or from, xOffset or 0, yOffset or 0)
	end
	self:RegisterStatusBarTexture(bar)
	return bar
end

local UpdateIncomingHeal, PostUpdateHealth, PostIncomingHealTextureUpdate
if oUF.HasIncomingHeal then
	local function UpdateHealBar(bar, current, max, incomingHeal)
		if bar.incomingHeal ~= incomingHeal or bar.currentHealth ~= current or bar.maxHealth ~= max then
			bar.incomingHeal, bar.currentHealth, bar.maxHealth = incomingHeal, current, max
			if current and incomingHeal and incomingHeal > 0 and max and max > 0 then
				bar:SetMinMaxValues(0, max)
				bar:SetValue(current + incomingHeal)
				bar:Show()
			else
				bar:Hide()
			end
		end
	end

	function UpdateIncomingHeal(self, event, unit, bar, incomingHeal)
		UpdateHealBar(bar, bar.currentHealth, bar.maxHealth, incomingHeal)
	end

	function PostUpdateHealth(self, event, unit, _, current, max)
		local bar = self.IncomingHeal
		UpdateHealBar(bar, current, max, bar.incomingHeal)
	end

	function PostIncomingHealTextureUpdate(bar)
		bar:SetStatusBarColor(0, 1, 0, 0.75)
	end
end

local function PostCreateAuraIcon(self, button, icons, index, debuff)
	--button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.cd.noCooldownCount = true
	button.cd:SetReverse(true)
	button.cd:SetDrawEdge(true)
end


local CUREABLE_DEBUFF_TYPE = {
	Curse = (playerClass == "DRUID" or playerClass == "MAGE"),
	Disease = (playerClass == "PRIEST" or playerClass == "PALADIN" or playerClass == "SHAMAN"),
	Magic = (playerClass == "PRIEST" or playerClass == "PALADIN" or playerClass == "WARLOCK"),
	Poison = (playerClass == "DRUID" or playerClass == "PALADIN" or playerClass == "SHAMAN"),
}

local OFFENSIVE_DISPELL = (playerClass == "SHAMAN" or playerClass == "PRIEST" or playerClass == "HUNTER" or playerClass == "WARLOCK")

local function CustomAuraFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID)
	if not name then
		icon.isPlayer, icon.owner, icon.bigger = nil, nil, nil
		return
	end
	icon.owner, icon.isPlayer = caster, (caster == 'player' or caster == 'vehicle' or caster == 'pet')
	icon.bigger = icon.isPlayer
	if UnitCanAttack("player", unit) then
		-- Enemy
		if not icon.debuff then
			icon.bigger = (dtype == "Magic" and OFFENSIVE_DISPELL) or (playerClass == "MAGE" and isStealable)
		end
	elseif unit == "player" or UnitCanAssist("player", unit) then
		-- Friend
		if icon.debuff then
			icon.bigger = dtype and CUREABLE_DEBUFF_TYPE[dtype]
		elseif InCombatLockdown() and (shouldConsolidate or (duration or 0) == 0) then
			return false
		end
	end
	return true
end

local function SetAuraPosition(self, icons, numIcons)
	if not icons or numIcons == 0 then return end
	local spacing = icons.spacing or 0
	local defaultSize = icons.size or 16
	local anchor = icons.initialAnchor or "BOTTOMLEFT"
	local growthx = (icons["growth-x"] == "LEFT" and -1) or 1
	local growthy = (icons["growth-y"] == "DOWN" and -1) or 1
	local x = 0
	local y = 0
	local rowHeight = defaultSize
	local width = icons:GetWidth()
	local height = icons:GetHeight()

	for i = 1, #icons do
		local button = icons[i]
		if button and button:IsShown() then
			local size = defaultSize
			if button.bigger then
				size = icons.bigSize or size * 1.5
				rowHeight = size
			end

			if x >= width  then
				x, y, rowSize = 0, y + rowHeight + spacing, defaultSize
			end
			button:ClearAllPoints()
			button:SetPoint(anchor, icons, anchor, x * growthx, y * growthy)
			button:SetWidth(size)
			button:SetHeight(size)

			x = x + size + spacing
		elseif(not button) then
			break
		end
	end
end

local function OnSizeChanged(self, width, height)
	width = width or self:GetWidth()
	height = height or self:GetHeight()
	self.Border:SetWidth(width + 2*BORDER_WIDTH)
	self.Border:SetHeight(height + 2*BORDER_WIDTH)
	local portrait = self.Portrait
	if portrait then
		portrait:SetWidth(height)
		portrait:SetHeight(height)
	end
	if self.Power then
		self.Health:SetHeight((height-GAP)*0.55)
		if self.AltPower then
			self.AltPower:SetHeight((height-2*GAP)*0.20)
		end
	end
	end

local SetupAltPower
if playerClass == 'DEATHKNIGHT' then
	-- Death Knight Runes

	oUF.colors.runes = oUF.colors.runes or {
		{ 1, 0, 0  },
		{ 0, 0.5, 0 },
		{ 0, 1, 1 },
		{ 0.8, 0.1, 1 },
	}

	local function UpdateRuneColor(rune)
		local color = oUF.colors.runes[GetRuneType(rune.index) or false]
		if color then
			rune:SetStatusBarColor(unpack(color))
		end
	end


	local function LayoutRunes(runeBar)
		local spacing = (runeBar:GetWidth() + GAP) / 6
		local runeWidth = spacing - GAP
		local runeHeight = runeBar:GetHeight()
		for index = 1, 6 do
			local rune = runeBar[index]
			rune:SetPoint("TOPLEFT", runeBar, "TOPLEFT", spacing * (index-1), 0)
			rune:SetWidth(runeWidth)
			rune:SetHeight(runeHeight)
		end
	end

	function SetupAltPower(self)
		local runeBar = CreateFrame("Frame", nil, self)
		runeBar:HookScript('OnShow', LayoutRunes)
		runeBar:HookScript('OnSizeChanged', LayoutRunes)
		self.RuneBar = runeBar
		for index = 1, 6 do
			local rune = CreateFrame("StatusBar", nil, runeBar)
			rune.index = index
			rune.UpdateRuneColor = UpdateRuneColor
			self:RegisterStatusBarTexture(rune, UpdateRuneColor)
			runeBar[index] = rune
		end
		return runeBar
	end

elseif playerClass == "DRUID" then
	-- Druid mana bar

	function SetupAltPower(self)
		local POWERTYPE_MANA = 0

		local altPower = SpawnStatusBar(self)
		altPower.PostTextureUpdate = function()
			altPower:SetStatusBarColor(unpack(oUF.colors.power.MANA))
		end

		self.PostUpdatePower = function(self, event, unit)
			local power, altPower = self.Power, self.AltPower
			if unit == 'player' and UnitPowerType(unit) ~= POWERTYPE_MANA then
				local current, max = UnitPower(unit, POWERTYPE_MANA), UnitPowerMax(unit, POWERTYPE_MANA)
				if max and max > 0 then
					altPower:SetMinMaxValues(0, max)
					altPower:SetValue(current)
					return altPower:Show()
				end
			end
			altPower:Hide()
		end

		return altPower
	end

elseif playerClass == "SHAMAN" then
	-- Shaman totems

	oUF.colors.totems = oUF.colors.totems or {
		[FIRE_TOTEM_SLOT] = { 1, 0.3, 0.0  },
		[EARTH_TOTEM_SLOT] = { 0.3, 1, 0.2 },
		[WATER_TOTEM_SLOT] = { 0.3, 0.2, 1 },
		[AIR_TOTEM_SLOT] = { 0.2, 0.8, 1 },
	}

	local function UpdateTotemColor(totem)
		local color = oUF.colors.totems[totem.totemType]
		if color then
			totem:SetStatusBarColor(unpack(color))
		end
	end

	local function LayoutTotems(totemBar)
		local spacing = (totemBar:GetWidth() + GAP) / MAX_TOTEMS
		local totemWidth = spacing - GAP
		local totemHeight = totemBar:GetHeight()
		for index = 1, MAX_TOTEMS do
			local totem = totemBar[index]
			totem:SetPoint("TOPLEFT", totemBar, "TOPLEFT", spacing * (index-1), 0)
			totem:SetWidth(totemWidth)
			totem:SetHeight(totemHeight)
		end
	end

	function SetupAltPower(self)
		local totemBar = CreateFrame("Frame", nil, self)
		totemBar:HookScript('OnShow', LayoutTotems)
		totemBar:HookScript('OnSizeChanged', LayoutTotems)
		self.TotemBar = totemBar
		for index = 1, MAX_TOTEMS do
			local totem = CreateFrame("StatusBar", nil, totemBar)
			totem.totemType = TOTEM_PRIORITIES[index]
			self:RegisterStatusBarTexture(totem, UpdateTotemColor)
			totemBar[index] = totem
		end
		return totemBar
	end

end

local function PostUpdatePower(self, event, unit, bar, min, max)
	if bar.disconnected or UnitIsDeadOrGhost(unit) then
		bar:SetValue(0)
	end
end

local DROPDOWN_FRAMES = {
	player = "PlayerFrame",
	pet = "PetFrame",
	target = "TargetFrame",
	focus = "FocusFrame",
}

local DRAGON_TEXTURES = {
	rare  = { [[Interface\Addons\oUF_Adirelle\media\rare_graphic]],  6/128, 123/128, 17/128, 112/128, },
	elite = { [[Interface\Addons\oUF_Adirelle\media\elite_graphic]], 6/128, 123/128, 17/128, 112/128, },
}

local function ToggleMenu(self, unit, button, actionType)
	ToggleDropDownMenu(1, nil, DROPDOWN_MENUS[unit], self:GetName(), 0, 0)
end

local function OoC_UnitFrame_OnEnter(...)
	if not InCombatLockdown() then return UnitFrame_OnEnter(...) end
end

local function InitFrame(settings, self)
	local unit = self.unit

	self:RegisterForClicks("AnyUp")
	self:SetAttribute("type", "target");

	self:SetScript("OnEnter", OoC_UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	local dropdownButton = DROPDOWN_FRAMES[unit]
	if dropdownButton then
		-- Hacky workaround
		local f = _G[dropdownButton]
		self:SetAttribute("*type2", "click")
		self:SetAttribute("*clickbutton2", f)
		f:ClearAllPoints()
		f:SetAllPoints(self)
	end

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)
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
		local importantDebuff = self:SpawnAuraIcon(portrait)
		importantDebuff:SetAllPoints(portrait)
		self:AddAuraIcon(importantDebuff, "ImportantDebuff")

		-- Spawn a container frame that spans remaining space
		barContainer = CreateFrame("Frame", nil, self)
		barContainer:SetPoint("TOP"..left, portrait, "TOP"..right, GAP*dir, 0)
		barContainer:SetPoint("BOTTOM"..right)
	else
		barContainer = self
	end
	self.BarContainer = barContainer

	-- Health bar
	local health = SpawnStatusBar(self, false, "TOPLEFT", barContainer)
	health:SetPoint("TOPRIGHT", barContainer)
	health.colorTapping = true
	health.colorDisconnected = true
	health.colorHappiness = true
	health.colorClass = true
	health.colorSmooth = true
	--health.frequentUpdates = true	-- let LibQuickHealth handle this
	self.Health = health

	-- Name
	local name = SpawnText(health, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN)
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", TEXT_MARGIN)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, (unit == "player" or unit == "pet") and "[name]" or "[name][( <)status(>)]")
	self.Name = name

	-- Incoming heals
	if oUF.HasIncomingHeal then
		local incomingHeal = CreateFrame("StatusBar", nil, self)
		incomingHeal:SetAllPoints(health)
		incomingHeal:SetFrameLevel(health:GetFrameLevel()-1)
		self:RegisterStatusBarTexture(incomingHeal, PostIncomingHealTextureUpdate)

		self.IncomingHeal = incomingHeal
		self.UpdateIncomingHeal = UpdateIncomingHeal
		self.PostUpdateHealth = PostUpdateHealth
	end

	-- Power bar
	if not settings.noPower then
		local power = SpawnStatusBar(self, false, "TOPLEFT", health, "BOTTOMLEFT", 0, -GAP)
		power:SetPoint("BOTTOMRIGHT", barContainer)
		power.colorDisconnected = true
		power.colorPower = true
		power.frequentUpdates = true
		self.PostUpdatePower = PostUpdatePower
		self.Power = power

		-- Unit level and class (or creature family)
		if unit ~= "player" and unit ~= "pet" then
			local classif = SpawnText(barContainer, "OVERLAY")
			classif:SetPoint("TOPLEFT", power, "TOPLEFT", TEXT_MARGIN, 0)
			classif:SetPoint("RIGHT", power.Text, "LEFT")
			classif:SetPoint("BOTTOM", barContainer)
			self:Tag(classif, "[smartlevel][( )smartclass]")
		end

		if unit == "player" and SetupAltPower then
			local altPower = SetupAltPower(self)
			altPower:SetPoint("BOTTOMRIGHT", barContainer)
			altPower:SetPoint("BOTTOMLEFT", barContainer)
			altPower:Hide()
			altPower:SetScript('OnShow', function()
				power:SetPoint("BOTTOMRIGHT", altPower, "TOPRIGHT", 0, GAP)
			end)
			altPower:SetScript('OnHide', function()
				power:SetPoint("BOTTOMRIGHT", barContainer)
			end)
			self.AltPower = altPower
		end
	else
		health:SetPoint("BOTTOMRIGHT", barContainer)
	end

	if unit == "target" then
		-- Add a simple threat bar on the target
		local threatBar = SpawnStatusBar(self, false, "TOPRIGHT", self, "BOTTOMRIGHT", 0, -FRAME_MARGIN)
		threatBar:SetBackdrop(backdrop)
		threatBar:SetBackdropColor(0,0,0,1)
		threatBar:SetBackdropBorderColor(0,0,0,1)
		threatBar:SetWidth(190*0.5)
		threatBar:SetHeight(16)
		threatBar:SetMinMaxValues(0, 100)
		self.PostThreatBarUpdate = function(self, event, unit, bar, isTanking, status, scaledPercent, rawPercent, threatValue)
			if not bar.Text then return end
			self:Debug(event, unit, bar, isTanking, status, scaledPercent, rawPercent, threatValue)
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
	end

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
	local indicators = CreateFrame("Frame", nil, self)
	indicators:SetAllPoints(self)
	indicators:SetFrameLevel(health:GetFrameLevel()+3)
	self.Leader = SpawnTexture(indicators, 16, "TOP"..left)
	self.Assistant = SpawnTexture(indicators, 16, "TOP"..left)
	self.MasterLooter = SpawnTexture(indicators, 16, "TOP"..left, 16*dir)
	self.Combat = SpawnTexture(indicators, 16, "BOTTOM"..left)

	self.RoleIcon = SpawnTexture(indicators, 16)
	self.RoleIcon:SetPoint("CENTER", barContainer)

	if unit == "pet" then
		self.Happiness = SpawnTexture(indicators, 16, "BOTTOMRIGHT")
	end

	if unit == "player" then
		self.Resting = SpawnTexture(indicators, 16, "BOTTOMLEFT")
	end

	if self.Portrait then
		local pvp = SpawnTexture(indicators, 12)
		pvp:SetTexCoord(0, 0.6, 0, 0.6)
		pvp:SetPoint("CENTER", self.Portrait, "BOTTOM"..right)
		self.PvP = pvp
	end

	-- Combo points
	if unit == "target" or unit == "focus" then
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
	if unit == "pet" then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, FRAME_MARGIN)
		buffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, FRAME_MARGIN)
		buffs:SetHeight(AURA_SIZE * 2)
		self.Buffs = buffs
		--self.CustomAuraFilter = PetBuffFilter
	elseif unit == "target" or unit == "focus" then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOM"..right, self, "BOTTOM"..left, -FRAME_MARGIN*dir, 0)
		buffs.num = 12
		buffs:SetWidth(12 * AURA_SIZE)
		buffs:SetHeight(AURA_SIZE)
		buffs.onlyShowPlayer = (unit == "player")
		buffs.showType = (unit ~= "player")
		buffs.initialAnchor = "BOTTOM"..right
		buffs['growth-x'] = left
		buffs['growth-y'] = "UP"
		self.Buffs = buffs

		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint("TOP"..right, self, "TOP"..left, -FRAME_MARGIN*dir, 0)
		debuffs.num = 24
		debuffs.showType = true
		debuffs:SetWidth(12 * AURA_SIZE)
		debuffs:SetHeight(2 * AURA_SIZE)
		debuffs.initialAnchor = "TOP"..right
		debuffs['growth-x'] = left
		debuffs['growth-y'] = "DOWN"
		self.Debuffs = debuffs

	end
	self.CustomAuraFilter = CustomAuraFilter
	self.SetAuraPosition = SetAuraPosition

	if self.Buffs then
		self.Buffs.size = AURA_SIZE
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end
	if self.Debuffs then
		self.Debuffs.size = AURA_SIZE
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end

	-- Classification dragon
	if unit == "target" or unit == "focus" then
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
		xpFrame:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -FRAME_MARGIN)
		xpFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, -FRAME_MARGIN-12)
		xpFrame:SetBackdrop(backdrop)
		xpFrame:SetBackdropColor(0,0,0,1)
		xpFrame:SetBackdropBorderColor(0,0,0,1)
		xpFrame:EnableMouse(false)

		local xpBar = SpawnStatusBar(self, true)
		xpBar:SetParent(xpFrame)
		xpBar:SetAllPoints(xpFrame)
		xpBar.Show = function() return xpFrame:Show() end
		xpBar.Hide = function() return xpFrame:Hide() end
		xpBar.IsShown = function() return xpFrame:IsShown() end
		xpBar:EnableMouse(false)
		xpBar.PostTextureUpdate = function() self:UpdateElement('Experience') end

		local restedBar = SpawnStatusBar(self, true)
		restedBar:SetParent(xpFrame)
		restedBar:SetAllPoints(xpFrame)
		restedBar:EnableMouse(false)
		restedBar.PostTextureUpdate = xpBar.PostTextureUpdate
		
		local levelText = SpawnText(xpBar, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
		levelText:SetPoint("BOTTOMLEFT", xpBar, "BOTTOMLEFT", TEXT_MARGIN, 0)

		local xpText = SpawnText(xpBar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
		xpText:SetPoint("BOTTOMRIGHT", xpBar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
		
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
	end

	-- Range fading
	self.XRange = true

	self:HookScript('OnSizeChanged', OnSizeChanged)
	if self:IsShown() and self:GetWidth() and self:GetHeight() then
		OnSizeChanged(self)
	end
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

-- DiminishingReturns support
if DiminishingReturns and DiminishingReturns.DeclareOUF then
	DiminishingReturns:DeclareOUF('oUF_Adirelle', oUF)
end


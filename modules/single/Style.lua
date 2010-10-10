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
local AURA_SIZE = 22

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

local IncomingHeal_PostUpdate, Health_PostUpdate
if oUF.HasIncomingHeal then
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

	function IncomingHeal_PostUpdate(bar, event, unit, incoming)
		return UpdateHealBar(bar, unit, bar.current, bar.max, incoming or 0)
	end

	function Health_PostUpdate(healthBar, unit, current, max)
		local bar = healthBar:GetParent().IncomingHeal
		return UpdateHealBar(bar, unit, current, max, bar.incoming)
	end
end

local function Auras_PostCreateIcon(icons, button)
	button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
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

local function Buffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID)
	if (unit == "player" or UnitCanAssist("player", unit)) then
		if InCombatLockdown() and (shouldConsolidate or (duration or 0) == 0) then
			return false
		else
			icon.bigger = (caster == 'player' or caster == 'vehicle' or caster == 'pet')
		end
	elseif UnitCanAttack("player", unit) then
		icon.bigger = (dtype == "Magic" and OFFENSIVE_DISPELL) or (playerClass == "MAGE" and isStealable)
	else
		icon.bigger = nil
	end
	return true
end

local function Debuffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID)
	if unit == "player" or UnitCanAssist("player", unit) then
		icon.bigger = dtype and CUREABLE_DEBUFF_TYPE[dtype]
	elseif UnitCanAttack("player", unit) then
		icon.bigger = (caster == 'player' or caster == 'vehicle' or caster == 'pet')
	else
		icon.bigger = nil
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
		local spacing = icons.spacing or 0
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
		runeBar:SetScript('OnShow', LayoutRunes)
		runeBar:SetScript('OnSizeChanged', LayoutRunes)
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

	function AltPower_Update(power, event, unit)
		local altPower = power:GetParent().AltPower
		if unit == 'player' and UnitPowerType(unit) ~= SPELL_POWER_MANA then
			local current, max = UnitPower(unit, SPELL_POWER_MANA), UnitPowerMax(unit, SPELL_POWER_MANA)
			if max and max > 0 then
				altPower:SetMinMaxValues(0, max)
				altPower:SetValue(current)
				return altPower:Show()
			end
		end
		return altPower:Hide()
	end

	function SetupAltPower(self)

		local altPower = SpawnStatusBar(self)
		altPower:Hide()
		altPower.textureColor = oUF.colors.power.MANA

		if self.Power.PostUpdate then
			local orig = self.Power.PostUpdate
			self.Power.PostUpdate = function(...)
				AltPower_Update(...)
				return orig(...)
			end
		else
			self.Power.PostUpdate = AltPower_Update
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
		totemBar:SetScript('OnShow', LayoutTotems)
		totemBar:SetScript('OnSizeChanged', LayoutTotems)
		self.TotemBar = totemBar
		for index = 1, MAX_TOTEMS do
			local totem = CreateFrame("StatusBar", nil, totemBar)
			totem.totemType = TOTEM_PRIORITIES[index]
			self:RegisterStatusBarTexture(totem, UpdateTotemColor)
			totemBar[index] = totem
		end
		return totemBar
	end

elseif playerClass == "WARLOCK" then
	-- Warlock shards

	local function LayoutShards(soulShardBar)
		local spacing = (soulShardBar:GetWidth() + GAP) / SHARD_BAR_NUM_SHARDS
		local width = spacing - GAP
		local height = soulShardBar:GetHeight()
		for index = 1, SHARD_BAR_NUM_SHARDS do
			local shard = soulShardBar[index]
			shard:SetPoint("TOPLEFT", soulShardBar, "TOPLEFT", spacing * (index-1), 0)
			shard:SetSize(width, height)
		end
	end

	function SetupAltPower(self)
		local soulShardBar = CreateFrame("Frame", nil, self)
		soulShardBar:SetScript('OnShow', LayoutShards)
		soulShardBar:SetScript('OnSizeChanged', LayoutShards)
		self.SoulShards = soulShardBar
		for index = 1, SHARD_BAR_NUM_SHARDS do
			local shard = CreateFrame("StatusBar", nil, soulShardBar)
			self:RegisterStatusBarTexture(shard)
			soulShardBar[index] = shard
		end
		return soulShardBar
	end

end

local function Power_PostUpdate(power, unit, min, max)
	if power.disconnected or UnitIsDeadOrGhost(unit) then
		power:SetValue(0)
	end
end

local function LayoutBars(self, width, height)
	if width == 0 or height == 0 then return end
	self.Border:SetWidth(width + 2 * BORDER_WIDTH)
	self.Border:SetHeight(height + 2 * BORDER_WIDTH)
	local portrait = self.Portrait
	if portrait then
		portrait:SetWidth(height)
		portrait:SetHeight(height)
	end
	if self.Power then
		local powerHeight = height * 0.45
		height = height - powerHeight
		if self.AltPower and self.AltPower:IsShown() then
			local altHeight = powerHeight * 0.45
			powerHeight = powerHeight - altHeight
			self.AltPower:SetHeight(altHeight - GAP)
		end
		self.Power:SetHeight(powerHeight - GAP)
	end
	self.Health:SetHeight(height)
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

do
	local function Update(self, event, name)
		if event == "CVAR_UPDATE" and name ~= "SHOW_TARGET_CASTBAR" then return end
		local enabled = not not GetCVarBool("showTargetCastbar")
		if enabled == self.Castbar.enabled then return end
		self.Castbar.enabled = enabled
		self:Debug('UpdateCastbarDisplay', enabled, event, name)
		if enabled then
			self:EnableElement('Castbar')
		else
			self:DisableElement('Castbar')
			self.Castbar:Hide()
		end
	end

	local function Enable(self)
		if self.Castbar and self.OptionalCastbar then
			self.Castbar.enabled = true
			self:RegisterEvent('CVAR_UPDATE', Update)
			return true
		end
	end

	local function Disable(self)
		if self.Castbar and self.OptionalCastbar then
			self:UnregisterEvent('CVAR_UPDATE', Update)
		end
	end

	oUF:AddElement('OptionalCastbar', Update, Enable, Disable)
end

local function InitFrame(settings, self)
	local unit = self.unit

	self:SetAttribute('initial-width', settings['initial-width'])
	self:SetAttribute('initial-height', settings['initial-height'])

	self:RegisterForClicks("AnyUp")
	self:SetAttribute("type", "target")

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
		local importantDebuff = self:SpawnAuraIcon(portrait)
		importantDebuff:SetAllPoints(portrait)
		local stack = importantDebuff.Stack
		stack:ClearAllPoints()
		stack:SetPoint("BOTTOMRIGHT", importantDebuff, -1, 1)
		importantDebuff.Stack:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
		self:AddAuraIcon(importantDebuff, "ImportantDebuff")

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
	--health.frequentUpdates = true	-- let LibQuickHealth handle this
	self.Health = health

	-- Name
	local name = SpawnText(health, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN)
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", TEXT_MARGIN)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, (unit == "player" or unit == "pet") and "[name]" or "[name][ <>status<>]")
	self.Name = name

	-- Incoming heals
	if oUF.HasIncomingHeal then
		--local incomingHeal = CreateFrame("StatusBar", nil, self)
		--incomingHeal:SetPoint("BOTTOMRIGHT", health)
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

	-- Power bar
	if not settings.noPower then
		local power = SpawnStatusBar(self, false, "TOPLEFT", health, "BOTTOMLEFT", 0, -GAP)
		power:SetPoint('RIGHT', barContainer)
		power.colorDisconnected = true
		power.colorPower = true
		power.frequentUpdates = true
		power.PostUpdate = Power_PostUpdate
		self.Power = power

		if unit == "player" and SetupAltPower then
			local altPower = SetupAltPower(self)
			altPower:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -GAP)
			altPower:SetPoint('RIGHT', barContainer)
			altPower:HookScript('OnShow', UpdateLayout)
			altPower:HookScript('OnHide', UpdateLayout)
			self.AltPower = altPower
		end

		-- Unit level and class (or creature family)
		if unit ~= "player" and unit ~= "pet" then
			local classif = SpawnText(power, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
			classif:SetPoint("BOTTOMLEFT", power)
			classif:SetPoint("RIGHT", power.Text, "LEFT")
			self:Tag(classif, "[smartlevel][ >smartclass<]")
		end

		-- Casting Bar
		if unit == 'pet' or unit == 'target' or unit == 'focus' then
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
		threatBar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -FRAME_MARGIN)
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

	-- Assigned/guessed raid/party icons, if we have a portrait
	if self.Portrait then
		self.RoleIcon = SpawnTexture(indicators, 16)
		self.RoleIcon:SetPoint("CENTER", self.Portrait, "TOP"..right)
		self.RoleIcon.noRaidTarget = true
	end

	-- Raid target icon
	self.RaidIcon = SpawnTexture(indicators, 16)
	self.RaidIcon:SetPoint("CENTER", barContainer)

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
	local buffs, debuffs
	if unit == "pet" then
		buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, FRAME_MARGIN)
		buffs.initialAnchor = "BOTTOMLEFT"
		buffs['growth-x'] = "RIGHT"
		buffs['growth-y'] = "UP"

	elseif unit == "target" or unit == "focus" then
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
		self.Buffs = buffs
	end
	if debuffs then
		debuffs.size = AURA_SIZE
		debuffs.num = 12
		debuffs:SetWidth(AURA_SIZE * 12)
		debuffs:SetHeight(AURA_SIZE)
		debuffs.CustomFilter = Debuff_CustomFilter
		debuffs.SetPosition = Auras_SetPosition
		debuffs.PostCreateIcon = Auras_PostCreateIcon
		self.Debuffs = debuffs
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
		xpBar.PostTextureUpdate = function() return self.ExperienceBar.ForceUpdate and self.ExperienceBar:ForceUpdate() end

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

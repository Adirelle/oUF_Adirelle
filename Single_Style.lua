--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
setfenv(1, oUF_Adirelle)

local BORDER_WIDTH = 2
local TEXT_MARGIN = 2
local GAP = 2
local FRAME_MARGIN = BORDER_WIDTH + GAP
local AURA_SIZE = 15
	
local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]],
	edgeSize = BORDER_WIDTH,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local floor = math.floor

local function smartValue(value)
	if value >= 10000000 then
		return value/1000000, "%.1fm"
	elseif value >= 10000 then
		return value/1000, "%.1fk"
	else
		return value, "%d"
	end
end

local function OnStatusBarUpdate(bar)
	local text = bar.Text
	if not text then return end
	local value, _, max = bar:GetValue(), bar:GetMinMaxValues()
	if max == 100 then
		text:SetFormattedText("%d%%", floor(value))
	elseif max == 0 then
		return text:Hide()
	else
		local curValue, curFormat = smartValue(value)
		local maxValue, maxFormat = smartValue(max)
		text:SetFormattedText("%d%% "..curFormat.."/"..maxFormat, floor(value/max*100), curValue, maxValue)
	end
	text:Show()
end

local fontPath, fontSize, fontFlags = GameFontWhiteSmall:GetFont()
local lsm = LibStub('LibSharedMedia-3.0', true)
if lsm then
	local altFont = lsm:Fetch("font", "ABF")
	if altFont then
		fontPath, fontSize, fontFlags = altFont, 12, ""
	end
end

local function SetFont(fs, size, flags)
	fs:SetFont(fontPath, size or fontSize, flags or fontFlags)
	fs:SetTextColor(1,1,1,1)
	fs:SetShadowColor(0,0,0,1)
	fs:SetShadowOffset(0.5,-0.5)
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
		bar.Text = SpawnText(bar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
		bar.Text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
		bar:SetScript('OnValueChanged', OnStatusBarUpdate)
		bar:SetScript('OnMinMaxChanged', OnStatusBarUpdate)	
	end
	if from then
		bar:SetPoint(from, anchor or self, to or from, xOffset or 0, yOffset or 0)
	end
	self:RegisterStatusBarTexture(bar)
	return bar
end

local function PostCreateAuraIcon(self, button, icons, index, debuff)
	button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.cd:SetReverse(true)
	button.cd:SetDrawEdge(true)
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

local function playerBuffFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster)
	if name then
		if icon.debuff then return true end
		icon.isPlayer = (caster == 'player' or caster == 'vehicle' or caster == 'pet')
		icon.owner = caster
		duration = tonumber(duration) or 0
		return icon.isPlayer and duration > 0 and duration < 30
	else
		icon.isPlayer, icon.owner = nil, nil
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

local _, playerClass = UnitClass('player')

local SetupAltPower
if playerClass == 'DEATHKNIGHT' then
	function SetupAltPower(self)
	
		oUF.colors.runes = oUF.colors.runes or {
			{ 1, 0, 0  },
			{ 0, 0.5, 0 },
			{ 0, 1, 1 },
			{ 0.8, 0.1, 1 },
		}

		local function UpdateRuneColor(rune)
			rune:SetStatusBarColor(unpack(oUF.colors.runes[GetRuneType(rune.index)]))
		end
	
		local GetTime = GetTime
		local function OnUpdate(rune)
			local now = GetTime()
			rune:SetValue(now)
			if now > rune.readyTime then
				rune:SetScript('OnUpdate', nil)
			end
		end

		local function RuneUpdate(self, event, index)
			local rune = self.RuneBar[index]
			if not rune then return end
			UpdateRuneColor(rune)
			local start, duration, ready = GetRuneCooldown(index)
			if not ready then
				rune.duration = duration
				rune.readyTime = start + duration
				rune:SetMinMaxValues(start, start + duration)
				rune:SetScript('OnUpdate', OnUpdate)
			else
				rune:SetScript('OnUpdate', nil)		
			end
		end
	
		local function Update(self, event, index)
			if event == 'PLAYER_ENTERING_WORLD' then
				if self.unit ~= 'player' then
					return self.RuneBar:Hide()
				else
					self.RuneBar:Show()
				end
				for index = 1, 6 do 
					RuneUpdate(self, event, index) 
				end
			else
				RuneUpdate(self, event, index) 
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

		local runeBar = CreateFrame("Frame", nil, self)
		runeBar:HookScript('OnSizeChanged', LayoutRunes)
		self.RuneBar = runeBar
		
		for index = 1, 6 do
			local rune = CreateFrame("StatusBar", nil, runeBar)
			rune.index = index
			self:RegisterStatusBarTexture(rune, UpdateRuneColor)
			runeBar[index] = rune
		end

		self:RegisterEvent('RUNE_POWER_UPDATE', Update)
		self:RegisterEvent('RUNE_TYPE_UPDATE', Update)

		RuneFrame:Hide()
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:UnregisterAllEvents()
		
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
end

local DROPDOWN_MENUS = {
	player = PlayerFrameDropDown,
	pet = PetFrameDropDown,
	target = TargetFrameDropDown,
	focus = FocusFrameDropDown,
}

local function ToggleMenu(self, unit, button, actionType)
	ToggleDropDownMenu(1, nil, DROPDOWN_MENUS[unit], self:GetName(), 0, 0) 
end

local function InitFrame(settings, self)
	local unit = self.unit
	
	self:RegisterForClicks("AnyUp")
	self:SetAttribute("type", "target");

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	if DROPDOWN_MENUS[unit] then
		self:SetAttribute("*type2", "menu");
		self.menu = ToggleMenu
	end

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)
	self:SetBackdropBorderColor(0,0,0,1)
	
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
		local portrait = CreateFrame("PlayerModel", nil, self)
		portrait:SetPoint(left)
		self.Portrait = portrait
	
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
	health.frequentUpdates = true	
	self.Health = health
	
	-- Name
	local name = SpawnText(health, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN)
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", TEXT_MARGIN)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, (unit == "player" or unit == "pet") and "[name]" or "[name][( <)status(>)]")
	
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
	
	-- Various indicators
	local indicators = CreateFrame("Frame", nil, self)
	indicators:SetAllPoints(self)
	indicators:SetFrameLevel(health:GetFrameLevel()+2)	
	self.Leader = SpawnTexture(indicators, 16, "TOP"..left)
	self.Assistant = SpawnTexture(indicators, 16, "TOP"..left)
	self.MasterLooter = SpawnTexture(indicators, 16, "TOP"..left, 16*dir)
	self.Combat = SpawnTexture(indicators, 16, "BOTTOM"..left)

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
		local cpoints = {}
		for i = 0, 4 do
			local cpoint = SpawnTexture(indicators, 8)
			cpoint:SetPoint("BOTTOM"..left, indicators, "BOTTOM"..right, FRAME_MARGIN*dir, i*9)
			cpoint:SetTexture([[Interface\AddOns\oUF_Adirelle\media\combo]])
			cpoint:SetTexCoord(3/16, 13/16, 5/16, 14/16)
			tinsert(cpoints, cpoint)
		end
		self.CPoints = cpoints
	end
	
	-- Auras
	if unit == "pet" then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, FRAME_MARGIN)
		buffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, FRAME_MARGIN)
		buffs:SetHeight(AURA_SIZE * 2)
		self.Buffs = buffs
		self.CustomAuraFilter = playerBuffFilter
	elseif unit == "target" or unit == "player" or unit == "focus" then
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

		if unit ~= "player" then
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
		else
			self.CustomAuraFilter = playerBuffFilter
		end
	end

	if self.Buffs then
		self.Buffs.size = AURA_SIZE
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end
	if self.Debuffs then
		self.Debuffs.size = AURA_SIZE
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end
	
	-- Range fading
	self.XRange = true
	
	self:HookScript('OnSizeChanged', OnSizeChanged)
	OnSizeChanged(self)	
end

local single_style = setmetatable({
	["initial-width"] = 190,
	["initial-height"] = 45,
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



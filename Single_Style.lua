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

local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\white16x16]],
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
	fontPath, fontSize = lsm:Fetch("font", "ABF"), 12
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

local function CreateStatusBarText(bar)
	bar.Text = SpawnText(bar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
	bar.Text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
	bar:SetScript('OnValueChanged', OnStatusBarUpdate)
	bar:SetScript('OnMinMaxChanged', OnStatusBarUpdate)	
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
		self.Health:SetHeight(height*0.55)
	end
	self.RaidIcon:SetWidth(height)
	self.RaidIcon:SetHeight(height)
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
		icon.isPlayer = UnitIsUnit(caster, 'player') or UnitIsUnit(caster, 'vehicle')  or UnitIsUnit(caster, 'pet')
		icon.owner = caster
		return dtype or (icon.isPlayer and duration and duration ~= 0)
	end
end

local function InitFrame(settings, self)
	local unit = self.unit

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
		barContainer:SetPoint("TOP"..left, portrait, "TOP"..right, -GAP*dir)
		barContainer:SetPoint("BOTTOM"..right)
	else
		barContainer = self
	end
	self.BarContainer = barContainer
	
	-- Health bar
	local health = CreateFrame("StatusBar", nil, self)	
	health.colorTapping = true
	health.colorDisconnected = true
	health.colorHappiness = true
	health.colorClass = true	
	health.colorSmooth = true	
	health.frequentUpdates = true	
	health:SetPoint("TOPLEFT", barContainer)
	health:SetPoint("TOPRIGHT", barContainer)
	self.Health = health
	oUF:RegisterStatusBarTexture(health)

	CreateStatusBarText(health)
	
	-- Name
	local name = SpawnText(health, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN)
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", TEXT_MARGIN)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, "[name][( )status]")
	
	-- Incoming heals
	if oUF.HasIncomingHeal then
		local incomingHeal = CreateFrame("StatusBar", nil, self)
		incomingHeal:SetAllPoints(health)
		incomingHeal:SetFrameLevel(health:GetFrameLevel()-1)
		incomingHeal.PostTextureUpdate = PostIncomingHealTextureUpdate
		oUF:RegisterStatusBarTexture(incomingHeal)

		self.IncomingHeal = incomingHeal
		self.UpdateIncomingHeal = UpdateIncomingHeal
		self.PostUpdateHealth = PostUpdateHealth
	end

	-- Power bar
	if not settings.noPower then
		local power = CreateFrame("StatusBar", nil, self)
		power.colorDisconnected = true
		power.colorPower = true
		power.frequentUpdates = true
		power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -GAP)
		CreateStatusBarText(power)
		self.Power = power
		oUF:RegisterStatusBarTexture(power)
		
		-- Unit level and class (or creature family)
		if unit ~= "player" and unit ~= "pet" then
			local classif = SpawnText(power, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN)
			classif:SetPoint("BOTTOMLEFT", power, "BOTTOMLEFT", TEXT_MARGIN)
			classif:SetPoint("RIGHT", power.Text, "LEFT")
			self:Tag(classif, "[smartlevel][( )smartclass]")
		end
	end
	
	-- Stick the last bar to the bottom of the frame
	(self.Power or self.Health):SetPoint("BOTTOMRIGHT", barContainer)
	
	-- Various indicators
	local indicators = CreateFrame("Frame", nil, self)
	indicators:SetAllPoints(self)
	indicators:SetFrameLevel(health:GetFrameLevel()+2)
	self.RaidIcon = SpawnTexture(indicators, 16)
	self.Leader = SpawnTexture(indicators, 16, "TOP"..left)
	self.Assistant = SpawnTexture(indicators, 16, "TOP"..left)
	self.MasterLooter = SpawnTexture(indicators, 16, "TOP"..left, 16*dir)
	self.Combat = SpawnTexture(indicators, 16, "BOTTOM"..left)
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
	
	-- Auras
	local aura_margin = BORDER_WIDTH + GAP
	if unit == "pet" then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, aura_margin)
		buffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, aura_margin)
		buffs:SetHeight(16 * 2)
		self.Buffs = buffs
		self.CustomAuraFilter = playerBuffFilter
	elseif unit == "target" or unit == "player" or unit == "focus" then
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOM"..right, self, "BOTTOM"..left, -aura_margin*dir, 0)
		buffs.num = 12
		buffs:SetWidth(12 * 16)
		buffs:SetHeight(16)
		buffs.onlyShowPlayer = (unit == "player")		
		buffs.showType = (unit ~= "player")
		buffs.initialAnchor = "BOTTOM"..right
		buffs['growth-x'] = left
		buffs['growth-y'] = "UP"
		self.Buffs = buffs

		if unit ~= "player" then
			local debuffs = CreateFrame("Frame", nil, self)
			debuffs:SetPoint("TOP"..right, self, "TOP"..left, -aura_margin*dir, 0)
			debuffs.num = 24
			debuffs.showType = true
			debuffs:SetWidth(12 * 16)
			debuffs:SetHeight(2 * 16)	
			debuffs.initialAnchor = "TOP"..right
			debuffs['growth-x'] = left
			debuffs['growth-y'] = "DOWN"
			self.Debuffs = debuffs
		else
			self.CustomAuraFilter = playerBuffFilter
		end
	end
	
	if self.Buffs or self.Debuffs then
		self.PostCreateAuraIcon = PostCreateAuraIcon
	end

	-- Range fading
	--[[
	self.Range = true
	self.inRangeAlpha = 1.0
	self.outsideRangeAlpha = 0.40
	--]]
	
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



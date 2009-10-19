--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
setfenv(1, oUF_Adirelle)

local GAP = 2

local floor = math.floor
local function OnStatusBarUpdate(bar)
	local text = bar.Text
	if not text then return end
	local value, _, max = bar:GetValue(), bar:GetMinMaxValues()
	if max == 100 then
		text:SetFormattedText("%d%%", floor(value))
	elseif max == 0 then
		return text:Hide()
	else
		local unit, div = "", 1
		if max >= 1000000 then
			unit, div = "m", 1000000
		elseif max >= 1000 then
			unit, div = "k", 1000
		end
		text:SetFormattedText("%d%% %.1f%s/%.1f%s", floor(value/max*100), value/div, unit, max/div, unit)
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

local function SpawnTexture(object, layer, width, height, from, to, xOffset, yOffset)
	local texture = object:CreateTexture(nil, layer)
	texture:SetWidth(width)
	texture:SetHeight(height)
	if from then
		texture:SetPoint(from, object, to or from, xOffset or 0, yOffset or 0)
	end
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
	bar.Text = SpawnText(bar, "OVERLAY", "TOPRIGHT")
	bar.Text:SetPoint("BOTTOMRIGHT")
	bar:SetScript('OnValueChanged', OnStatusBarUpdate)
	bar:SetScript('OnMinMaxChanged', OnStatusBarUpdate)	
end

local function OnSizeChanged(self, width, height)
	width = width or self:GetWidth()
	height = height or self:GetHeight()
	self.Border:SetWidth(width + 2)
	self.Border:SetHeight(height + 2)
	local portrait = self.Portrait
	if portrait then
		portrait:SetWidth(height)
		portrait:SetHeight(height)
	end
	if self.Power then
		self.Health:SetHeight((height-GAP)/2)
	end
end

local function InitFrame(settings, self)
	local unit = self.unit
	local height = self:GetAttribute('initial-height') or settings['initial-height']
	

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
	self.Border = border	
	
	local barContainer

	-- Portrait
	if not settings.noPortrait then
		barContainer = CreateFrame("Frame", nil, self)		
	
		local portrait = CreateFrame("PlayerModel", nil, self)
		portrait:SetWidth(height)
		portrait:SetHeight(height)
		self.Portrait = portrait
	
		if settings.rightPortrait then
			portrait:SetPoint("TOPRIGHT")
			barContainer:SetPoint("TOPLEFT", self)
			barContainer:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMLEFT", -GAP)
		else
			portrait:SetPoint("TOPLEFT")
			barContainer:SetPoint("BOTTOMLEFT", portrait, "BOTTOMRIGHT", GAP)
			barContainer:SetPoint("TOPRIGHT", self)
		end
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
	local name = SpawnText(health, "OVERLAY", "TOPLEFT", "TOPLEFT", 4)
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", 4)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, "[name][( )status]")
	
	--[[ Incoming heals
	if oUF.HasIncomingHeal then
		local heal = health:CreateTexture(nil, "OVERLAY")
		heal:SetTexture(0, 0.5, 0, 0.5)
		heal:SetBlendMode("BLEND")
		heal:SetPoint("TOP")
		heal:SetPoint("BOTTOM")
		heal:Hide()
		self.IncomingHeal = heal
		--self.UpdateIncomingHeal = UpdateIncomingHeal
		--self.PostUpdateHealth = PostUpdateHealth
	end	
	--]]

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
			local classif = SpawnText(power, "OVERLAY", "TOPLEFT", "TOPLEFT", 4)
			classif:SetPoint("BOTTOMLEFT", power, "BOTTOMLEFT", 4)
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
	self.RaidIcon = SpawnTexture(indicators, "OVERLAY", height, height, "CENTER")
	self.Leader = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "TOPRIGHT")
	self.Assistant = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "TOPRIGHT")
	self.MasterLooter = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "TOPRIGHT", -16)
	self.Combat = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "BOTTOMLEFT")
	if unit == "pet" then
		self.Happiness = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "BOTTOMRIGHT")
	end
	if unit == "player" then
		self.Resting = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "BOTTOMLEFT")
	end
	
	if self.Portrait then
		self.PvP = SpawnTexture(indicators, "OVERLAY", 16, 16)
		if settings.rightPortrait then
			self.PvP:SetPoint("CENTER", barContainer, "BOTTOMRIGHT")
		else
			self.PvP:SetPoint("CENTER", barContainer, "BOTTOMLEFT")
		end
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
	rightPortrait = true
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



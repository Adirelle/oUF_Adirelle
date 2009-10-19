--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
setfenv(1, oUF_Adirelle)

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

local fontPath, fontSize, fontFlags = GameFontNormalSmall:GetFont()

local function SetFont(fs, size, flags)
	fs:SetFont(fontPath, size or fontsize, flags or fontFlags)
	fs:SetFontColor(1,1,1,1)
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
	if from then
		text:SetPoint(from, object, to or from, xOffset or 0, yOffset or 0)
	end
	return text
end

local function CreateStatusBarText(bar)
	bar.Text = SpawnText(bar, "OVERLAY", "RIGHT")
	bar:SetScript('OnValueChanged', OnStatusBarUpdate)
	bar:SetScript('OnMinMaxChanged', OnStatusBarUpdate)	
end

local function InitFrame(settings, self)
	local unit = self.unit
	local height = self:GetAttribute('initial-height') or settings['initial-height']
	
	local leftOffset, rightOffset = 0, 0
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)
	self:SetBackdropBorderColor(0,0,0,1)

	-- Portrait
	if not settings.noPortrait then
		local portrait = CreateFrame("PlayerModel", nil, self)
		portrait:SetWidth(height)
		portrait:SetHeight(height)
		self.Portrait = portrait
	
		if settings.rightPortrait then
			portrait:SetPoint("TOPRIGHT")
			rightOffset = -1-height
		else
			portrait:SetPoint("TOPLEFT")
			leftOffset = 1+height
		end
	end
	
	-- Health bar
	local health = CreateFrame("StatusBar", nil, self)	
	health.colorTapping = true
	health.colorDisconnected = true
	health.colorHappiness = true
	health.colorClass = true	
	health.colorReaction = true	
	health.frequentUpdates = true	
	health:SetPoint("TOPLEFT", self, "TOPLEFT", leftOffset, 0)
	health:SetPoint("TOPRIGHT", self, "TOPRIGHT", rightOffset, 0)
	health:SetHeight(height / 2)
	self.Health = health
	oUF:RegisterStatusBarTexture(health)

	CreateStatusBarText(health)
	
	-- Name
	local name = SpawnText(health, "OVERLAY", "LEFT")
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
		power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
		power:SetPoint("TOPRIGHT", health, "BOTTOMRIGHT", 0, -1)
		power:SetHeight(height / 2)
		CreateStatusBarText(power)
		self.Power = power
		oUF:RegisterStatusBarTexture(power)
		
		-- Unit level and class (or creature family)
		if unit ~= "player" and unit ~= "pet" then
			local classif = SpawnText(power, "OVERLAY", "LEFT")
			self:Tag(classif, "[smartlevel][( )smartclass]")
		end
	end
	
	-- Various indicators
	local indicators = CreateFrame("Frame", self:GetName().."Indicator", self)
	indicators:SetAllPoints(self)
	indicators:SetFrameLevel(health:GetFrameLevel()+2)
	self.RaidIcon = SpawnTexture(indicators, "OVERLAY", height, height, "CENTER")
	self.Leader = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "TOPRIGHT")
	self.Assistant = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "TOPRIGHT")
	self.MasterLooter = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "TOPRIGHT", -16)
	self.PvP = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "BOTTOMLEFT", leftOffset)
	self.Combat = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "BOTTOMLEFT")
	if unit == "pet" then
		self.Happiness = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "BOTTOMRIGHT")
	end
	if unit == "player" then
		self.Resting = SpawnTexture(indicators, "OVERLAY", 16, 16, "CENTER", "BOTTOMLEFT")
	end

	-- Range fading
	--[[
	self.Range = true
	self.inRangeAlpha = 1.0
	self.outsideRangeAlpha = 0.40
	--]]
end

single_style = setmetatable(
	{
		["initial-width"] = 190,
		["initial-height"] = 45,
	}, {
		__call = InitFrame,
	}
)

oUF:RegisterStyle("Adirelle_Single", single_style)


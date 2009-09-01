--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local WIDTH = 80
local BORDER_WIDTH = 1
local ICON_SIZE = 16
local HEIGHT = 20
local SPACING = 2

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
local lsm = LibStub('LibSharedMedia-3.0', true)

local statusbarTexture = lsm and lsm:Fetch("statusbar", false) or [[Interface\TargetingFrame\UI-StatusBar]]

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\white16x16]], 
	edgeSize = BORDER_WIDTH,	insets = {left = BORDER_WIDTH, right = BORDER_WIDTH, top = BORDER_WIDTH, bottom = BORDER_WIDTH},
}

local UnitClass, UnitIsConnected = UnitClass, UnitIsConnected
local UnitIsDeadOrGhost, UnitName = UnitIsDeadOrGhost, UnitName
local strformat = string.format

local function UpdateHealth(self, event, unit, bar, current, max)
	local isDisconnected, isDead = not UnitIsConnected(unit), UnitIsDeadOrGhost(unit)
	if isDisconnected or isDead then
		bar:SetValue(max)
	end
	
	local r, g, b
	if isDisconnected then
		r, g, b = unpack(self.colors.disconnected)
	else
		r, g, b = unpack(self.colors.class[select(2, UnitClass(unit))])
	end
	bar.bg:SetVertexColor(r, g, b, 1)
	
	local hpPercent = current/max
	if isDead then
		self.Name:SetText("MORT")
	elseif isDisconnected or hpPercent > 0.9  then
		self.Name:SetText(UnitName(unit))
	else
		self.Name:SetText(strformat("-%.1fk", (max-current)/1000))
	end
	if hpPercent < 0.4 then
		self.Name:SetTextColor(1,0,0)
	else
		self.Name:SetTextColor(r, g, b)
	end
end

local function UpdateTextures(self)
	self.Health:SetStatusBarTexture(statusbarTexture)
	self.Health:SetStatusBarColor(0, 0, 0, 0.75)
	self.Health.bg:SetTexture(statusbarTexture)
end

local function SpawnIcon(self)
	local	icon = CreateFrame("Frame", nil, self)
	icon:SetWidth(ICON_SIZE)
	icon:SetHeight(ICON_SIZE)
	
	local texture = icon:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints(icon)
	texture:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	texture:SetTexture(1,1,1,0)	
	icon.Texture = texture	

	local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	cooldown:SetAllPoints(texture)
	cooldown:SetReverse(true)
	icon.Cooldown = cooldown

	local stack = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	stack:SetAllPoints(texture)
	stack:SetJustifyH("CENTER")
	stack:SetJustifyV("MIDDLE")
	stack:SetFont(GameFontNormal:GetFont(), 10, "OUTLINE")
	stack:SetTextColor(1, 1, 1, 1)
	icon.Stack = stack
	
	local border = CreateFrame("Frame", nil, icon)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("TOPLEFT", icon, "TOPLEFT", -BORDER_WIDTH, BORDER_WIDTH)
	border:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", BORDER_WIDTH, -BORDER_WIDTH)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	icon.Border = border
	
	return icon
end

local function TestMyAura(spellId)
	local spellName = GetSpellInfo(spellId)
	assert(spellName, "invalid spell id: "..spellId)
	return function(unit)
		local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName)
		if name and UnitIsUnit(caster, "player") then
			return texture, count, expirationTime-duration, duration, 1, 0, 0
		end
	end
end

local function InitFrame(settings, self, unit)
	self:EnableMouse(true)
	self:RegisterForClicks("anyup")
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
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

	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth

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
	border:SetPoint("TOPLEFT", self, "TOPLEFT", -BORDER_WIDTH, BORDER_WIDTH)
	border:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", BORDER_WIDTH, -BORDER_WIDTH)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border:Hide()	 
	self.Border = border
	
	--[=[
	-- ReadyCheck icon
	local rc = self:CreateTexture(nil, 'OVERLAY')
	rc:SetPoint('CENTER', self)
	rc:SetWidth(HEIGHT)
	rc:SetHeight(HEIGHT)
	rc:SetAlpha(1.0)
	rc:Hide()
	self.ReadyCheck = rc 
	--]=]
	
	local _, class = UnitClass("player")
	if class == "HUNTER" then
		local misdirection = SpawnIcon(self)
		misdirection:SetPoint("CENTER", self, "CENTER", 0, 0)
		self:AuraIcon(misdirection, TestMyAura(34477))
		
	elseif class == "DRUID" then
		local rejuv = SpawnIcon(self)
		rejuv:SetPoint("RIGHT", self, "CENTER", - SPACING * 1.5 - ICON_SIZE, 0)
		self:AuraIcon(rejuv, TestMyAura(774))

		local regrowth = SpawnIcon(self)
		regrowth:SetPoint("RIGHT", self, "CENTER", - SPACING / 2, 0)
		self:AuraIcon(regrowth, TestMyAura(8936))

		local lifebloom = SpawnIcon(self)
		lifebloom:SetPoint("LEFT", self, "CENTER", SPACING / 2, 0)
		self:AuraIcon(lifebloom, TestMyAura(33763))
	end
	
	-- Range fading
	self.Range = true
	self.inRangeAlpha = 1.0
	self.outsideRangeAlpha = 0.25
end

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

raid[1]:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
raid[1]:SetManyAttributes(
	"showParty", true,
	"showPlayer", true,
	"showSolo", true
)

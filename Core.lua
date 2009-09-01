--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
local lsm = LibStub('LibSharedMedia-3.0')

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	--edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
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

do
end

local function InitFrame(settings, self, unit)
	self:EnableMouse(true)
	self:RegisterForClicks("anyup")
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(1, 0, 0, 1)
	
	local texture = lsm:Fetch("statusbar", false)
	
	-- Health bar
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	hp:SetStatusBarTexture(texture)
	hp:SetStatusBarColor(0, 0, 0, 0.75)
	hp.frequentUpdates = true
		
	local hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	hpbg:SetAlpha(1)
	hp.bg = hpbg

	lsm.RegisterCallback(self, 'LibSharedMedia_SetGlobal', function(_, media, value)
		if media == "statusbar" then
			local texture = lsm:Fetch("statusbar", value)
			hp:SetStatusBarTexture(texture)
			hp:SetStatusBarColor(0, 0, 0, 0.75)
			hpbg:SetTexture(texture)
		end
	end)
	
	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth
	
	-- Name
	local name = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetAllPoints(self)
	name:SetJustifyH"CENTER"
	name:SetFont(GameFontNormal:GetFont(), 11)
	name:SetTextColor(1, 1, 1, 1)
	self.Name = name
	
	-- Border
	local border = self:CreateTexture(nil, "ARTWORK")
	border:SetPoint("LEFT", self, "LEFT", -1, 0)
	border:SetPoint("RIGHT", self, "RIGHT", 1, 0)
	border:SetPoint("TOP", self, "TOP", 0, 1)
	border:SetPoint("BOTTOM", self, "BOTTOM", 0, - 1)
	border:SetTexture(1, 1, 1, 1)
	border:SetAlpha(1)
	border:SetVertexColor(0, 0, 0)
	border:Hide()	 
	self.Border = border
	
	-- Range fading
	self.Range = true
	self.inRangeAlpha = 1.0
	self.outsideRangeAlpha = 0.25
end

local style = setmetatable(
	{
		["initial-width"] = 80,
		["initial-height"] = 20,
	}, {
		__call = InitFrame,
	}
)
 
oUF:RegisterStyle("Adirelle", style)
oUF:SetActiveStyle("Adirelle")

local spacing = 2
local raid = {}
for group = 1, 8 do
	local header = oUF:Spawn("header", "oUF_Raid" .. group)
	header:SetManyAttributes(
		"showRaid", true,
		"groupFilter", group,
		"point", "LEFT",
		"xOffset", spacing
	)
	if group > 1 then
		header:SetPoint("BOTTOMLEFT", raid[group - 1], "TOPLEFT", 0, spacing)
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
		"xOffset", spacing
	)
	header:SetPoint("BOTTOMLEFT", raid[1], "TOPLEFT", 0, spacing)
	header:Show()
	raid['PartyPets'] = header
end

raid[1]:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
raid[1]:SetManyAttributes(
	"showParty", true,
	"showPlayer", true,
	"showSolo", true
)

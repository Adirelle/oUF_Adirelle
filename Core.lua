--[=[
Adirelle's oUF layout - (c) 20009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
local lsm = LibStub('LibSharedMedia-3.0')
local lsmStatusBarMedia = lsm.MediaType.STATUSBAR

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	--edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local function UpdateTexture(self, event, media, value)
	if media == lsmStatusBarMedia then
		self:SetTexture(lsm:Fetch(media, value))
	end
end

local function SetupTexture(self)
	self:SetTexture(lsm:Fetch(lsmStatusBarMedia, false))
	lsm.RegisterCallback(self, 'LibSharedMedia_SetGlobal', UpdateTexture, self)
end

local function UpdateHealth(self, event, unit, bar, current, max)
	bar.bg:SetVertexColor(unpack(self.colors.class[select(2, UnitClass(unit))]))
end

local function InitFrame(settings, self, unit)
	self:EnableMouse(true)
	self:RegisterForClicks("anyup")
	--self:SetAttribute("*type2",
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0, 0)
	
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	hp.SetTexture = hp.SetStatusBarTexture
	SetupTexture(hp)
	hp:SetStatusBarColor(0, 0, 0, 0.75)
	hp.frequentUpdates = true
	
	local hpbg = hp:CreateTexture(nil, hp)
	hpbg:SetAllPoints(hp)
	hpbg:SetAlpha(1)
	SetupTexture(hpbg)
	hp.bg = hpbg

	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth
end

local style = setmetatable(
	{
		["initial-width"] = 80,
		["initial-height"] = 25,
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
		"yOffset", - 9
	)
	if group > 1 then
		header:SetPoint("BOTTOM", header[group - 1], "TOP", 0, -2)
	end
	header:Show()
	raid[group] = header
end

raid[1]:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 220)
raid[1]:SetManyAttributes(
	"showParty", true,
	"showPlayer", true,
	"showSolo", true
)

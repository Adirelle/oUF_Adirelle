--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local GetInstanceInfo = GetInstanceInfo
local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local pairs = pairs
local ipairs = ipairs

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

oUF:SetActiveStyle("Adirelle_Raid")

local HEIGHT_FULL = HEIGHT
local HEIGHT_SMALL = 20

--------------------------------------------------------------------------------
-- Anchor
--------------------------------------------------------------------------------

local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate")
anchor.Debug = function(self, ...) return Debug(self:GetName(), ...) end
anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
anchor:SetWidth(0.1)
anchor:SetHeight(0.1)

local Movable = GetLib('LibMovable-1.0')
if Movable then
	local mask = CreateFrame("Frame", nil, anchor)
	mask:SetPoint("BOTTOM")
	mask:SetWidth(SPACING * 4 + WIDTH * 5)
	mask:SetHeight(SPACING * 7 + HEIGHT_SMALL * 8)
	RegisterMovable(anchor, 'anchor', "Party/raid frames", mask)
end

--------------------------------------------------------------------------------
-- Creating group headers
--------------------------------------------------------------------------------

local headers = {}

for group = 1, 8 do
	local header = oUF:Spawn("header", "oUF_Raid" .. group)
	header.isParty = (group == 1)
	header.groupFilter = group
	header:SetManyAttributes(
		"showRaid", true,
		"groupFilter", group,
		"point", "LEFT",
		"xOffset", SPACING
	)
	header:SetScale(SCALE)
	header:SetParent(anchor)
	if group > 1 then
		header:SetPoint("BOTTOMLEFT", headers[group - 1], "TOPLEFT", 0, SPACING)
	else
		header:SetPoint("BOTTOMLEFT", anchor)
	end
	headers[group] = header
end

headers[1]:SetManyAttributes(
--@debug@--
	"showSolo", true,
--@end-debug@--
	"showParty", true,
	"showPlayer", true
)

-- Party pets
local header = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
header:SetManyAttributes(
--@debug@--
	"showSolo", true,
--@end-debug@--
	"showParty", true,
	"showPlayer", true,
	"groupFilter", 1,
	"point", "LEFT",
	"xOffset", SPACING
)
header.isPets = "party"
header.groupFilter = 1
header:SetScale(SCALE)
header:SetPoint("BOTTOMLEFT", headers[1], "TOPLEFT", 0, SPACING)
header:SetParent(anchor)
header:Hide()
headers.partypets = header

-- Raid pets
for group = 1, 2 do
	local header = oUF:Spawn("header", "oUF_Raid"..group.."Pets", "SecureGroupPetHeaderTemplate")
	header:SetManyAttributes(
		"showRaid", true,
		"showPlayer", true,
		"groupFilter", group,
		"point", "LEFT",
		"xOffset", SPACING
	)
	header.isPets = "raid"
	header.groupFilter = group
	header:SetScale(SCALE)
	header:SetParent(anchor)
	header:Hide()
	headers['raidpet'..group] = header
end
headers.raidpet1:SetPoint("BOTTOMLEFT", headers[2], "TOPLEFT", 0, SPACING)
headers.raidpet2:SetPoint("BOTTOMLEFT", headers.raidpet1, "TOPLEFT", 0, SPACING)

--------------------------------------------------------------------------------
-- Centering
--------------------------------------------------------------------------------

function anchor:UpdateWidth()
	if self.lockedWidth then return end
	if not self:CanChangeProtectedState() then 
		return self:Debug('UpdateWidth: not updating anchor width because of combat lockdown') 
	end
	local width = 0.1
	for key, header in pairs(headers) do
		if header:IsVisible() then
			width = math.max(width, header:GetWidth())
		end
	end
	if self:GetWidth() ~= width then
		self:Debug('UpdateWidth: old=', math.ceil(self:GetWidth()), 'new=', math.ceil(width))
		self:SetWidth(width)
	end
end

local UpdateAnchorWidth = function() anchor:UpdateWidth() end
for key, header in pairs(headers) do
	header:HookScript('OnShow', UpdateAnchorWidth)
	header:HookScript('OnHide', UpdateAnchorWidth)
	header:HookScript('OnSizeChanged', UpdateAnchorWidth)
end

--------------------------------------------------------------------------------
-- Header visibility
--------------------------------------------------------------------------------

-- group size = { header1Key = header1visibility, ... }
local VISIBILITIES = {
	[1] = { true, partypets = true },
	[5] = { true, partypets = true },
	[10] = { true, true, raidpet1 = true, raidpet2 = true },
	[15] = { true, true, true },
	[20] = { true, true, true, true },
	[25] = { true, true, true, true, true },
	[40] = { true, true, true, true, true, true, true, true },
}

-- Size boundaries for "free" groups, depending on the highest non-empty group number
local NUMGROUP_TO_LAYOUT = { 5, 10, 15, 20, 25, 40, 40, 40 }

-- Zone-based layouts (mainly PvP zones)
local ZONE_LAYOUTS = {
	LakeWintergrasp = 40,
	AlteracValley = 40,
	IsleofConquest = 40,
	ArathiBasin = 15,
	NetherstormArena = 15,
	StrandoftheAncients = 15,
	WarsongGulch = 10,
}

-- Get the better layout type
local function GetLayoutType()
	local name, instanceType, _, _, maxPlayers = GetInstanceInfo()
	if instanceType == 'arena' or instanceType == 'party' then
		return 5
	elseif type(maxPlayers) == "number" and maxPlayers > 0 then
		return NUMGROUP_TO_LAYOUT[math.ceil(maxPlayers / 5)]
	elseif GetNumRaidMembers() > 0 then
		local zoneLayout = ZONE_LAYOUTS[GetMapInfo() or ""]
		if zoneLayout then
			return zoneLayout
		end
		local maxGroup = 1
		for index = 1, GetNumRaidMembers() do
			local _, _, subGroup = GetRaidRosterInfo(index)
			maxGroup = math.max(maxGroup, subGroup)
		end
		return NUMGROUP_TO_LAYOUT[maxGroup]
	elseif GetNumPartyMembers() > 0 then
		return 5
	end
	return 1
end

local function GetWantedHeight(layout)
	return GetPlayerRole() == "healer" and layout < 40 and HEIGHT_FULL or HEIGHT_SMALL
end

function anchor:ApplyHeight()
	local height = self.wantedHeight
	if self.currentHeight == height then return end
	if not self:CanChangeProtectedState() then 
		return self:Debug('ApplyHeight: not updating height because of combat lockdown') 
	end
	self:Debug('ApplyHeight: changing height', 'old:', self.currentHeight, 'new:', height)
	self.currentHeight = height
	self.lockedWidth = nil
	for key, header in pairs(headers) do
		for i = 1, 5 do
			local unitframe = header:GetAttribute('child'..i)
			if unitframe and unitframe:GetHeight() ~= height then
				unitframe:SetAttribute('initial-height', height)
				unitframe:SetHeight(height)
			end
		end
		if header:GetAttribute('minHeight') ~= height then
			header:SetAttribute('minHeight', height)
		end
		if header:GetHeight() ~= height then
			header:SetHeight(height)
		end
	end
	self.lockedWidth = nil
end

function anchor:ApplyVisbility()
	if self.currentLayout == self.wantedLayout then return end
	if not self:CanChangeProtectedState() then 
		return self:Debug('ApplyVisbility: not updating layout because of combat lockdown') 
	end
	self:Debug('ApplyVisbility: changing raid layout', 'old:', self.currentLayout, 'new:', self.wantedLayout)
	self.currentLayout = self.wantedLayout
	local groups = VISIBILITIES[self.currentLayout]
	self.lockedWidth = true
	for key, header in pairs(headers) do
		if groups[key] then
			if not header:IsShown() then
				self:Debug("Showing", header:GetName())
				header:Show()
			end
		else
			if header:IsShown() then
				self:Debug("Hiding", header:GetName())
				header:Hide()
			end
		end
	end
	self.lockedWidth = nil
end

function anchor:UpdateLayout(event)
	self.wantedLayout = GetLayoutType()
	self.wantedHeight = GetWantedHeight(self.wantedLayout)
	self:ApplyVisbility()
	self:ApplyHeight()
	self:UpdateWidth()
end

-- Update on load
anchor:UpdateLayout('load')

-- Register events
anchor:SetScript('OnEvent', anchor.UpdateLayout)
anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')
anchor:RegisterEvent('PARTY_MEMBERS_CHANGED')
anchor:RegisterEvent('PLAYER_REGEN_ENABLED')

-- Update on role change (mainly height actually)
RegisterPlayerRoleCallback(function()
	anchor:UpdateLayout('OnPlayerRoleChanged')
end)


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

local ANCHOR_BORDER_WIDTH = 0
local RAID40_HEIGHT = 20

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

oUF:SetActiveStyle("Adirelle_Raid")

-- Raid anchor
local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate")
anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
anchor:SetWidth(ANCHOR_BORDER_WIDTH * 2 + SPACING * 4 + WIDTH * 5)
anchor:SetHeight(0.1)

-- Header tables
local headers = {}

-- Raid groups
for group = 1, 8 do
	local header = oUF:Spawn("header", "oUF_Raid" .. group)
	header.isParty = (group == 1)
	header:SetManyAttributes("showRaid", true, "groupFilter", group, "point", "LEFT", "xOffset", SPACING)
	header:SetScale(SCALE)
	header:SetParent(anchor)
	if group > 1 then
		header:SetPoint("BOTTOMLEFT", headers[group - 1], "TOPLEFT", 0, SPACING)
	else
		header:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT")
	end
	headers[group] = header
end
headers[1]:SetManyAttributes("showParty", true, "showPlayer", true)

-- Party pets
local header = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
header:SetManyAttributes("showParty", true, "showRaid", true, "showPlayer", true, "groupFilter", 1, "point", "LEFT", "xOffset", SPACING)
header.isPets = true
header:SetScale(SCALE)
header:SetPoint("BOTTOMLEFT", headers[1], "TOPLEFT", 0, SPACING)
header:SetParent(anchor)
headers.partypets = header

-- Raid pets
for group = 1, 2 do
	local header = oUF:Spawn("header", "oUF_Raid"..group.."Pets", "SecureGroupPetHeaderTemplate")
	header:SetManyAttributes("showRaid", true, "groupFilter", group, "point", "LEFT", "xOffset", SPACING)
	header.isPets = true
	header:SetScale(SCALE)
	header:SetParent(anchor)
	header:SetPoint("BOTTOMLEFT", headers[group+1], "TOPLEFT", 0, SPACING)
	headers['raidpet'..group] = header
end

RegisterStateDriver(headers[1], "visibility", "[nogroup:party] hide; show")
RegisterStateDriver(headers[2], "visibility", "[@raid6,exists] show; hide")
RegisterStateDriver(headers[3], "visibility", "[@raid11,exists] show; hide")
RegisterStateDriver(headers[4], "visibility", "[@raid16,exists] show; hide")
RegisterStateDriver(headers[5], "visibility", "[@raid21,exists] show; hide")
RegisterStateDriver(headers[6], "visibility", "[@raid26,exists] show; hide")
RegisterStateDriver(headers[7], "visibility", "[@raid31,exists] show; hide")
RegisterStateDriver(headers[8], "visibility", "[@raid36,exists] show; hide")

RegisterStateDriver(headers.partypets, "visibility", "[@raid6,exists] hide; [group:party] show; hide")
RegisterStateDriver(headers.raidpet1, "visibility", "[@raid11,exists] hide; [@raid6,exists] show; hide")
RegisterStateDriver(headers.raidpet2, "visibility", "[@raid11,exists] hide; [@raid6,exists] show; hide")

--@debug@
headers[1]:SetAttribute("showSolo", true)
headers.partypets:SetAttribute("showSolo", true)
RegisterStateDriver(headers[1], "visibility", "show")
RegisterStateDriver(headers.partypets, "visibility", "[@raid6,exists] hide; show")
--@end-debug@

-- State driver to dynamically adjust position and height
local driver = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")

-- Position updating
driver:SetFrameRef('anchor', anchor)
driver:SetAttribute('_onstate-width', [[ self:GetFrameRef('anchor'):SetWidth(newstate) ]])
RegisterStateDriver(driver, "width", 
	("[@raid6, exists][@party4, exists] %d; [@party3, exists] %d; [@party2, exists] %d; [@party1, exists] %d; %d")
	:format(WIDTH * 5 + SPACING * 4, WIDTH * 4 + SPACING * 3, WIDTH * 3 + SPACING * 2, WIDTH * 2 + SPACING,	WIDTH)
)

-- Height updating
if HEIGHT ~= RAID40_HEIGHT then
	local numHeaders = 0
	for _, header in pairs(headers) do
		numHeaders = numHeaders + 1
		driver:SetFrameRef('header'..numHeaders, header)
	end
	driver:Execute([[numHeaders = ]]..numHeaders)
	driver:SetAttribute('_onstate-height', [[
		local height = newstate
		for i = 1, numHeaders do
			local header = self:GetFrameRef('header'..i)
			header:SetAttribute('initial-height', height)
			header:SetAttribute('minHeight', height)
			header:SetHeight(height)
			for i = 1, 5 do
			  local child = header:GetFrameRef('child'..i)
			  if child then
			  	child:SetHeight(height)
			  end
			end
		end
	]])	
	RegisterStateDriver(driver, "height", "[@raid26,exists] "..RAID40_HEIGHT.."; "..HEIGHT)
end

local libmovable = GetLib('LibMovable-1.0')
if libmovable then
	local mask = CreateFrame("Frame", nil, anchor)
	mask:SetPoint("BOTTOM")
	mask:SetWidth(SPACING * 4 + WIDTH * 5)
	mask:SetHeight(SPACING * 7 + 20 * 8 + ANCHOR_BORDER_WIDTH * 2)
	RegisterMovable(anchor, 'anchor', "Party/raid frames", mask)
end


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

-- Raid anchor
local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate")
local ANCHOR_BORDER_WIDTH = 0
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
		header:SetPoint("BOTTOM", headers[group - 1], "TOP", 0, SPACING)
	else
		header:SetPoint("BOTTOM", anchor, "TOP")
	end
	headers[group] = header
end
headers[1]:SetManyAttributes("showParty", true, "showPlayer", true)

-- Party pets
local header = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
header:SetManyAttributes("showParty", true, "showRaid", true, "showPlayer", true, "groupFilter", 1, "point", "LEFT", "xOffset", SPACING)
header.isPets = true
header:SetScale(SCALE)
header:SetPoint("BOTTOM", headers[1], "TOP", 0, SPACING)
header:SetParent(anchor)
headers.partypets = header

-- Raid pets
for group = 1, 2 do
	local header = oUF:Spawn("header", "oUF_Raid"..group.."Pets", "SecureGroupPetHeaderTemplate")
	header:SetManyAttributes("showRaid", true, "groupFilter", group, "point", "LEFT", "xOffset", SPACING)
	header.isPets = true
	header:SetScale(SCALE)
	header:SetParent(anchor)
	headers['raidpet'..group] = header
end
headers.raidpet1:SetPoint("BOTTOM", headers[2], "TOP", 0, SPACING)
headers.raidpet2:SetPoint("BOTTOM", headers.raid1, "TOP", 0, SPACING)

RegisterStateDriver(headers[1], "visibility", "[nogroup:party] hide; show")
RegisterStateDriver(headers[2], "visibility", "[@raid6,exists] show; hide")
RegisterStateDriver(headers[3], "visibility", "[@raid11,exists] show; hide")
RegisterStateDriver(headers[4], "visibility", "[@raid11,exists] show; hide")
RegisterStateDriver(headers[5], "visibility", "[@raid11,exists] show; hide")
RegisterStateDriver(headers[6], "visibility", "[@raid26,exists] show; hide")
RegisterStateDriver(headers[7], "visibility", "[@raid26,exists] show; hide")
RegisterStateDriver(headers[8], "visibility", "[@raid26,exists] show; hide")

RegisterStateDriver(headers.partypets, "visibility", "[nogroup:party] hide; show")
RegisterStateDriver(headers.raidpet1, "visibility", "[@raid11,exists] hide; [@raid6,exists] show; hide")
RegisterStateDriver(headers.raidpet2, "visibility", "[@raid11,exists] hide; [@raid6,exists] show; hide")

--@debug@
headers[1]:SetAttribute("showSolo", true)
headers.partypets:SetAttribute("showSolo", true)
RegisterStateDriver(headers[1], "visibility", "show")
RegisterStateDriver(headers.partypets, "visibility", "show")
--@end-debug@

-- Height update
if HEIGHT ~= 20 then
	local driver = CreateFrame("Frame", nil, nil, "SecureHandlerStateTemplate")
	driver:Execute([[headers = newtable()]])
	for _, header in pairs(headers) do
		driver:SetFrameRef('header', header)
		driver:Execute([[	tinsert(headers, self:GetFrameRef('header')) ]])
	end
	driver:SetAttribute('_onstate-height', [[
		local height = newstate
		for _, header in pairs(headers) do
			control:RunFor(header, [=[
			  local height = ...
				self:SetAttribute('initial-height', height)
				self:SetHeight(height)
				for i = 1, 5 do
				  local child = self:GetFrameRef('child'..i)
				  if child then
				  	child:SetHeight(height)
				  end
				end
			]=], height)
		end
	]])	
	RegisterStateDriver(driver, "height", "[@raid26,exists] 20; "..HEIGHT)	
end

local libmovable = GetLib('LibMovable-1.0')
if libmovable then
	local mask = CreateFrame("Frame", nil, anchor)
	mask:SetPoint("BOTTOM")
	mask:SetWidth(SPACING * 4 + WIDTH * 5)
	mask:SetHeight(SPACING * 7 + 20 * 8 + ANCHOR_BORDER_WIDTH * 2)
	RegisterMovable(anchor, 'anchor', "Party/raid frames", mask)
end


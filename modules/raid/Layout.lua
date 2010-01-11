--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local LibStub = LibStub
local GetInstanceInfo = GetInstanceInfo
local GetNumRaidMembers = GetNumRaidMembers
local GetNumPartyMembers = GetNumPartyMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local pairs = pairs
local ipairs = ipairs

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

local LAYOUTS = {
	[1] = { '1', pets = "party" },
	[5] = { '1', pets = "party" },
	[10] = { '1', '2', pets = "raid" },
	[15] = { '1', '2', '3' },
	[20] = { '1', '2', '3', '4' },
	[25] = { '1', '2', '3', '4', '5' },
	[40] = { '1', '2', '3', '4', '5', '6', '7', '8', height = 20 },
}

local LAYOUTS_SIZES = { 1, 5, 10, 15, 20, 25 }

local BATTLE_GROUND_LAYOUTS = {
	AlteracValley = 40,
	IsleofConquest = 40,
	ArathiBasin = 15,
	NetherstormArena = 15,
	StrandoftheAncients = 15,
	WarsongGulch = 10,
}

local RAID_LAYOUTS = {
	[RAID_DIFFICULTY_10PLAYER] = 10,
	[RAID_DIFFICULTY_10PLAYER_HEROIC] = 10,
	[RAID_DIFFICULTY_20PLAYER] = 20,
	[RAID_DIFFICULTY_25PLAYER] = 25,
	[RAID_DIFFICULTY_25PLAYER_HEROIC] = 25,
	[RAID_DIFFICULTY_40PLAYER] = 40,
}

oUF:SetActiveStyle("Adirelle_Raid")

-- Raid anchor
local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate")
local ANCHOR_BORDER_WIDTH = 0
anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
anchor:SetHeight(0.1)

-- Raid groups
local headers = {}
local petHeaders = {}

for group = 1, 8 do
	local header = oUF:Spawn("header", "oUF_Raid" .. group)
	header.isParty = (group == 1)
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
		header:SetPoint("BOTTOMLEFT", anchor, ANCHOR_BORDER_WIDTH, ANCHOR_BORDER_WIDTH)
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

do
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
	header.petGroupFilter = 1
	header:SetScale(SCALE)
	header:SetPoint("BOTTOMLEFT", headers[1], "TOPLEFT", 0, SPACING)
	header:SetParent(anchor)
	header:Hide()
	petHeaders.party = header
	
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
		header.petGroupFilter = group
		header:SetScale(SCALE)
		header:SetParent(anchor)
		header:Hide()
		petHeaders['raid'..group] = header
	end
	petHeaders.raid1:SetPoint("BOTTOMLEFT", headers[2], "TOPLEFT", 0, SPACING)
	petHeaders.raid2:SetPoint("BOTTOMLEFT", petHeaders.raid1, "TOPLEFT", 0, SPACING)
end

local function GetLayoutType()
	local name, instanceType, _, difficulty = GetInstanceInfo()
	if instanceType == 'arena' or instanceType == 'party' then
		return 5
	elseif instanceType == 'pvp' then
		return BATTLE_GROUND_LAYOUTS[GetMapInfo()]
	elseif instanceType == 'raid' then
		return RAID_LAYOUTS[difficulty]
	elseif GetNumRaidMembers() > 0 then
		local maxGroup = 1
		for index = 1, GetNumRaidMembers() do
			local _, _, subGroup = GetRaidRosterInfo(index)
			maxGroup = math.max(maxGroup, subGroup)
		end
		local num = 5 * maxGroup
		for i, size in ipairs(LAYOUTS_SIZES) do
			if num <= size then
				return size
			end
		end
		return 40
	elseif GetNumPartyMembers() > 0 then
		return 5
	end
	return 1
end

local lastLayoutType, lastNumColumns

local function SetHeaderLayout(header, filter, height)
	if filter then	
		for i = 1, 5 do
			local frame = _G[header:GetName().."UnitButton"..i]
			if frame then
				frame:SetAttribute('initial-height', height)
				frame:SetHeight(height)
			end
		end
		header:Show()	
		header:SetAttribute('groupFilter', filter)
	else
		header:SetAttribute('groupFilter', '')
		header:Hide()		
	end
end

local function ApplyRaidLayout(layoutType)
	local layout = layoutType and LAYOUTS[layoutType]
	if layout then
		local height = layout.height or HEIGHT
		raid_style['initial-height'] = height
		for _, header in next, petHeaders do
			SetHeaderLayout(header, (header.isPets == layout.pets) and header.petGroupFilter, height)
		end
		for group = 1, 8 do
			SetHeaderLayout(headers[group], layout[group], height)
		end
	else
		print('No data for layout', layoutType)
	end
end

local updateFrame = CreateFrame("Frame")
updateFrame:Hide()

local dirtyLayout, dirtyPosition

local function OnUpdate()
	if not InCombatLockdown() then
		if dirtyLayout then
			dirtyLayout = nil
			local layoutType = GetLayoutType()
			if layoutType ~= lastLayoutType then
				lastLayoutType = layoutType
				ApplyRaidLayout(layoutType)
			end
		end
		if dirtyPosition then
			dirtyPosition = nil
			local width = 0, 0, 0
			for _, header in pairs(headers) do
				if header:IsVisible() then
					width = math.max(width, header:GetWidth())
				end
			end
			anchor:SetWidth(width + ANCHOR_BORDER_WIDTH * 2)
		end
	end
	updateFrame:Hide()
end

local function CheckLayout()
	dirtyLayout = true
	updateFrame:Show()
end

local function CheckPosition()
	dirtyPosition = true
	updateFrame:Show()
end

updateFrame:SetScript('OnUpdate', OnUpdate)
updateFrame:SetScript('OnEvent', CheckLayout)
updateFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
updateFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
updateFrame:RegisterEvent('PARTY_MEMBERS_CHANGED')

for _, header in pairs(headers) do
	header:HookScript('OnShow', CheckPosition)
	header:HookScript('OnHide', CheckPosition)
	header:HookScript('OnSizeChanged', CheckPosition)
end

for _, header in pairs(petHeaders) do
	header:HookScript('OnShow', CheckPosition)
	header:HookScript('OnHide', CheckPosition)
	header:HookScript('OnSizeChanged', CheckPosition)
end

local libmovable = LibStub and LibStub('LibMovable-1.0', true)
if libmovable then
	local mask = CreateFrame("Frame", nil, anchor)
	mask:SetPoint("BOTTOM")
	mask:SetWidth(SPACING * 4 + WIDTH * 5)
	mask:SetHeight(SPACING * 7 + LAYOUTS[40].height * 8 + ANCHOR_BORDER_WIDTH * 2)
	RegisterMovable(anchor, 'anchor', "Party/raid frames", mask)
end

CheckLayout()


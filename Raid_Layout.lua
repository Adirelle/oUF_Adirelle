--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
setfenv(1, oUF_Adirelle)

local LAYOUTS = {
	[1] = { '1', pets = true },
	[5] = { '1', pets = true },
	[10] = { '1', '2' },
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

-- Raid groups
local raid = {}
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
	if group > 1 then
		header:SetPoint("BOTTOMLEFT", raid[group - 1], "TOPLEFT", 0, SPACING)
	end
	header:Show()
	raid[group] = header
end

raid[1]:SetManyAttributes(
	"showParty", true,
	"showPlayer", true,
	"showSolo", true
)

do
	-- Party pets
	local header = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
	header:SetManyAttributes(
		"showParty", true,
		"showPlayer", true,
		"showSolo", true,
		"groupFilter", 1,
		"point", "LEFT",
		"xOffset", SPACING
	)
	header.isPets = true
	header:SetScale(SCALE)
	header:SetPoint("BOTTOMLEFT", raid[1], "TOPLEFT", 0, SPACING)
	header:Show()
	raid['PartyPets'] = header
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

function oUF:SetRaidLayout(layoutType)
	local layout = layoutType and LAYOUTS[layoutType]
	if layout then
		if layout.pets then
			raid.PartyPets:Show()
		else
			raid.PartyPets:Hide()
		end
		local height = layout.height or HEIGHT
		raid_style['initial-height'] = height
		for groupNum = 1, 8 do
			local group, filter = raid[groupNum], layout[groupNum]
			if filter then
				group:SetAttribute('groupFilter', filter)
				group:Show()
				for i = 1, 5 do
					local frame = _G[group:GetName().."UnitButton"..i]
					if frame then
						frame:SetAttribute('initial-height', height)
						frame:SetHeight(height)
					end
				end
			else
				group:SetAttribute('groupFilter', '')
				group:Hide()
			end
		end
	else
		print('No data for layout', layoutType)
	end
end

local function UpdateLayout(...)
	if InCombatLockdown() then return end
	local layoutType = GetLayoutType()
	if layoutType ~= lastLayoutType then
		lastLayoutType = layoutType
		oUF:SetRaidLayout(layoutType)
	end
	local numColumns = 1 + GetNumPartyMembers()
	for name, header in pairs(raid) do
		if header:IsVisible() then
			local n = 0
			for i = 1, 5 do
				local frame = header:GetAttribute('child'..i)
				if frame and frame:IsVisible() then
					n = n + 1
				end
			end
			numColumns = math.max(numColumns, n)
		end
	end
	if lastNumColumns ~= numColumns then
		lastNumColumns = numColumns
		local width = WIDTH * numColumns + SPACING * (numColumns - 1)
		local header = raid[1]
		local scale = header:GetScale() or 1.0
		header:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", -width/2/scale, 230/scale)
	end
end

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript('OnEvent', UpdateLayout)
updateFrame:RegisterEvent('PARTY_MEMBERS_CHANGED')
updateFrame:RegisterEvent('VARIABLES_LOADED')
updateFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
updateFrame:RegisterEvent('PLAYER_ENTERING_WORLD')


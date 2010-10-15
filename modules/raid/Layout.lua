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

oUF:Factory(function()

	oUF:SetActiveStyle("Adirelle_Raid")

	local WIDTH = oUF_Adirelle.WIDTH
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
	-- Helper
	--------------------------------------------------------------------------------

	local function SpawnHeader(name, template, visbility, group, ...)
		local header = oUF:SpawnHeader(
			name, 
			template,
			visbility,
			"groupFilter", group,
			"point", "LEFT",
			"xOffset", SPACING,			
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				self:SetWidth(]]..WIDTH..[[)
				self:SetHeight(]]..HEIGHT..[[)
				RegisterUnitWatch(self)
			]],
			...
		)
		header.groupFilter = group
		header:SetScale(SCALE)
		header:SetSize(0.1, 0.1)
		header:SetParent(anchor)
		return header
	end

	--------------------------------------------------------------------------------
	-- Creating group headers
	--------------------------------------------------------------------------------

	local visibilities = {
		--@debug@--
		[1] = "solo,party,raid",
		--@end-debug@--
		--[===[@non-debug@
		[1] = "party,raid",
		--@end-non-debug@]===]	
		[2] = "raid10",
		[3] = "raid25",
		[4] = "raid25",
		[5] = "raid25",
		[6] = "raid40",
		[7] = "raid40",
		[8] = "raid40",
	}
	
	local headers = {}

	for group = 1, 8 do
		local isParty = (group == 1) or nil
		local header = SpawnHeader(
			"oUF_Raid"..group, -- Name
			nil, -- Use default template (SecureGroupHeaderTemplate)
			visibilities[group],
			group,
			--@debug@--
			"showSolo", isParty,
			--@end-debug@--
			"showPlayer", isParty,
			"showParty", isParty,
			"showRaid", true
		)
		header.isParty = isParty
		if group > 1 then
			header:SetPoint("BOTTOMLEFT", headers[group - 1], "TOPLEFT", 0, SPACING)
		else
			header:SetPoint("BOTTOMLEFT", anchor)
		end
		headers[group] = header
	end

	-- Party pets
	local header = SpawnHeader(
		"oUF_PartyPets",
		"SecureGroupPetHeaderTemplate",
		"custom [group:raid] hide; show",
		1,
	--@debug@--
		"showSolo", true,
	--@end-debug@--
		"showParty", true,
		"showPlayer", true
	)
	header.isPets = "party"
	header:SetPoint("BOTTOMLEFT", headers[1], "TOPLEFT", 0, SPACING)
	headers.partypets = header

	-- Raid pets
	for group = 1, 2 do
		local header = SpawnHeader(
			"oUF_Raid"..group.."Pets",
			"SecureGroupPetHeaderTemplate",
			"custom [@raid11,exists] hide; [group:raid] show; hide",
			group,
			"showRaid", true,
			"showPlayer", true
		)
		header.isPets = "raid"
		headers['raidpet'..group] = header
	end
	headers.raidpet1:SetPoint("BOTTOMLEFT", headers[2], "TOPLEFT", 0, SPACING)
	headers.raidpet2:SetPoint("BOTTOMLEFT", headers.raidpet1, "TOPLEFT", 0, SPACING)
	
end)

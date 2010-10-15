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

	local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate,SecureHandlerStateTemplate")
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
				local anchor = header:GetParent()
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				self:SetWidth(]]..WIDTH..[[)
				self:SetHeight(header:GetAttribute('initial-height'))
				RegisterUnitWatch(self)
			]],
			"initial-height", HEIGHT_SMALL,
			...
		)
		header:SetScale(SCALE)
		header:SetSize(0.1, HEIGHT)
		header:SetParent(anchor)
		return header
	end

	--------------------------------------------------------------------------------
	-- Creating group headers
	--------------------------------------------------------------------------------

	local headers = {}

	for group = 1, 8 do
		local isParty = (group == 1) or nil
		local header = SpawnHeader(
			"oUF_Raid"..group,
			"SecureGroupHeaderTemplate",
			isParty and "solo,party,raid" or "raid",
			group,
			--@debug@--
			"showSolo", isParty,
			--@end-debug@--
			"showParty", isParty,
			"showPlayer", true,
			"showRaid", true
		)
		if group > 1 then
			header:SetPoint("BOTTOM", headers[group - 1], "TOP", 0, SPACING)
		else
			header:SetPoint("BOTTOM", anchor)
		end
		headers[group] = header
	end

	-- Party pets
	local header = SpawnHeader(
		"oUF_PartyPets",
		"SecureGroupPetHeaderTemplate",
		"solo,party",
		1,
	--@debug@--
		"showSolo", true,
	--@end-debug@--
		"showPlayer", true,
		"showParty", true
	)
	header:SetPoint("BOTTOM", headers[1], "TOP", 0, SPACING)
	headers.partypets = header

	-- Raid pets
	for group = 1, 2 do
		headers['raidpet'..group] = SpawnHeader(
			"oUF_Raid"..group.."Pets",
			"SecureGroupPetHeaderTemplate",
			"custom [@raid11,noexists]show;hide",
			group,
			"showPlayer", true,
			"showParty", true,
			"showRaid", true
		)
	end
	headers.raidpet1:SetPoint("BOTTOM", headers[2], "TOP", 0, SPACING)
	headers.raidpet2:SetPoint("BOTTOM", headers.raidpet1, "TOP", 0, SPACING)

	-- Height updating
	anchor:SetAttribute('_onstate-height', [[
		local headers, units = self:GetChildList(newtable()), newtable()
		for i, header in pairs(headers) do
			header:GetChildList(units)
			header:SetHeight(newstate)
			header:SetAttribute('initial-height', newstate)
			header:SetAttribute('minHeight', newstate)
		end
		for i, unit in pairs(units) do
			if unit:GetHeight() ~= newstate then
				unit:SetHeight(newstate)
			end
		end
	]])

	RegisterPlayerRoleCallback(function(role)
		if role == 'HEALER' then
			RegisterStateDriver(anchor, 'height', format('[@raid26,exists]%d;%d', HEIGHT_SMALL, HEIGHT))
		else
			UnregisterStateDriver(anchor, 'height')
			anchor:SetAttribute('state-height', HEIGHT_SMALL)
		end
	end)

end)

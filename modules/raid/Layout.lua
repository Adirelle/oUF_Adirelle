--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF_Adirelle = oUF_Adirelle
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle namespace")

oUF:Factory(function()
	-- Fetch some globals into local namespace
	local oUF_Adirelle = oUF_Adirelle
	local GetInstanceInfo = GetInstanceInfo
	local GetNumRaidMembers = GetNumRaidMembers
	local GetNumPartyMembers = GetNumPartyMembers
	local GetRaidRosterInfo = GetRaidRosterInfo
	local pairs = pairs
	local ipairs = ipairs
	
	-- Fetch some shared variables into local namespace
	local SCALE = oUF_Adirelle.SCALE
	local SPACING = oUF_Adirelle.SPACING
	local WIDTH = oUF_Adirelle.WIDTH
	local HEIGHT_FULL = oUF_Adirelle.HEIGHT
	local GetPlayerRole = oUF_Adirelle.GetPlayerRole

	local HEIGHT_SMALL = 20
	
	--------------------------------------------------------------------------------
	-- Anchor
	--------------------------------------------------------------------------------

	local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate,SecureHandlerStateTemplate")
	anchor.Debug = oUF_Adirelle.Debug
	anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
	anchor:SetSize(SPACING * 4 + WIDTH * 5, SPACING * 7 + HEIGHT_SMALL * 8)

	anchor:SetAttribute('heightSmall', HEIGHT_SMALL)
	anchor:SetAttribute('heightFull', HEIGHT)

	oUF_Adirelle.RegisterMovable(anchor, 'anchor', "Party/raid frames")

	--------------------------------------------------------------------------------
	-- Helper
	--------------------------------------------------------------------------------

	local function SpawnHeader(name, template, ...)
		local header = oUF:SpawnHeader(
			name,
			template,
			nil,
			"point", "LEFT",
			"xOffset", SPACING,
			"sortMethod", "INDEX",
			"groupBy", "GROUP",
			"groupingOrder", "1,2,3,4,5,6,7,8",
			"unitsPerColumn", 5,
			"columnSpacing", SPACING,
			"columnAnchorPoint", "BOTTOM",
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				self:SetWidth(]]..WIDTH..[[)
				self:SetHeight(header:GetAttribute('unitHeight'))
			]],
			"unitHeight", HEIGHT_SMALL,
			"minHeight", HEIGHT_SMALL,
			...
		)
		header.Debug = Debug
		header:SetScale(SCALE)
		header:SetParent(anchor)
		return header
	end

	--------------------------------------------------------------------------------
	-- Creating group headers
	--------------------------------------------------------------------------------
	
	oUF:SetActiveStyle("Adirelle_Raid")

	local players = SpawnHeader(
		"oUF_Raid",
		"SecureGroupHeaderTemplate",
		"maxColumns", 8,
		--@debug@--
		"showSolo", true,
		--@end-debug@--
		"showParty", true,
		"showPlayer", true,
		"showRaid", true
	)
	players:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 0)
	players:Show()
	SecureHandlerSetFrameRef(anchor, 'players', players)

	local pets = SpawnHeader(
		"oUF_RaidPets",
		"SecureGroupPetHeaderTemplate",
		"maxColumns", 3,
	--@debug@--
		"showSolo", true,
	--@end-debug@--
		"showPlayer", true,
		"showParty", true,
		"showRaid", true
	)
	pets:SetPoint("BOTTOM", players, "TOP", 0, 2*SPACING)
	SecureHandlerSetFrameRef(anchor, 'pets', pets)

	-- Unit height updating
	anchor:SetAttribute('_onstate-height', [===[
		local height = tonumber(newstate)
		local players = self:GetFrameRef('players')
		if not height or height == players:GetAttribute('unitHeight') then return end
		self:CallMethod('Debug', "_onstate-height", height)
		units = wipe(units or newtable())
		players:GetChildList(units)
		for _, unit in next, units do
			unit:SetHeight(height)
		end
		players:SetAttribute('unitHeight', height)
		players:SetAttribute('minHeight', height)
	]===])

	anchor:SetAttribute('_onstate-pets', [===[
		local pets = self:GetFrameRef('pets')
		if newstate == 'show' and not pets:IsShown() then
			self:CallMethod('Debug', "_onstate-pets", newstate)
			pets:Show()
		elseif newstate == 'hide' and pets:IsShown() then
			self:CallMethod('Debug', "_onstate-pets", newstate)
			pets:Hide()
		end
	]===])

	RegisterStateDriver(anchor, "pets", "[@raid26,exists] hide; show")
	local healerHeightExpr =  format("[@raid26,exists] %d; %d", HEIGHT_SMALL, HEIGHT_FULL)

	local function UpdateHeightDriver()
		if not anchor:CanChangeAttribute() then
			anchor:Debug("UpdateHeightDriver, locked down, waiting end of combat")
			anchor:SetScript('OnEvent', UpdateHeightDriver)
			anchor:RegisterEvent('PLAYER_REGEN_ENABLED')
			return
		else
			anchor:SetScript('OnEvent', nil)
			anchor:UnregisterEvent('PLAYER_REGEN_ENABLED')
		end

		if GetPlayerRole() == "HEALER" then
			anchor:Debug("UpdateHeightDriver, healer => dynamic height")
			RegisterStateDriver(anchor, "height", healerHeightExpr)
		else
			anchor:Debug("UpdateHeightDriver, not healer => fixed height")
			UnregisterStateDriver(anchor, "height")
			anchor:SetAttribute("height", HEIGHT_SMALL)
		end
	end

	oUF_Adirelle.RegisterPlayerRoleCallback(UpdateHeightDriver)
	UpdateHeightDriver()

end)

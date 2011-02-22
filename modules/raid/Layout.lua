--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
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

	local SPACING = oUF_Adirelle.SPACING
	local WIDTH = oUF_Adirelle.WIDTH
	local HEIGHT_FULL = oUF_Adirelle.HEIGHT
	local HEIGHT_SMALL = 20

	--------------------------------------------------------------------------------
	-- Anchor
	--------------------------------------------------------------------------------

	local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate,SecureHandlerStateTemplate")
	anchor.Debug = function(self, ...) return Debug(self:GetName(), ...) end
	anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
	anchor:SetWidth(0.1)
	anchor:SetHeight(0.1)

	anchor:SetAttribute('heightSmall', HEIGHT_SMALL)
	anchor:SetAttribute('heightFull', HEIGHT)

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

		if GetPlayerRole() == "healer" then
			anchor:Debug("UpdateHeightDriver, healer => dynamic height")
			RegisterStateDriver(anchor, "height", healerHeightExpr)
		else
			anchor:Debug("UpdateHeightDriver, not healer => fixed height")
			UnregisterStateDriver(anchor, "height")
			anchor:SetAttribute("height", HEIGHT_SMALL)
		end
	end

	RegisterPlayerRoleCallback(UpdateHeightDriver)
	UpdateHeightDriver()

end)

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

	local function SpawnHeader(name, template, layouts, group, ...)
		local header = oUF:SpawnHeader(
			name,
			template,
			nil,
			"groupFilter", group,
			"point", "LEFT",
			"xOffset", SPACING,
			"layouts", layouts,
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				self:SetWidth(]]..WIDTH..[[)
				self:SetHeight(header:GetAttribute('unitHeight'))
				self:SetAttribute('refreshUnitChange', [=[
					local unit = self:GetAttribute('unit')
					self:CallMethod('Debug', 'refreshUnitChange', unit)
					if unit then
						unit = unit:gsub('petpet', 'pet')
						if unit ~= self:GetAttribute('unit') then
							self:CallMethod('Debug', '- fixing unit', self:GetAttribute('unit'), '=>', unit)
							self:SetAttribute('unit', unit)
						end
					end
					--self:CallMethod('UpdateAllElements', 'refreshUnitChange')
				]=])
			]],
			"unitHeight", HEIGHT_SMALL,
			"_childupdate-height", [[
				local height = tonumber(message)
				if not height or height == self:GetAttribute('unitHeight') then return end
				self:CallMethod('Debug', "_childupdate-height", height)
				self:SetAttribute('unitHeight', height)
				units = wipe(units or newtable())
				self:GetChildList(units)
				for _, unit in next, units do
					unit:SetHeight(height)
				end
			]],
			"_childupdate-layout", [[
				local layout = tonumber(message)
				if not layout or layout == self:GetAttribute('layout') then return end
				if self:GetAttribute('layouts'):match(';'..tostring(layout)..';') then
					if not self:IsShown() then
						self:CallMethod('Debug', "_childupdate-layout", layout, "=> show")
						self:Show()
					end
				else
					if self:IsShown() then
						self:CallMethod('Debug', "_childupdate-layout", layout, "=> hide")
						self:Hide()
					end
				end
			]],
			...
		)
		header:Hide()
		header.Debug = Debug
		header:SetScale(SCALE)
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
			isParty and ";1;5;10;15;20;25;40;" or ";10;15;20;25;40;",
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
		";1;5;",
		1,
	--@debug@--
		"showSolo", true,
	--@end-debug@--
		"showPlayer", true,
		"showParty", true,
		"showRaid", true
	)
	header:SetPoint("BOTTOM", headers[1], "TOP", 0, SPACING)
	headers.partypets = header

	-- Raid pets
	for group = 1, 2 do
		headers['raidpet'..group] = SpawnHeader(
			"oUF_Raid"..group.."Pets",
			"SecureGroupPetHeaderTemplate",
			";10;",
			group,
			"showRaid", true
		)
	end
	headers.raidpet1:SetPoint("BOTTOM", headers[2], "TOP", 0, SPACING)
	headers.raidpet2:SetPoint("BOTTOM", headers.raidpet1, "TOP", 0, SPACING)

	-- Unit height updating
	anchor:SetAttribute('_onstate-height', [===[
		local height = tonumber(newstate)
		if not height then return end
		self:CallMethod('Debug', "_onstate-height", height)
		self:ChildUpdate('height', height)
	]===])

	anchor:SetAttribute('_onstate-layout', [===[
		local layout = tonumber(newstate)
		if not layout then return end
		self:CallMethod('Debug', "_onstate-layout", layout)
		self:ChildUpdate('layout', layout)
	]===])

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

	-- Get the best layout type
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

	function anchor:UpdateLayout(...)
		if not self:CanChangeAttribute() then return end
		self:Debug('UpdateLayout', ...)
		local layout = GetLayoutType()
		local height = (GetPlayerRole() == 'healer' and layout <= 25) and HEIGHT_FULL or HEIGHT_SMALL
		if height ~= self:GetAttribute('state-height') then
			self:SetAttribute('state-height', height)
		end
		if layout ~= self:GetAttribute('state-layout') then
			self:SetAttribute('state-layout', layout)
		end
	end

	anchor:SetScript('OnEvent', anchor.UpdateLayout)
  anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
  anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')
  anchor:RegisterEvent('PLAYER_REGEN_ENABLED')
  anchor:RegisterEvent('PARTY_MEMBERS_CHANGED')

	RegisterPlayerRoleCallback(function(...) anchor:UpdateLayout('RegisterPlayerRoleCallback', ...) end)

	anchor:UpdateLayout("OnLoad")

end)

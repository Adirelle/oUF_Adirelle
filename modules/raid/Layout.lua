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

	anchor.pendingAttributes = {}
	anchor:SetScript('OnEvent', function(self, event, ...) return self[event](self, event, ...) end)

	function anchor:PLAYER_REGEN_ENABLED()
		local attrs = self.pendingAttributes
		if next(attrs) then
			for k,v in pairs(attrs) do
				if self:GetAttribute(k) ~= v then
					self:SetAttribute(k, v)
				end
			end
			wipe(attrs)
		end
	end

	-- SafeSetAttribute allow to ask to set attributes in combat,	change will be postponed until end of combat
	function anchor:SafeSetAttribute(k, v)
		if self:CanChangeProtectedState() then
			if self:GetAttribute(k) ~= v then
				return self:SetAttribute(k, v)
			end
		else
			self.pendingAttributes[k] = v
			self:RegisterEvent('PLAYER_REGEN_ENABLED')
		end
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
			"layouts", layouts,
			"minWidth", 0.1,
			"minHeight", HEIGHT_SMALL,
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
			"showPlayer", true,
			"showParty", true,
			"showRaid", true
		)
	end
	headers.raidpet1:SetPoint("BOTTOM", headers[2], "TOP", 0, SPACING)
	headers.raidpet2:SetPoint("BOTTOM", headers.raidpet1, "TOP", 0, SPACING)

	-- Unit height updating
	anchor:SetAttribute('_onstate-height', [===[
		newstate = tonumber(newstate)
		if not newstate then return end
		local headers, units = self:GetChildList(newtable()), newtable()
		for i, header in pairs(headers) do
			if header:GetAttribute('layouts') then
				header:GetChildList(units)
				header:SetHeight(newstate)
				header:SetAttribute('initial-height', newstate)
				header:SetAttribute('minHeight', newstate)
			end
		end
		for i, unit in pairs(units) do
			if unit:GetHeight() ~= newstate then
				unit:SetHeight(newstate)
			end
		end
	]===])

	anchor:SetAttribute('update-height', [===[
		local layout, isHealer = tonumber(self:GetAttribute('state-layout')) or 1, self:GetAttribute('state-isHealer')
		local newHeight = self:GetAttribute((layout < 25 and isHealer) and "heightFull" or "heightSmall")
		if newHeight ~= self:GetAttribute('state-height') then
			self:SetAttribute('state-height', newHeight)
		end
	]===])

	anchor:SetAttribute('_onstate-isHealer', [===[
		control:RunAttribute('update-height')
	]===])

	anchor:SetAttribute('_onstate-layout', [===[
		local children = self:GetChildList(newtable())
		local pattern = ';'..tostring(newstate)..';'
		for _, child in pairs(children) do
			local layouts = child:GetAttribute('layouts')
			if layouts then
				if layouts:match(pattern) then
					child:SetAttribute('statehidden', nil)
					child:Show()
				else
					child:SetAttribute('statehidden', true)
					child:Hide()
				end
			end
		end
		control:RunAttribute('update-height')
	]===])

	anchor:SetAttribute('state-isHealer', GetPlayerRole() == "HEALER")
	anchor:SetAttribute('state-layout', 40)

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

	function anchor:PLAYER_ENTERING_WORLD()
		self:SafeSetAttribute('state-layout', GetLayoutType())
	end
	anchor.ZONE_CHANGED_NEW_AREA = anchor.PLAYER_ENTERING_WORLD
	anchor.PARTY_MEMBERS_CHANGED = anchor.PLAYER_ENTERING_WORLD

  anchor:RegisterEvent('PLAYER_ENTERING_WORLD')
  anchor:RegisterEvent('ZONE_CHANGED_NEW_AREA')
  anchor:RegisterEvent('PARTY_MEMBERS_CHANGED')

	RegisterPlayerRoleCallback(function(role)
		anchor:SafeSetAttribute('state-isHealer', role == "HEALER")
	end)

	--RegisterStateDriver(anchor, 'layout', "[@raid26,exists] 40; [@raid11,exists] 25; [group:raid] 10; [group:party] 5; 1")
	anchor:PLAYER_ENTERING_WORLD()

end)

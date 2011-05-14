--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

oUF:Factory(function()
	-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
	local GetInstanceInfo = _G.GetInstanceInfo
	local GetNumRaidMembers = _G.GetNumRaidMembers
	local GetNumPartyMembers = _G.GetNumPartyMembers
	local GetRaidRosterInfo = _G.GetRaidRosterInfo
	local pairs, ipairs, format, strmatch = _G.pairs, _G.ipairs, _G.format, _G.strmatch
	local max, huge, GetTime = _G.math.max, _G.math.huge, _G.GetTime
	local CreateFrame, UIParent = _G.CreateFrame, _G.UIParent
	local SecureHandlerSetFrameRef = _G.SecureHandlerSetFrameRef
	local RegisterStateDriver, UnregisterStateDriver = _G.RegisterStateDriver, _G.UnregisterStateDriver

	local Debug = oUF_Adirelle.Debug

	-- Fetch some shared variables into local namespace
	local SCALE = oUF_Adirelle.SCALE
	local SPACING = oUF_Adirelle.SPACING
	local WIDTH = oUF_Adirelle.WIDTH
	local HEIGHT = oUF_Adirelle.HEIGHT
	local GetPlayerRole = oUF_Adirelle.GetPlayerRole

	local HEIGHT_FULL = HEIGHT
	local HEIGHT_SMALL = 20

	--------------------------------------------------------------------------------
	-- Anchor
	--------------------------------------------------------------------------------

	local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate,SecureHandlerStateTemplate")
	anchor.Debug = oUF.Debug
	anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
	anchor:SetSize(SPACING * 4 + WIDTH * 5, SPACING * 7 + HEIGHT_SMALL * 8)

	oUF_Adirelle.RegisterMovable(anchor, 'raid', "Party/raid frames")

	oUF_Adirelle.EmbedEventMessaging(anchor)

	--------------------------------------------------------------------------------
	-- Header prototype
	--------------------------------------------------------------------------------
	local headerProto = { Debug = oUF.Debug	}

	local function children_iterator(self, index)
		index = index + 1
		local child = self:GetAttribute('child'..index)
		if child then
			return index, child
		end
	end

	function headerProto:IterateChildren()
		return children_iterator, self, 0
	end

	function headerProto:OnAttributeChanged(name, value)
		if name ~= '_changed' and name ~= '_ignore' then
			self:Debug('OnAttributeChanged', name, value)
			self:SetAttribute('_changed', true)
		end
		if name == 'columnAnchorPoint' or name == 'point' or name == 'unitsPerColumn' then
			self:Debug('Clearing children anchors')
			for _, child in self:IterateChildren() do
				child:ClearAllPoints()
			end
		end
	end

	function headerProto:SetAttributes(...)
		for i = 1, select('#', ...), 2 do
			self:SetAttribute(select(i, ...))
		end
	end

	function headerProto:SetAnchoring(orientation, anchor, spacing)
		self:Debug('SetAnchoring', orientation, anchor, spacing)
		if orientation == "horizontal" then
			self:SetAttributes(
				"point", strmatch(anchor, "RIGHT") or "LEFT",
				"columnAnchorPoint", strmatch(anchor, "TOP") or "BOTTOM",
				"xOffset", strmatch(anchor, "RIGHT") and -spacing or spacing,
				"yOffset", 0
			)
		else
			self:SetAttributes(
				"point", strmatch(anchor, "TOP") or "BOTTOM",
				"columnAnchorPoint", strmatch(anchor, "RIGHT") or "LEFT",
				"xOffset", 0,
				"yOffset", strmatch(anchor, "TOP") and -spacing or spacing
			)
		end
	end

	function headerProto:SetUnitSize(width, height)
		if self:GetAttribute('unitWidth') ~= width or self:GetAttribute('unitHeight') ~= height then
			self:Debug('SetUnitSize', width, height)
			self:SetAttributes('unitWidth', width, 'unitHeight', height)
			for _, child in self:IterateChildren() do
				child:SetSize(width, height)
			end
		end
	end

	local function CreateHeader(suffix, template)
		oUF:SetActiveStyle("Adirelle_Raid")
		local header = oUF:SpawnHeader("oUF_Raid"..tostring(suffix), template or "SecureGroupHeaderTemplate")
		for k, v in pairs(headerProto) do
			header[k] = v
		end
		header:Hide()
		header:SetParent(anchor)
		header:SetAttributes(
			'_ignore', "attributeChanges",
			'oUF-initialConfigFunction', [===[
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				local header = self:GetParent()
				self:SetWidth(header:GetAttribute('unitWidth'))
				self:SetHeight(header:GetAttribute('unitHeight'))
			]===],
			"sortMethod", "NAME",
			"groupBy", "GROUP",
			"groupingOrder", "1,2,3,4,5,6,7,8",
			"unitsPerColumn", 5,
			--@debug@--
			"showSolo", true,
			--@end-debug@--
			"showParty", true,
			"showPlayer", true,
			"showRaid", true,
			"unitWidth", WIDTH,
			"unitHeight", HEIGHT
		)
		header:HookScript('OnAttributeChanged', header.OnAttributeChanged)
		header:Debug('New header')
		return header
	end

	--------------------------------------------------------------------------------
	-- Layout core functions
	--------------------------------------------------------------------------------

	-- Returns (type, number of groups, PvE layout flag)
	local function GetLayoutInfo()
		local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
		if instanceType == "arena" then
			return "arena", 1, false
		elseif instanceType == "pvp" then
			return "pvp", (maxPlayers or 40)/5, false
		elseif instanceType == "party" then
			return "party", 1, true
		elseif instanceType == "raid" then
			return "raid", (maxPlayers or 40)/5, true
		elseif GetNumRaidMembers() > 0 then
			local maxGroup = 1
			for i = 1, GetNumRaidMembers() do
				local _, _, subGroup = GetRaidRosterInfo(i)
				if subGroup > maxGroup then
					maxGroup = subGroup
				end
			end
			return "raid", maxGroup, true
		elseif GetNumPartyMembers() > 0 then
			return "party", 1, true
		else
			return "solo", 1, true
		end
	end

	local heap = {}
	local headers = {}

	--@debug@
	do
		local function spy(self, ...)
			for k, v in pairs(headers) do
				if v == self then
					return self:Debug('SecureGroup*Header_Update', ...)
				end
			end
		end
		hooksecurefunc('SecureGroupHeader_Update', spy)
		hooksecurefunc('SecureGroupPetHeader_Update', spy)
	end
	--@end-debug@

	function anchor:ConfigureHeaders(layoutType, numGroups, isPvE)
		self:Debug('ConfigureHeaders', layoutType, numGroups, isPvE)

		local numHeaders = numGroups

		local showTanks = isPvE and numGroups > 1
		local showPets = isPvE
		if showTanks then
			numHeaders = numHeaders + 1
		end

		-- Create new headers if need be
		for i = #headers+1, numHeaders do
			headers[i] = heap[i] or CreateHeader(i)
			heap[i] = nil
			headers[i]:Show()
		end

		-- Hide unused headers
		for i = numHeaders+1, #headers do
			local header = headers[i]
			header:Hide()
			heap[i] = header
			headers[i] = nil
		end

		-- Configure filters
		local offset = 0
		if showTanks then
			headers[1]:SetAttributes('groupFilter', 'TANK')
			offset = 1
		end
		for i = 1, numGroups do
			headers[i + offset]:SetAttributes('groupFilter', tostring(i))
		end

		-- Update pets
		if showPets then
			headers.pets = heap.pets or CreateHeader("Pets", "SecureGroupPetHeaderTemplate")
			headers.pets:Show()
		elseif headers.pets then
			heap.pets = headers.pets
			headers.pets:Hide()
			headers.pets = nil
		end
	end

	function anchor:ConfigureAnchors(alignment, orientation, unitSpacing, groupSpacing)
		self:Debug('ConfigureAnchors', alignment, orientation, unitSpacing, groupSpacing)

		-- Calculating the header anchoring parameters, depending on alignment and orientation
		local from, xOffset, yOffset = alignment, 0, 0
		local horiz, vert
		if orientation == "horizontal" then
			horiz = strmatch(from, "LEFT") or strmatch(from, "RIGHT") or ""
			if strmatch(from, "TOP") then
				vert, yOffset = "BOTTOM", -groupSpacing
			else
				vert, yOffset = "TOP", groupSpacing
			end
		else
			vert = strmatch(from, "BOTTOM") or strmatch(from, "TOP") or ""
			if strmatch(from, "RIGHT") then
				horiz, xOffset = "LEFT", -groupSpacing
			else
				horiz, xOffset = "RIGHT", groupSpacing
			end
		end
		local to = vert..horiz

		for key, header in pairs(headers) do
			header:ClearAllPoints()
			header:SetAnchoring(orientation, alignment, unitSpacing)
			if key == 1 then
				header:SetPoint(from, anchor, from, 0, 0)
			elseif key == 'pets' then
				headers.pets:SetPoint(from, headers[#headers], to, xOffset, yOffset)
			else
				header:SetPoint(from, headers[key-1], to, xOffset, yOffset)
			end
		end

	end

	function anchor:ConfigureUnitSize(width, height, petHeight)
		self:Debug('ConfigureUnitSize', width, height, petHeight)
		for key, header in pairs(headers) do
			if key == 'pets' then
				header:SetUnitSize(width, petHeight)
			else
				header:SetUnitSize(width, height)
			end
		end
	end

	function anchor:UpdateLayout(event)
		self:Debug('UpdateLayout', event)

		-- Clear any pending update
		self:SetScript('OnUpdate', nil)

		-- Our saved variable
		local layout = oUF_Adirelle.layoutDB.profile.Raid

		-- Protect all headers against updates
		for _, header in pairs(headers) do
			header:SetAttribute('_ignore', "attributeChanges")
		end

		-- Get information about the layout
		local layoutType, numGroups, isPvE = GetLayoutInfo()

		local changed = false

		-- Update filters and visibility
		if self.layoutType ~= layoutType and self.numGroups ~= numGroups and self.isPvE ~= isPvE then
			self.layoutType, self.numGroups, self.isPvE = layoutType, numGroups, isPvE
			self:ConfigureHeaders(layoutType, numGroups, isPvE)
			changed = true
		else
			self:Debug('- layout, no change:', layoutType, numGroups, isPvE)
		end

		-- Reanchor
		local alignment, orientation, unitSpacing, groupSpacing = layout.alignment, layout.orientation, layout.unitSpacing, layout.groupSpacing
		if changed or self.alignment ~= alignment or self.orientation ~= orientation or self.unitSpacing ~= unitSpacing or self.groupSpacing ~= groupSpacing then
			self.alignment, self.orientation, self.unitSpacing, self.groupSpacing = alignment, orientation, unitSpacing, groupSpacing
			self:ConfigureAnchors(alignment, orientation, unitSpacing, groupSpacing)
		else
			self:Debug('- anchoring, no change:', alignment, orientation, unitSpacing, groupSpacing)
		end

		-- Update size
		local width, height = layout.width, layout[GetPlayerRole() == "HEALER" and "healerHeight" or "height"]
		if self.unitWidth ~= width or self.unitHeight ~= height then
			self.unitWidth, self.unitHeight = width, height
			self:ConfigureUnitSize(width, height, layout.height)
		else
			self:Debug('- unit size, no change:', width, height)
		end

		-- Reenable update and clear the _changed flags
		-- If that flag wasn't nil, this causes the header to update
		for _, header in pairs(headers) do
			header:SetAttribute('_ignore', nil)
			if header:GetAttribute('_changed') then
				header:SetAttribute('_changed', nil)
			end
		end

	end

	--------------------------------------------------------------------------------
	-- Event handling
	--------------------------------------------------------------------------------

	local delay = 0
	function anchor:OnUpdate(elapsed)
		delay = delay + elapsed
		if delay >= 0.1 then
			delay = 0
			return self:UpdateLayout('OnUpdate')
		end
	end

	function anchor:TriggerUpdate(event)
		self:Debug('TriggerUpdate', event)
		if not self:GetScript('OnUpdate') then
			delay = 0
			self:SetScript('OnUpdate', self.OnUpdate)
		end
	end

	function anchor:PLAYER_REGEN_DISABLED(event)
		self:Debug('PLAYER_REGEN_DISABLED', event)

		self:UnregisterEvent('PLAYER_REGEN_DISABLED', self.PLAYER_REGEN_DISABLED)
		self:UnregisterEvent('PLAYER_ENTERING_WORLD', self.TriggerUpdate)
		self:UnregisterEvent('ZONE_CHANGED_NEW_AREA', self.TriggerUpdate)
		self:UnregisterEvent('PARTY_MEMBERS_CHANGED', self.TriggerUpdate)
		self:UnregisterEvent('RAID_ROSTER_UPDATE', self.TriggerUpdate)
		self:UnregisterMessage('OnSettingsModified', self.TriggerUpdate)
		self:UnregisterMessage('OnRaidLayoutModified', self.TriggerUpdate)
		self:UnregisterMessage('OnPlayerRoleChanged', self.TriggerUpdate)

		self:RegisterEvent('PLAYER_REGEN_ENABLED', self.PLAYER_REGEN_ENABLED)

		return self:UpdateLayout(event)
	end

	function anchor:PLAYER_REGEN_ENABLED(event)
		self:Debug('PLAYER_REGEN_ENABLED', event)

		self:UnregisterEvent('PLAYER_REGEN_ENABLED', self.PLAYER_REGEN_ENABLED)

		self:RegisterEvent('PLAYER_REGEN_DISABLED', self.PLAYER_REGEN_DISABLED)
		self:RegisterEvent('PLAYER_ENTERING_WORLD', self.TriggerUpdate)
		self:RegisterEvent('ZONE_CHANGED_NEW_AREA', self.TriggerUpdate)
		self:RegisterEvent('PARTY_MEMBERS_CHANGED', self.TriggerUpdate)
		self:RegisterEvent('RAID_ROSTER_UPDATE', self.TriggerUpdate)
		self:RegisterMessage('OnSettingsModified', self.TriggerUpdate)
		self:RegisterMessage('OnRaidLayoutModified', self.TriggerUpdate)
		self:RegisterMessage('OnPlayerRoleChanged', self.TriggerUpdate)

		return self:UpdateLayout(event)
	end

	--------------------------------------------------------------------------------
	-- Go !
	--------------------------------------------------------------------------------
	anchor:PLAYER_REGEN_ENABLED('OnLoad')

end)

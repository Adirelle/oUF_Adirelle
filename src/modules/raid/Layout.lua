--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]=]

local _, private = ...

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

oUF:Factory(function()
	--<GLOBALS
	local ceil = assert(_G.ceil)
	local CreateFrame = assert(_G.CreateFrame)
	local GetInstanceInfo = assert(_G.GetInstanceInfo)
	local GetNumGroupMembers = assert(_G.GetNumGroupMembers)
	local GetRaidRosterInfo = assert(_G.GetRaidRosterInfo)
	local hooksecurefunc = assert(_G.hooksecurefunc)
	local IsInActiveWorldPVP = assert(_G.IsInActiveWorldPVP)
	local pairs = assert(_G.pairs)
	local select = assert(_G.select)
	local strjoin = assert(_G.strjoin)
	local strmatch = assert(_G.strmatch)
	local tostring = assert(_G.tostring)
	local UIParent = assert(_G.UIParent)
	--GLOBALS>

	-- Fetch some shared variables into local namespace
	local SPACING = assert(private.SPACING)
	local WIDTH = assert(private.WIDTH)
	local HEIGHT = assert(private.HEIGHT)
	local GetPlayerRole = assert(oUF_Adirelle.GetPlayerRole)

	local HEIGHT_SMALL = 20

	--------------------------------------------------------------------------------
	-- Anchor
	--------------------------------------------------------------------------------

	local anchor = CreateFrame("Frame", "oUF_Raid_Anchor", UIParent, "SecureFrameTemplate,SecureHandlerStateTemplate")
	anchor.Debug = oUF.Debug
	anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
	anchor:SetSize(SPACING * 4 + WIDTH * 5, SPACING * 7 + HEIGHT_SMALL * 8)

	oUF_Adirelle.RegisterMovable(anchor, "raid", "Party/raid frames")

	oUF_Adirelle.EmbedEventMessaging(anchor)

	--------------------------------------------------------------------------------
	-- Header prototype
	--------------------------------------------------------------------------------
	local headerProto = { Debug = oUF.Debug }

	local function children_iterator(self, index)
		index = index + 1
		local child = self:GetAttribute("child" .. index)
		if child then
			return index, child
		end
	end

	function headerProto:IterateChildren()
		return children_iterator, self, 0
	end

	function headerProto:OnAttributeChanged(name)
		if name ~= "_ignore" then
			self._changed = true
		end
		if name == "columnAnchorPoint" or name == "point" or name == "unitsPerColumn" then
			for _, child in self:IterateChildren() do
				child:ClearAllPoints()
			end
		end
	end

	function headerProto:SetAttributes(...)
		for i = 1, select("#", ...), 2 do
			self:SetAttribute(select(i, ...))
		end
	end

	function headerProto:SetAnchoring(orientation, anchorPoint, spacing)
		if orientation == "horizontal" then
			self:SetAttributes(
				"point",
				strmatch(anchorPoint, "RIGHT") or "LEFT",
				"columnAnchorPoint",
				strmatch(anchorPoint, "TOP") or "BOTTOM",
				"xOffset",
				strmatch(anchorPoint, "RIGHT") and -spacing or spacing,
				"yOffset",
				0
			)
		else
			self:SetAttributes(
				"point",
				strmatch(anchorPoint, "TOP") or "BOTTOM",
				"columnAnchorPoint",
				strmatch(anchorPoint, "RIGHT") or "LEFT",
				"xOffset",
				0,
				"yOffset",
				strmatch(anchorPoint, "TOP") and -spacing or spacing
			)
		end
	end

	function headerProto:SetUnitSize(width, height)
		if self:GetAttribute("unitWidth") ~= width or self:GetAttribute("unitHeight") ~= height then
			self:SetAttributes("unitWidth", width, "unitHeight", height)
			for _, child in self:IterateChildren() do
				child:SetSize(width, height)
			end
		end
	end

	local function CreateHeader(suffix, template)
		oUF:SetActiveStyle("Adirelle_Raid")
		local header = oUF:SpawnHeader(
			"oUF_Raid" .. tostring(suffix),
			template or "SecureGroupHeaderTemplate",
			nil,
			"_ignore",
			"attributeChanges",
			"oUF-initialConfigFunction",
			[===[
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				local header = self:GetParent()
				self:SetWidth(header:GetAttribute('unitWidth'))
				self:SetHeight(header:GetAttribute('unitHeight'))
			]===],
			"sortMethod",
			"NAME",
			"groupBy",
			"GROUP",
			"groupingOrder",
			"1,2,3,4,5,6,7,8",
			"unitsPerColumn",
			5,
			"showParty",
			(suffix == "Pets" or suffix == 1),
			"showPlayer",
			true,
			"showRaid",
			true,
			"unitWidth",
			WIDTH,
			"unitHeight",
			HEIGHT,
			"minWidth",
			0.1,
			"minHeight",
			0.1
		)
		for k, v in pairs(headerProto) do
			header[k] = v
		end
		header:Hide()
		header:SetParent(anchor)
		header:HookScript("OnAttributeChanged", header.OnAttributeChanged)
		header:Debug("New header")
		return header
	end

	--------------------------------------------------------------------------------
	-- Layout core functions
	--------------------------------------------------------------------------------

	local function GetRaidNumGroups(maxPlayers)
		if not maxPlayers or maxPlayers == 0 then
			maxPlayers = GetNumGroupMembers() or 1
		end
		local numGroups = ceil(maxPlayers / 5)
		local highestGroup = numGroups
		for i = 1, GetNumGroupMembers() do
			local _, _, group = GetRaidRosterInfo(i)
			if group > highestGroup then
				highestGroup = group
			end
		end
		return numGroups, highestGroup
	end

	-- Returns (type, PvE, number of groups, highest group number)
	local function GetLayoutInfo()
		local _, instanceType, _, _, maxPlayers = GetInstanceInfo()
		anchor:Debug("GetLayoutInfo", "groupSize=", GetNumGroupMembers(), "instanceInfo:", GetInstanceInfo())
		if instanceType == "arena" then
			return "arena", false, 1, 1
		elseif instanceType == "scenario" and GetNumGroupMembers() > 0 then
			return "raid", false, GetRaidNumGroups(maxPlayers)
		elseif instanceType == "pvp" or IsInActiveWorldPVP() then
			return "battleground", false, GetRaidNumGroups(maxPlayers)
		elseif instanceType == "raid" or (instanceType == "none" and GetNumGroupMembers() > 0) then
			return "raid", true, GetRaidNumGroups(instanceType == "raid" and maxPlayers)
		elseif instanceType == "party" or (instanceType == "none" and GetNumGroupMembers() > 0) then
			return "party", true, 1, 1
		else
			return "solo", true, 1, 1
		end
	end

	local heap = {}
	local headers = {}

	--@debug@
	do
		local function spy(self, ...)
			for _, v in pairs(headers) do
				if v == self then
					return self:Debug("SecureGroup*Header_Update", ...)
				end
			end
		end
		hooksecurefunc("SecureGroupHeader_Update", spy)
		hooksecurefunc("SecureGroupPetHeader_Update", spy)
	end
	--@end-debug@

	local function GroupList(n)
		if n > 0 then
			return tostring(n), GroupList(n - 1)
		end
	end

	function anchor:ConfigureHeaders(layoutType, numGroups, showTanks, showPets, showSolo)
		self:Debug("ConfigureHeaders", layoutType, numGroups, showTanks, showPets, showSolo)

		if showTanks and numGroups < 2 then
			showTanks = false
		end

		local numHeaders = numGroups
		if showTanks then
			numHeaders = numHeaders + 1
		end

		-- Create new headers if need be
		for i = #headers + 1, numHeaders do
			headers[i] = heap[i] or CreateHeader(i)
			heap[i] = nil
			headers[i]:Show()
		end

		-- Hide unused headers
		for i = numHeaders + 1, #headers do
			local header = headers[i]
			header:Hide()
			heap[i] = header
			headers[i] = nil
		end

		-- Configure filters
		local offset = 0
		if showTanks then
			headers[1]:SetAttribute("groupFilter", "MAINTANK")
			offset = 1
		end
		headers[1 + offset]:SetAttribute("showSolo", showSolo)
		for i = 1, numGroups do
			headers[i + offset]:SetAttribute("groupFilter", tostring(i))
		end

		-- Update pets
		local pets = headers.pets
		if showPets then
			if not pets then
				pets = heap.pets or CreateHeader("Pets", "SecureGroupPetHeaderTemplate")
				headers.pets = pets
				pets:Show()
			end
			pets:SetAttributes(
				"groupFilter",
				strjoin(",", GroupList(numGroups)),
				"maxColumns",
				numGroups,
				"showSolo",
				showSolo
			)
		elseif pets then
			pets:Hide()
			heap.pets, headers.pets = pets, nil
		end
	end

	function anchor:ConfigureAnchors(alignment, orientation, unitSpacing, groupSpacing)
		self:Debug("ConfigureAnchors", alignment, orientation, unitSpacing, groupSpacing)

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
		local to = vert .. horiz

		for key, header in pairs(headers) do
			header:ClearAllPoints()
			header:SetAnchoring(orientation, alignment, unitSpacing)
			if key == 1 then
				header:SetPoint(from, anchor, from, 0, 0)
			elseif key == "pets" then
				headers.pets:SetPoint(from, headers[#headers], to, xOffset * 2, yOffset * 2)
			else
				header:SetPoint(from, headers[key - 1], to, xOffset, yOffset)
			end
		end

	end

	function anchor:ConfigureUnitSize(width, height, petHeight)
		self:Debug("ConfigureUnitSize", width, height, petHeight)
		for key, header in pairs(headers) do
			if key == "pets" then
				header:SetUnitSize(width, petHeight)
			else
				header:SetUnitSize(width, height)
			end
		end
	end

	function anchor:UpdateLayout(event)
		self:Debug("UpdateLayout", event)

		-- Clear any pending update
		self:SetScript("OnUpdate", nil)

		-- Our saved variable
		local layout = oUF_Adirelle.layoutDB.profile.Raid

		-- Protect all headers against updates
		for _, header in pairs(headers) do
			header:SetAttribute("_ignore", "attributeChanges")
		end

		-- Get information to select the layout
		local layoutType, isPvE, numGroups, highestGroup
		local playerRole = GetPlayerRole()
		if playerRole == nil then
			-- First login, use safe settings in case the player crashed during combat
			playerRole, layoutType, isPvE, numGroups, highestGroup = "HEALER", "raid", true, 8, 8
		else
			layoutType, isPvE, numGroups, highestGroup = GetLayoutInfo()
		end
		self:Debug(
			"UpdateLayout role:",
			playerRole,
			"type:",
			layoutType,
			"pve:",
			isPvE,
			"numGroups:",
			numGroups,
			"highest:",
			highestGroup
		)

		-- Should we show the tanks and the pets ?
		local showTanks = isPvE and layout.showTanks
		local showPets = false
		if isPvE or layout.showPets[layoutType] then
			local prefs = layout.showPets
			if numGroups == 1 then
				showPets = prefs.party
			elseif numGroups <= 2 then
				showPets = prefs.raid10
			elseif numGroups <= 3 then
				showPets = prefs.raid15
			elseif numGroups <= 5 then
				showPets = prefs.raid25
			else
				showPets = prefs.raid40
			end
		end

		-- If not strict, show the highestGroup
		if not layout.strictSize then
			numGroups = highestGroup
		end

		local changed = false
		local showSolo = layout.showSolo

		-- Update filters and visibility
		if
			self.layoutType ~= layoutType
			or self.numGroups ~= numGroups
			or self.showTanks ~= showTanks
			or self.showPets ~= showPets
			or self.showSolo ~= showSolo
		then
			self.layoutType, self.numGroups, self.showTanks = layoutType, numGroups, showTanks
			self.showPets, self.showSolo = showPets, showSolo
			self:ConfigureHeaders(layoutType, numGroups, showTanks, showPets, showSolo)
			changed = true
		else
			self:Debug("- layout, no change:", layoutType, numGroups, showTanks, showPets, showSolo)
		end

		-- Reanchor
		local alignment, orientation = layout.alignment, layout.orientation
		local unitSpacing, groupSpacing = layout.unitSpacing, layout.groupSpacing
		if
			changed
			or self.alignment ~= alignment
			or self.orientation ~= orientation
			or self.unitSpacing ~= unitSpacing
			or self.groupSpacing ~= groupSpacing
		then
			self.alignment, self.orientation = alignment, orientation
			self.unitSpacing, self.groupSpacing = unitSpacing, groupSpacing
			self:ConfigureAnchors(alignment, orientation, unitSpacing, groupSpacing)
			changed = true
		else
			self:Debug("- anchoring, no change:", alignment, orientation, unitSpacing, groupSpacing)
		end

		-- Update size
		local width, height = layout.width, layout[playerRole == "HEALER" and "healerHeight" or "height"]
		if changed or self.unitWidth ~= width or self.unitHeight ~= height then
			self.unitWidth, self.unitHeight = width, height
			self:ConfigureUnitSize(width, height, layout.height)
		else
			self:Debug("- unit size, no change:", width, height)
		end

		-- Reenable update and clear the _changed flags
		-- If that flag wasn't nil, this causes the header to update
		for _, header in pairs(headers) do
			header:SetAttribute("_ignore", nil)
			if header._changed then
				header._changed = nil
				-- Change some attributes to trigger a refresh in secure code
				header:SetAttribute("_changed", not header:GetAttribute("_changed"))
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
			return self:UpdateLayout("OnUpdate")
		end
	end

	function anchor:TriggerUpdate(event)
		self:Debug("TriggerUpdate", event)
		if not self:GetScript("OnUpdate") then
			delay = 0
			self:SetScript("OnUpdate", self.OnUpdate)
		end
	end

	function anchor:PLAYER_REGEN_DISABLED(event)
		self:Debug("PLAYER_REGEN_DISABLED", event)

		self:UnregisterEvent("PLAYER_REGEN_DISABLED", self.PLAYER_REGEN_DISABLED)

		self:UnregisterEvent("PLAYER_ENTERING_WORLD", self.TriggerUpdate)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", self.TriggerUpdate)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE", self.TriggerUpdate)

		self:UnregisterMessage("OnSettingsModified", self.UpdateLayout)
		self:UnregisterMessage("OnRaidLayoutModified", self.UpdateLayout)
		self:UnregisterMessage("OnPlayerRoleChanged", self.UpdateLayout)

		self:RegisterEvent("PLAYER_REGEN_ENABLED", self.PLAYER_REGEN_ENABLED)

		return self:UpdateLayout(event)
	end

	function anchor:PLAYER_REGEN_ENABLED(event)
		self:Debug("PLAYER_REGEN_ENABLED", event)

		self:UnregisterEvent("PLAYER_REGEN_ENABLED", self.PLAYER_REGEN_ENABLED)

		self:RegisterEvent("PLAYER_REGEN_DISABLED", self.PLAYER_REGEN_DISABLED)

		self:RegisterEvent("PLAYER_ENTERING_WORLD", self.TriggerUpdate)
		self:RegisterEvent("ZONE_CHANGED_NEW_AREA", self.TriggerUpdate)
		self:RegisterEvent("GROUP_ROSTER_UPDATE", self.TriggerUpdate)

		self:RegisterMessage("OnSettingsModified", self.UpdateLayout)
		self:RegisterMessage("OnRaidLayoutModified", self.UpdateLayout)
		self:RegisterMessage("OnPlayerRoleChanged", self.UpdateLayout)

		return self:UpdateLayout(event)
	end

	--------------------------------------------------------------------------------
	-- Go !
	--------------------------------------------------------------------------------
	anchor:PLAYER_REGEN_ENABLED("OnLoad")

end)

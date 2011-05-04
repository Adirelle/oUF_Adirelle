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
	anchor.Debug = oUF_Adirelle.Debug
	anchor:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
	anchor:SetSize(SPACING * 4 + WIDTH * 5, SPACING * 7 + HEIGHT_SMALL * 8)

	anchor:SetAttribute('unitWidth', WIDTH)
	anchor:SetAttribute('unitHeightSmall', HEIGHT_SMALL)
	anchor:SetAttribute('unitHeightBig', HEIGHT)

	oUF_Adirelle.RegisterMovable(anchor, 'raid', "Party/raid frames")

	--------------------------------------------------------------------------------
	-- Helper
	--------------------------------------------------------------------------------

	local function Header_ApplySettings(self, layout, _, force, event)
		if not force and event ~= 'OnRaidLayoutModified' then return end
		local c = layout.Raid
		local spacing, alignment = c.unitSpacing, c.alignment
		self:Debug('Header_ApplySettings', 'orientation=', c.orientation, 'alignment=', alignment, 'unitSpacing=', spacing)
		self:SetAttribute('_ignore', true)
		if c.orientation == "horizontal" then
			self:SetAttribute('xOffset', strmatch(alignment, 'RIGHT') and -spacing or spacing)
			self:SetAttribute('yOffset', 0)
			self:SetAttribute('point', strmatch(alignment, 'RIGHT') or 'LEFT')
			self:SetAttribute('columnAnchorPoint', strmatch(alignment, 'TOP') or 'BOTTOM')
		else
			self:SetAttribute('xOffset', 0)
			self:SetAttribute('yOffset', strmatch(alignment, 'TOP') and -spacing or spacing)
			self:SetAttribute('point', strmatch(alignment, 'TOP') or 'BOTTOM')
			self:SetAttribute('columnAnchorPoint', strmatch(alignment, 'RIGHT') or 'LEFT')
		end

		--  Blizzard headers never clear the button anchors
		for i = 1, huge do
			local button = self:GetAttribute("child"..i)
			if button then
				button:ClearAllPoints()
			else
				break
			end
		end

		self:SetAttribute('_ignore', nil)
		self:SetAttribute('columnSpacing', c.groupSpacing)
	end

	local function SpawnHeader(name, template, ...)
		local header = oUF:SpawnHeader(
			name,
			template,
			nil,
			"point", "LEFT",
			"xOffset", SPACING,
			"sortMethod", "NAME",
			"groupBy", "GROUP",
			"groupingOrder", "1,2,3,4,5,6,7,8",
			"unitsPerColumn", 5,
			"columnSpacing", SPACING,
			"columnAnchorPoint", "BOTTOM",
			'oUF-initialConfigFunction', [===[
				local header = self:GetParent()
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				local width, height = header:GetAttribute('unitWidth'), header:GetAttribute('unitHeight')
				header:CallMethod('Debug', 'oUF-initialConfigFunction:', self:GetName(), header:GetAttribute('heightType'), 'new size:', width, height)
	  		self:SetWidth(width)
	  		self:SetHeight(height)
			]===],
			"unitWidth", WIDTH,
			"unitHeight", HEIGHT_SMALL,
			...
		)
		header.Debug = Debug
		header:SetScale(SCALE)
		header:SetParent(anchor)
		oUF_Adirelle.RegisterVariableLoadedCallback(function(...) return Header_ApplySettings(header, ...) end)
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

	-- Pet visibility
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

	-- Generic size updating
	anchor:SetAttribute('UpdateHeaderSize', [===[
		local headerName, width, height = ...
		if not width or not height then return end
		local header = self:GetFrameRef(headerName)
		local changed = false
		if width ~= header:GetAttribute('unitWidth') then
			header:SetAttribute('unitWidth', width)
			changed = true
		end
		if height ~= header:GetAttribute('unitHeight') then
			header:SetAttribute('unitHeight', height)
			changed = true
		end
		if not changed then return end
		if children then
			table.wipe(children)
		else
			children = newtable()
		end
		header:GetChildList(children)
		header:CallMethod('Debug', 'UpdateHeaderSize', width, height, #children)
		for i, child in pairs(children) do
			child:SetWidth(width)
			child:SetHeight(height)
		end
	]===])

	anchor:SetAttribute('UpdateSize', [===[
		local width = self:GetAttribute('unitWidth')
		self:RunAttribute('UpdateHeaderSize', 'pets', width, self:GetAttribute('unitHeightSmall'))
		local heightType = self:GetAttribute('state-heightType')
		self:RunAttribute('UpdateHeaderSize', 'players', width, self:GetAttribute('unitHeight'..heightType))
	]===])


	-- Player height updating
	anchor:SetAttribute('_onstate-size', "self:RunAttribute('UpdateSize')")
	anchor:SetAttribute('_onstate-heightType', "self:RunAttribute('UpdateSize')")

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
			RegisterStateDriver(anchor, "heightType", "[@raid26,exists] Small; Big")
		else
			anchor:Debug("UpdateHeightDriver, not healer => fixed height")
			UnregisterStateDriver(anchor, "heightType")
			anchor:SetAttribute("heightType", "Small")
		end
	end

	-- Player height updating
	oUF_Adirelle.RegisterPlayerRoleCallback(UpdateHeightDriver)
	UpdateHeightDriver()

	-- Apply settings
	oUF_Adirelle.RegisterVariableLoadedCallback(function(layout, _, force, event)
		if not force and event ~= 'OnRaidLayoutModified' then return end
		local c = layout.Raid
		local width, heightBig, heightSmall = c.width, c.healerHeight, c.height
		local alignment = c.alignment
		players:ClearAllPoints()
		players:SetPoint(alignment, anchor)
		pets:ClearAllPoints()

		-- Update anchors for orientation and alignment
		if c.orientation == "horizontal" then
			anchor:SetSize(c.unitSpacing * 4 + width * 5, c.groupSpacing * 7 + max(heightBig * 5 + heightSmall * 3, heightSmall * 8))
			local vert = strmatch(alignment, "LEFT") or strmatch(alignment, "RIGHT") or ""
			if strmatch(alignment, "TOP") then
				pets:SetPoint("TOP"..vert, players, "BOTTOM"..vert, 0, -2*c.groupSpacing)
			else
				pets:SetPoint("BOTTOM"..vert, players, "TOP"..vert, 0, 2*c.groupSpacing)
			end
		else
			anchor:SetSize(c.groupSpacing * 7 + width * 8, c.unitSpacing * 4 + heightBig * 5)
			local horiz = strmatch(alignment, "TOP") or strmatch(alignment, "BOTTOM") or ""
			if strmatch(alignment, "RIGHT") then
				pets:SetPoint(horiz.."RIGHT", players, horiz.."LEFT", -2*c.groupSpacing, 0)
			else
				pets:SetPoint(horiz.."LEFT", players, horiz.."RIGHT", 2*c.groupSpacing, 0)
			end
		end

		-- Apply pet visibility setting
		if c.showPets.raid25 or c.showPets.raid10 or c.showPets.party then
			RegisterStateDriver(anchor, "pets", format("[@raid26,exists]hide;[@raid11,exists]%s;[@raid6,exists]%s;%s",
				c.showPets.raid25 and "show" or "hide",
				c.showPets.raid10 and "show" or "hide",
				c.showPets.party and "show" or "hide"
			))
		else
			UnregisterStateDriver(anchor, "pets")
			pets:Hide()
		end

		-- Apply sizes
		if width ~= anchor:GetAttribute('unitWidth') or heightBig ~= anchor:GetAttribute('unitHeightBig') or heightSmall ~= anchor:GetAttribute('unitHeightSmall') then
			anchor:SetAttribute('unitWidth', width)
			anchor:SetAttribute('unitHeightBig', heightBig)
			anchor:SetAttribute('unitHeightSmall', heightSmall)
			anchor:SetAttribute('state-size', GetTime())
		end

	end)

end)

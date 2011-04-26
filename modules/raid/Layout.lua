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
	local pairs, ipairs, format = _G.pairs, _G.ipairs, _G.format
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

	anchor:SetAttribute('heightSmall', HEIGHT_SMALL)
	anchor:SetAttribute('heightFull', HEIGHT)

	oUF_Adirelle.RegisterMovable(anchor, 'anchor', "Party/raid frames")

	--------------------------------------------------------------------------------
	-- Helper
	--------------------------------------------------------------------------------
	
	local function Header_ApplySettings(self, layout, theme, first)
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
		for i = 1, math.huge do
			local button = self:GetAttribute("child"..i)
			if button then
				button:ClearAllPoints()
			else
				break
			end			
		end
		
		self:SetAttribute('_ignore', nil)
		self:SetAttribute('columnSpacing', c.groppSpacing)
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
			'oUF-initialConfigFunction', [[
				local header = self:GetParent()
				self:SetAttribute('*type1', 'target')
				self:SetAttribute('*type2', nil)
				self:SetWidth(header:GetAttribute('unitWidth'))
				self:SetHeight(header:GetAttribute('unitHeight'))
			]],
			"unitWidth", WIDTH,
			"unitHeight", HEIGHT_SMALL,
			"minHeight", HEIGHT_SMALL,
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
	
	oUF_Adirelle.RegisterVariableLoadedCallback(function(layout, theme, first) 
		local c = layout.Raid
		local alignment = c.alignment
		oUF_Adirelle.Debug('Alignment:', alignment)
		players:ClearAllPoints()
		players:SetPoint(alignment, anchor)
		pets:ClearAllPoints()
		if c.orientation == "horizontal" then
			anchor:SetSize(c.unitSpacing * 4 + WIDTH * 5, c.groupSpacing * 7 + HEIGHT_SMALL * 8)
			local vert = strmatch(alignment, "LEFT") or strmatch(alignment, "RIGHT") or ""			
			if strmatch(alignment, "TOP") then
				pets:SetPoint("TOP"..vert, players, "BOTTOM"..vert, 0, -2*c.groupSpacing)
			else
				pets:SetPoint("BOTTOM"..vert, players, "TOP"..vert, 0, 2*c.groupSpacing)
			end
		else
			anchor:SetSize(c.groupSpacing * 7 + WIDTH * 8, c.unitSpacing * 4 + HEIGHT * 5)
			local horiz = strmatch(alignment, "TOP") or strmatch(alignment, "BOTTOM") or ""			
			if strmatch(alignment, "RIGHT") then
				pets:SetPoint(horiz.."RIGHT", players, horiz.."LEFT", -2*c.groupSpacing, 0)
			else
				pets:SetPoint(horiz.."LEFT", players, horiz.."RIGHT", 2*c.groupSpacing, 0)
			end
		end
		UpdateHeightDriver()
	end)

end)

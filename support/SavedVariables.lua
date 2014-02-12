--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local ipairs = _G.ipairs
local pairs = _G.pairs
local rawget = _G.rawget
local type = _G.type
--GLOBALS>

-- ------------------------------------------------------------------------------
-- Main SV handling
-- ------------------------------------------------------------------------------

local layout, theme

local LAYOUT_DEFAULTS = {
	profile = {
		anchors = { ['*'] = {} },
		disabled = {
			['*'] = false,
			slim_focus = true
		},
		elements = { ['*'] = true },
		Raid = {
			width = 80,
			height = 20,
			healerHeight = 25,
			smallIconSize = 8,
			bigIconSize = 14,
			alignment = "BOTTOM",
			orientation = "horizontal",
			unitSpacing = 2,
			groupSpacing = 2,
			strictSize = false,
			showTanks = false,
			showPets = {
				['*'] = true,
				battleground = false,
				raid25 = false,
				raid40 = false,
			},
		},
		Single = {
			width = 190,
			heightBig = 47,
			heightSmall = 20,
			Auras = {
				size = 12,
				spacing = 1,
				enlarge = true,
				numBuffs = 12,
				buffFilter = { ['*'] = false },
				numDebuffs = 12,
				debuffFilter = { ['*'] = false },
				sides = {
					['*'] = 'RIGHT',
					pet = 'TOP',
				},
			},
		},
		unitTooltip = {
			enabled = true,
			inCombat = true,
			anchor = "DEFAULT",
			fadeOut = true,
		},
	},
	global = {
		minimapIcon = {},
	},
}

local SharedMedia = oUF_Adirelle.GetLib('LibSharedMedia-3.0')

local THEME_DEFAULTS = {
	profile = {
		statusbar = 'BantoBar',
		fonts = {
			['**'] = {
				name = SharedMedia:GetDefault('font'),
				scale = 1.0,
				flags = "DEFAULT",
			}
		},
		Border = {
			inCombatManaLevel = 0.3,
			oocInRaidManaLevel = 0.9,
			oocManaLevel = 0.6,
		},
		Health = {
			colorTapping = true,
			colorDisconnected = true,
			colorClass = true,
			colorClassNPC = false,
			colorClassPet = false,
			colorReaction = false,
			colorSmooth = true,
		},
		Power = {
			colorTapping = true,
			colorDisconnected = true,
			colorPower = true,
			colorClass = false,
			colorClassNPC = false,
			colorClassPet = false,
			colorReaction = false,
			colorSmooth = false,
		},
		LowHealth = {
			isPercent = true,
			percent = 0.15,
			amount = 10000,
		},
	}
}

local function UpdateProfiles()
	-- Some frame keys have been renamed at some point, move their settings along
	local rename = { arena = "arenas", raid = "anchor", boss = "bosses" }
	for new, old in pairs(rename) do
		if rawget(layout.disabled, old) ~= nil then
			layout.disabled[new] = layout.disabled[old]
			layout.disabled[old] = nil
		end
		if rawget(layout.anchors, old) ~= nil then
			layout.anchors[new] = layout.anchors[old]
			layout.anchors[old] = nil
		end
	end
end

function oUF_Adirelle.SettingsModified(event)
	oUF_Adirelle:SendMessage(event or 'OnSettingsModified', layout, theme)
end

-- Publish the databases and apply the settings
local function OnDatabaseChanged()
	-- Set up our upvalues
	layout, theme = oUF_Adirelle.layoutDB.profile, oUF_Adirelle.themeDB.profile

	-- Update the profile, in case it wasn't loaded since we changed the structure
	UpdateProfiles()

	-- Fire update callbacks
	oUF_Adirelle.SettingsModified()
end

local function ADDON_LOADED(self, event, name)
	if name ~= addonName then return end
	self:UnregisterEvent('ADDON_LOADED', ADDON_LOADED)
	ADDON_LOADED = nil

	-- Initialize the databases
	local layoutDB = LibStub('AceDB-3.0'):New("oUF_Adirelle_Layout", LAYOUT_DEFAULTS, true)
	local themeDB = LibStub('AceDB-3.0'):New("oUF_Adirelle_Theme", THEME_DEFAULTS, true)

	LibStub('LibDualSpec-1.0'):EnhanceDatabase(layoutDB, addonName.." Layout")
	LibStub('LibDualSpec-1.0'):EnhanceDatabase(themeDB, addonName.." Theme")

	self.layoutDB, self.themeDB = layoutDB, themeDB

	-- force initialization
	layout, theme = layoutDB.profile, themeDB.profile

	-- Convert the old database
	if type(_G.oUF_Adirelle_DB) == "table" then
		local old = _G.oUF_Adirelle_DB
		if old.disabled then
			for k,v in pairs(old.disabled) do
				layout.disabled[k] = not not v
			end
		end
		for key, pos in pairs(old) do
			if key ~= "disable" and type(pos) == "table" and (pos.pointFrom or pos.pointTo or pos.refFrame or pos.xOffset or pos.yOffset) then
				for k,v in pairs(pos) do
					layout.anchors[key][k] = v
				end
			end
		end
		_G.oUF_Adirelle_DB = nil
	end

	-- Register AceDB callbacks
	layoutDB.RegisterCallback(self, "OnNewProfile", OnDatabaseChanged)
	layoutDB.RegisterCallback(self, "OnProfileChanged", OnDatabaseChanged)
	layoutDB.RegisterCallback(self, "OnProfileCopied", OnDatabaseChanged)
	layoutDB.RegisterCallback(self, "OnProfileReset", OnDatabaseChanged)
	themeDB.RegisterCallback(self, "OnNewProfile", OnDatabaseChanged)
	themeDB.RegisterCallback(self, "OnProfileChanged", OnDatabaseChanged)
	themeDB.RegisterCallback(self, "OnProfileCopied", OnDatabaseChanged)
	themeDB.RegisterCallback(self, "OnProfileReset", OnDatabaseChanged)

	-- Optional launcher icon on the minimap
	local LibDBIcon = LibStub('LibDBIcon-1.0', true)
	if self.launcher and LibDBIcon then
		self.hasMinimapIcon = true
		LibDBIcon:Register("oUF_Adirelle", self.launcher, layoutDB.global.minimapIcon)
	end

	-- Run
	return OnDatabaseChanged()
end
oUF_Adirelle:RegisterEvent('ADDON_LOADED', ADDON_LOADED)

-- ------------------------------------------------------------------------------
-- Handle optional elements
-- ------------------------------------------------------------------------------

local optionalElements = {
	"Assistant", "Castbar", "ComboPoints", "Combat", "Dragon", "EclipseBar", "Experience",
	"HolyPower", "HealPrediction", "Leader", "LowHealth","MasterLooter",
	"PvP", "PvPTimer", "RaidIcon", "ReadyCheck", "Resting", "RoleIcon", "RuneBar",
	"SmartThreat", "SoulShards", "StatusIcon", "TargetIcon", "ThreatBar",
	"TotemBar", "WarningIcon", "XRange", "Portrait", "CustomClick"
}
oUF_Adirelle.optionalElements = optionalElements

local function UpdateElements(self, event, layout)
	-- Enable/disable the elements
	local changed = false
	for i, name in ipairs(optionalElements) do
		if layout.elements[name] then
			if not self:IsElementEnabled(name) then
				self:EnableElement(name)
				changed = true
			end
		elseif self:IsElementEnabled(name) then
			self:DisableElement(name)
			changed = true
		end
	end
	if changed and event ~= 'OnSettingsModified' then
		self:UpdateAllElements(event)
	end
end

-- ------------------------------------------------------------------------------
-- Handle togglable frames
-- ------------------------------------------------------------------------------

local togglableFrames = {}
oUF_Adirelle.togglableFrames = togglableFrames

local function Frame_GetEnabledSetting(self)
	return not (layout and layout.disabled[self.dbKey])
end

local function Frame_SetEnabledSetting(self, enabled)
	if layout then
		local disabled = not enabled
		if layout.disabled[self.dbKey] == disabled then return end
		layout.disabled[self.dbKey] = disabled
	end
	if enabled then
		self:Enable()
	else
		self:Disable()
	end
end

local function ApplyEnabledSettings(frame)
	if frame:GetEnabledSetting() then
		frame:Enable()
	else
		frame:Disable()
	end
end

-- Register a frame that can be permanently enabled/disabled
function oUF_Adirelle.RegisterTogglableFrame(frame, key, label)
	if frame.GetEnabledSetting then return end

	-- List the frame
	togglableFrames[key] = frame

	-- Setup our properties
	frame.dbKey = key
	frame.label = label

	-- Mix in our methods
	frame.Enable = frame.Enable or frame.Show
	frame.Disable = frame.Disable or frame.Hide
	frame.IsEnabled = frame.IsEnabled or frame.IsShown
	frame.GetEnabledSetting = Frame_GetEnabledSetting
	frame.SetEnabledSetting = Frame_SetEnabledSetting

	-- Setup setting callbacks
	oUF_Adirelle.EmbedMessaging(frame)
	frame:RegisterMessage('OnSettingsModified', ApplyEnabledSettings)

	-- Apply setting immediately if possible
	if layout then
		ApplyEnabledSettings(frame)
	end
end

-- ------------------------------------------------------------------------------
-- Default callback setup for unit frames
-- ------------------------------------------------------------------------------

oUF:RegisterInitCallback(function(self)

	-- Optional element handling
	self:RegisterMessage('OnSettingsModified', UpdateElements)
	self:RegisterMessage('OnElementsModified', UpdateElements)

	-- Update all elements in the ends
	self:RegisterMessage('OnSettingsModified', 'UpdateAllElements')

	-- Immediately update if possible
	if layout and theme then
		self:TriggerMessage('OnSettingsModified', layout, theme)
	end

end)


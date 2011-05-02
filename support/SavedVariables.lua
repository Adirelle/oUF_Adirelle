--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local type, pairs, ipairs, tinsert = _G.type, _G.pairs, _G.ipairs, _G.tinsert
local LibStub = _G.LibStub

-- ------------------------------------------------------------------------------
-- Upvalues and constants
-- ------------------------------------------------------------------------------

local callbacks = {}
local togglableFrames = {}
local layout, theme 

-- Elements that can be disabled
local optionalElements = {
	"Assistant", "Castbar", "ComboPoints", "Combat", "Dragon", "EclipseBar", "Experience",
	"Happiness", "HolyPower", "IncomingHeal", "Leader", "LowHealth","MasterLooter",
	"PvP", "PvPTimer", "RaidIcon", "ReadyCheck", "Resting", "RoleIcon", "RuneBar",
	"SmartThreat", "SoulShards", "StatusIcon", "TargetIcon", "ThreatBar",
	"TotemBar", "WarningIcon", "XRange",
}

oUF_Adirelle.togglableFrames = togglableFrames
oUF_Adirelle.optionalElements = optionalElements

-- ------------------------------------------------------------------------------
-- Callbacks
-- ------------------------------------------------------------------------------

function oUF_Adirelle.ApplySettings(event)
	oUF_Adirelle.Debug('ApplySettings', event)

	-- Call the callbacks
	local first = (event == 'ADDON_LOADED')
	for _, callback in ipairs(callbacks) do
		callback(layout, theme, first, event)
	end
	
	-- Update the togglable frames
	for _, frame in pairs(togglableFrames) do
		-- Enable/disable the frame
		if frame:GetEnabledSetting() then
			frame:Enable()
		else
			frame:Disable()
		end	
	end

	-- Update all the frames
	for _, frame in ipairs(oUF.objects) do
		if frame:IsVisible() then
			frame:ApplySettings(event, first)
		end
	end

end

-- Register a func to be called once the saved variables are loaded
function oUF_Adirelle.RegisterVariableLoadedCallback(callback)
	tinsert(callbacks, callback)
	if layout and theme then
		callback(layout, theme, true)
	end
end

-- ------------------------------------------------------------------------------
-- Initialization and update
-- ------------------------------------------------------------------------------

local LAYOUT_DEFAULTS = {
	profile = {
		anchors = { ['*'] = {} },
		disabled = { ['*'] = false },
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
			showPets = { ['*'] = true },
		},
	},
	global = {
		minimapIcon = {},
	},
}

local THEME_DEFAULTS = {
	profile = {
		statusbar = 'BantoBar',
		Health = {
			colorTapping = true,
			colorDisconnected = true,
			colorHappiness = true,
			colorClass = true,
			colorClassNPC = false,
			colorClassPet = false,
			colorReaction = false,
			colorSmooth = true,
		},
		Power = {
			colorTapping = true,
			colorDisconnected = true,
			colorHappiness = false,
			colorPower = true,
			colorClass = false,
			colorClassNPC = false,
			colorClassPet = false,
			colorReaction = false,
			colorSmooth = false,
		},
		XRange = {
			inRangeAlpha = 1,
			outsideRangeAlpha = 0.4,
		},
	}
}

-- Publish the databases and apply the settings
local function OnDatabaseChanged(event)
	layout, theme = oUF_Adirelle.layoutDB.profile, oUF_Adirelle.themeDB.profile
	return oUF_Adirelle.ApplySettings(event)
end

local frame = _G.CreateFrame("Frame")
frame:SetScript('OnEvent', function(self, event, name)
	if name ~= addonName then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:SetScript('OnEvent', nil)

	-- Initialize the databases
	local layoutDB = LibStub('AceDB-3.0'):New("oUF_Adirelle_Layout", LAYOUT_DEFAULTS, true)
	local themeDB = LibStub('AceDB-3.0'):New("oUF_Adirelle_Theme", THEME_DEFAULTS, true)
	
	LibStub('LibDualSpec-1.0'):EnhanceDatabase(layoutDB, addonName.." Layout")
	LibStub('LibDualSpec-1.0'):EnhanceDatabase(themeDB, addonName.." Theme")
	
	oUF_Adirelle.layoutDB, oUF_Adirelle.themeDB = layoutDB, themeDB
	
	-- First initialization
	layout, theme = oUF_Adirelle.layoutDB.profile, oUF_Adirelle.themeDB.profile

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
	if oUF_Adirelle.launcher and LibDBIcon then
		oUF_Adirelle.hasMinimapIcon = true
		LibDBIcon:Register("oUF_Adirelle", oUF_Adirelle.launcher, layoutDB.global.minimapIcon)
	end
	
	-- Call the callbacks
	return OnDatabaseChanged('ADDON_LOADED')
end)
frame:RegisterEvent('ADDON_LOADED')

-- ------------------------------------------------------------------------------
-- Frame activation handling
-- ------------------------------------------------------------------------------

-- Register a frame so it can be disabled
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

-- Register a frame that can be permanently enabled/disabled
function oUF_Adirelle.RegisterTogglableFrame(frame, key, label)
	if frame.GetEnabledSetting then return end
	togglableFrames[key] = frame
	frame.dbKey = key
	frame.label = label
	frame.Enable = frame.Enable or frame.Show
	frame.Disable = frame.Disable or frame.Hide
	frame.GetEnabledSetting = Frame_GetEnabledSetting
	frame.SetEnabledSetting = Frame_SetEnabledSetting
	if layout then
		if frame:GetEnabledSetting() then
			frame:Enable()
		else
			frame:Disable()
		end
	end
end

-- ------------------------------------------------------------------------------
-- Frame updating
-- ------------------------------------------------------------------------------

oUF:RegisterMetaFunction("ApplySettings", function(self, event, first)
	self:Debug("ApplySettings", event, first)
	
	-- Enable/disable the elements
	for i, name in ipairs(optionalElements) do
		if layout.elements[name] then
			if not self:IsElementEnabled(name) then
				self:EnableElement(name)
			end
		elseif self:IsElementEnabled(name) then
			self:DisableElement(name)
		end
	end
	
	-- Frame specific handler
	if self.OnApplySettings then
		self:OnApplySettings(layout, theme, first, event)
	end
	
	-- Enforce a full update
	return self:UpdateAllElements("event")
end)

-- Used for postponed initialization
oUF:RegisterInitCallback(function(self)
	if layout and theme then
		self:Debug("ApplySettings on init callback")
		self:ApplySettings("OnInit", true)
	end 
end)

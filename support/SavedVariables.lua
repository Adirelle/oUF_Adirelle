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

local callbacks = {}
local db

local DEFAULTS = {
	profile = {
		anchors = { ['*'] = {} },
		disabled = { ['*'] = false },
		elements = { ['*'] = true },
	}
}

local function OnDatabaseChanged(event)
	-- Publish the database
	oUF_Adirelle.db = db

	-- Call all the callbacks
	local profile, first = db.profile, (event == 'ADDON_LOADED')
	for _, callback in ipairs(callbacks) do
		callback(profile, first)
	end
	
	-- Update all the frames
	for _, frame in ipairs(oUF.objects) do
		frame:UpdateAllElements(event)
	end	
end

local frame = _G.CreateFrame("Frame")
frame:SetScript('OnEvent', function(self, event, name)
	if name ~= addonName then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:SetScript('OnEvent', nil)

	-- Initialize the database
	db = LibStub('AceDB-3.0'):New("oUF_Adirelle_DB2", DEFAULTS, true)
	LibStub('LibDualSpec-1.0'):EnhanceDatabase(db, addonName)
	
	-- Convert the old database
	if type(_G.oUF_Adirelle_DB) == "table" then
		local old = _G.oUF_Adirelle_DB
		if old.disabled then
			for k,v in pairs(old.disabled) do
				db.profile.disabled[k] = not not v
			end
		end
		for key, pos in pairs(old) do
			if key ~= "disable" and type(pos) == "table" and (pos.pointFrom or pos.pointTo or pos.refFrame or pos.xOffset or pos.yOffset) then
				for k,v in pairs(pos) do
					db.profile.anchors[key][k] = v
				end
			end
		end
		_G.oUF_Adirelle_DB = nil
	end
	
	-- Register AceDB callbacks
	db.RegisterCallback(self, "OnNewProfile", OnDatabaseChanged)
	db.RegisterCallback(self, "OnProfileChanged", OnDatabaseChanged)
	db.RegisterCallback(self, "OnProfileCopied", OnDatabaseChanged)
	db.RegisterCallback(self, "OnProfileReset", OnDatabaseChanged)
	
	-- Call the callbacks
	return OnDatabaseChanged('ADDON_LOADED')
end)
frame:RegisterEvent('ADDON_LOADED')

-- Register a func to be called once the saved variables are loaded
function oUF_Adirelle.RegisterVariableLoadedCallback(callback)
	tinsert(callbacks, callback)
	if db then
		callback(db.profile)
	end
end

-- Register a frame so it can be disabled
local function Frame_GetEnabledSetting(self)
	return not (db and db.profile.disabled[self.dbKey])
end

local function Frame_SetEnabledSetting(self, enabled)
	if db then
		local disabled = not enabled
		if db.profile.disabled[self.dbKey] == disabled then return end
		db.profile.disabled[self.dbKey] = disabled
	end
	if enabled then
		self:Enable()
	else
		self:Disable()
	end
end

local togglableFrames = {}
oUF_Adirelle.togglableFrames = togglableFrames

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
end

oUF_Adirelle.RegisterVariableLoadedCallback(function()
	for key, frame in pairs(togglableFrames) do
		if frame:GetEnabledSetting() then
			frame:Enable()
		else
			frame:Disable()
		end
	end
end)

-- Elements that can be disabled
local optionalElements = {
	"Assistant",
	"Castbar",
	"ComboPoints",
	"Dragon",
	"EclipseBar",
	"Experience",
	"Happiness",
	"HolyPower",
	"IncomingHeal",
	"Leader",
	"LowHealth",
	"MasterLooter",
	"PvP",
	"PvPTimer",
	"RaidIcon",
	"ReadyCheck",
	"Resting",
	"RoleIcon",
	"RuneBar",
	"SmartThreat",
	"SoulShards",
	"StatusIcon",
	"TargetIcon",
	"ThreatBar",
	"TotemBar",
	"WarningIcon",
	"XRange",
}
oUF_Adirelle.optionalElements = optionalElements

local function ApplyElementSettings(self)
	local changed = false
	for i, name in ipairs(optionalElements) do
		if self[name] then
			if db.profile.elements[name] then
				if not self:IsElementEnabled(name) then
					self:EnableElement(name)
					changed = true
				end
			elseif self:IsElementEnabled(name) then
				self:DisableElement(name)
				changed = true
			end
		end
	end
	if changed then
		self:UpdateAllElements("OnElementSettingChanged")
	end
end

oUF:RegisterInitCallback(ApplyElementSettings)

function oUF_Adirelle.ApplyElementSettings()
	for j, frame in ipairs(oUF.objects) do
		ApplyElementSettings(frame)
	end
end

oUF_Adirelle.RegisterVariableLoadedCallback(oUF_Adirelle.ApplyElementSettings)


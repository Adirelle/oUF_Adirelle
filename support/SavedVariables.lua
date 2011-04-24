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
	}
}

local function OnDatabaseChanged(event)
	-- Publish the database
	oUF_Adirelle.db = db

	-- Call all the callbacks
	for _, callback in ipairs(callbacks) do
		callback(db.profile)
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
			if key ~= "disable" and type(pos) == "table" and (pos.pointFrom or pos.pointTo or point.refFrame or point.xOffset or point.yOffset) then
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


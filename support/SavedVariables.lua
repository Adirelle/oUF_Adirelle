--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local ipairs, tinsert = _G.ipairs, _G.tinsert

local callbacks = {}
local db

local frame = _G.CreateFrame("Frame")
frame:SetScript('OnEvent', function(self, event, name)
	if name ~= addonName then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:SetScript('OnEvent', nil)

	-- Initialize the database
	_G.oUF_Adirelle_DB = _G.oUF_Adirelle_DB or {}
	db = _G.oUF_Adirelle_DB
	if not db.disabled then db.disabled = {} end

	-- Call the callbacks
	for _, callback in ipairs(callbacks) do
		callback(db)
	end
	callbacks = nil
	
	-- Update all the frames
	for _, frame in ipairs(oUF.objects) do
		frame:UpdateAllElements("ADDON_LOADED")
	end
end)
frame:RegisterEvent('ADDON_LOADED')

-- Register a func to be called once the saved variables are loaded
function oUF_Adirelle.RegisterVariableLoadedCallback(callback)
	if db then
		callback(db)
	else
		tinsert(callbacks, callback)
	end
end

-- Register a frame so it can be disabled
local function Frame_GetEnabledSetting(self)
	return not (db and db.disabled[self.dbKey])
end

local function Frame_SetEnabledSetting(self, enabled)
	if db then
		local disabled = not enabled
		if db.disabled[self.dbKey] == disabled then return end
		db.disabled[self.dbKey] = disabled
	end
	if enabled then
		self:Enable()
	else
		self:Disable()
	end
end

-- Register a frame that can be permanently enabled/disabled
function oUF_Adirelle.RegisterTogglableFrame(frame, key)
	if frame.GetEnabledSetting then return end
	frame.dbKey = key
	frame.Enable = frame.Enable or frame.Show
	frame.Disable = frame.Disable or frame.Hide
	frame.GetEnabledSetting = Frame_GetEnabledSetting
	frame.SetEnabledSetting = Frame_SetEnabledSetting
	oUF_Adirelle.RegisterVariableLoadedCallback(function() if not frame:GetEnabledSetting() then frame:Disable() end end)
end

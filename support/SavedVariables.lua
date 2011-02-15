--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
local _G, addonName, ns = _G, ...
setfenv(1, ns)

local callbacks = {}
local db

local frame = CreateFrame("Frame")
frame:SetScript('OnEvent', function(self, event, name)
	if name ~= addonName then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:SetScript('OnEvent', nil)

	-- Initialize the database
	_G.oUF_Adirelle_DB = _G.oUF_Adirelle_DB or {}
	db = _G.oUF_Adirelle_DB

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
function RegisterVariableLoadedCallback(callback)
	if db then
		callback(db)
	else
		tinsert(callbacks, callback)
	end
end

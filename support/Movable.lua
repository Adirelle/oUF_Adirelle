--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local addonName = ...

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

local libmovable = GetLib('LibMovable-1.0')
if libmovable then

	-- Function used until our SV is loaded
	local postponed = {}
	RegisterMovable = function(frame, key, label, mask)
		postponed[frame] = function() return RegisterMovable(frame, key, label, mask) end
	end

	-- Load the SV and register postponed movables
	local frame = CreateFrame("Frame")
	frame:SetScript('OnEvent', function(self, event, name)
		if name ~= addonName then return end
		self:UnregisterEvent('ADDON_LOADED')
		self:SetScript('OnEvent', nil)

		-- Initialize the database
		_G.oUF_Adirelle_DB = _G.oUF_Adirelle_DB or {}
		local db = _G.oUF_Adirelle_DB

		-- replace RegisterMovable with a function that actually registers the frame
		RegisterMovable = function(frame, key, label, mask)
			Debug('Registering movable', frame, key, label, mask)
			db[key] = db[key] or {}
			libmovable.RegisterMovable(addonName, frame, db[key], label, mask)
		end

		-- process already registered frames
		for _, func in pairs(postponed) do func()	end
		postponed = nil
	end)
	frame:RegisterEvent('ADDON_LOADED')

	-- Register the slash command
	_G.SLASH_OUFADIRELLE1 = "/ouf_adirelle"
	_G.SLASH_OUFADIRELLE2 = "/oufa"
	_G.SlashCmdList.OUFADIRELLE = function()
		if libmovable.IsLocked(addonName) then
			libmovable.Unlock(addonName)
		else
			libmovable.Lock(addonName)
		end
	end
else
	-- Do not care about this
	function RegisterMovable() end
end

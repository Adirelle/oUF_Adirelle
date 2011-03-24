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
	
	RegisterVariableLoadedCallback(function(db)

		-- replace RegisterMovable with a function that actually registers the frame
		RegisterMovable = function(frame, key, label, mask)
			frame:Debug('Registering movable', key, label, mask)
			db[key] = db[key] or {}

			if frame.Enable and frame.Disable then
				if not db.disabled then db.disabled = {} end
				local t = db.disabled
				frame.LM10_IsEnabled = function() return not t[key] end
				frame.LM10_Enable = function() t[key] = nil frame:Enable() end
				frame.LM10_Disable = function() t[key] = true frame:Disable() end
				if t[key] then
					frame:Debug('Disabled')
					frame:Disable()
				end
			end
			
			libmovable.RegisterMovable(addonName, frame, db[key], label, mask)
		end

		-- process already registered frames
		for _, func in pairs(postponed) do func()	end
		postponed = nil
	end)

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

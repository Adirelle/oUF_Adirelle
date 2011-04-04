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
	
		local function LM10_Enable(frame) return frame:SetEnabledSetting(true) end
		local function LM10_Disable(frame) return frame:SetEnabledSetting(false) end
		
		-- replace RegisterMovable with a function that actually registers the frame
		RegisterMovable = function(frame, key, label, mask)
			frame:Debug('Registering movable', key, label, mask)
			db[key] = db[key] or {}

			RegisterTogglableFrame(frame, key)
			frame.LM10_IsEnabled = frame.GetEnabledSetting
			frame.LM10_Enable = LM10_Enable
			frame.LM10_Disable = LM10_Disable
			
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

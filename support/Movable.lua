--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local addonName, oUF_Adirelle = ...

local libmovable = oUF_Adirelle.GetLib('LibMovable-1.0')
if libmovable then

	-- Function used until our SV is loaded
	local postponed = {}
	oUF_Adirelle.RegisterMovable = function(frame, key, label, mask)
		postponed[frame] = function() return oUF_Adirelle.RegisterMovable(frame, key, label, mask) end
	end
	
	oUF_Adirelle.RegisterVariableLoadedCallback(function(db)
	
		local function LM10_Enable(frame) return frame:SetEnabledSetting(true) end
		local function LM10_Disable(frame) return frame:SetEnabledSetting(false) end
		
		-- replace RegisterMovable with a function that actually registers the frame
		oUF_Adirelle.RegisterMovable = function(frame, key, label, mask)
			frame:Debug('Registering movable', key, label, mask)
			db[key] = db[key] or {}

			oUF_Adirelle.RegisterTogglableFrame(frame, key)
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
	function oUF_Adirelle.RegisterMovable() end
end

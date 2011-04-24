--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

local pairs, unpack = _G.pairs, _G.unpack

local libmovable = oUF_Adirelle.GetLib('LibMovable-1.0')
if libmovable then

	local db

	-- Functions used once the settings are loaded	
	local function LM10_Enable(frame) return frame:SetEnabledSetting(true) end
	local function LM10_Disable(frame) return frame:SetEnabledSetting(false) end
	local function DoRegister(frame, key, label, mask)
		frame:Debug('Registering movable', key, label, mask)

		oUF_Adirelle.RegisterTogglableFrame(frame, key)
		frame.LM10_IsEnabled = frame.GetEnabledSetting
		frame.LM10_Enable = LM10_Enable
		frame.LM10_Disable = LM10_Disable
		
		libmovable.RegisterMovable(addonName, frame, db[key], label, mask)
	end

	-- Function used until the settings are loaded
	local postponed = {}
	oUF_Adirelle.RegisterMovable = function(frame, key, label, mask)
		postponed[frame] = { key, label, mask }
	end
	
	-- Callback on database loaded/changed
	oUF_Adirelle.RegisterVariableLoadedCallback(function(profile)
	
		-- Get the anchor settings
		db = profile.anchors
		
		if oUF_Adirelle.RegisterMovable ~= DoRegister then
			-- First initialization		
						
			-- Replace RegisterMovable with the function that actually registers the frame
			oUF_Adirelle.RegisterMovable = DoRegister
			
			-- Process already registered frames
			for frame, params in pairs(postponed) do
				DoRegister(frame, unpack(params))
			end
			postponed = nil			
			
		else
			-- Already initialized, only apply the new layout
			libmovable.UpdateLayout(addonName)
		end		
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

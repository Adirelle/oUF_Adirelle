--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

oUF:Factory(function()

	local function Enable(self)
		RegisterUnitWatch(self, true)
	end
	
	local function PLAYER_ENTERING_WORLD(self)
		if select(2, IsInInstance()) == "arena" and (not self.LM10_IsEnabled or self:LM10_IsEnabled()) then
			self:Enable()
		else
			self:Disable()
		end
	end

	local function Spawn(unit, label, ...)
		-- Spawn the frame
		local frame = oUF:Spawn(unit:lower(), "oUF_Adirelle_"..unit)

		-- Position it and make it movable
		frame:SetPoint(...)
		RegisterMovable(frame, unit, label)

		-- Show the frame when the unit comes to existence, never hide, always update
		SecureHandlerWrapScript(frame, "OnAttributeChanged", frame, [=[
			if name == "state-unitexists" then
				if value then
					control:CallMethod("Debug", "unit appeared")
					if not self:IsShown() then
						self:Show() 
					else
						control:CallMethod("UpdateAllElements", "OnUnitExists")
					end
				else
					control:CallMethod("Debug", "unit disappeared")
				end
			end
		]=])

		-- Use PEW to enable/disable the frame, using our own made :Enable
		frame.Enable = Enable
		frame:RegisterEvent('PLAYER_ENTERING_WORLD', PLAYER_ENTERING_WORLD)
		
		-- Call it at least once, in case of LoD
		PLAYER_ENTERING_WORLD(frame, 'OnSpawn')

		return frame
	end

	oUF:SetActiveStyle("Adirelle_Single_Right")
	local anchor, gap = oUF_Adirelle_Focus, 30
	for index = 1, 5 do
		anchor, gap = Spawn("Arena"..index, format("Arena enemy #%d", index), "BOTTOM", anchor, "TOP", 0, gap), 40
	end

	oUF:SetActiveStyle("Adirelle_Single_Health")
	for index = 1, 5 do
		Spawn("ArenaPet"..index, format("Arena enemy pet #%d", index), "BOTTOM", _G["oUF_Adirelle_Arena"..index], "TOP", 0, 5)
	end

	-- Prevent loading of Blizzard arena frames
	_G.Arena_LoadUI = function() end
	if _G.ArenaEnemyFrames then
		_G.ArenaEnemyFrames:Hide()
		_G.ArenaEnemyFrames.Show = _G.ArenaEnemyFrames.Hide
	end
end)

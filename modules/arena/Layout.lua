--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

oUF:Factory(function()

	local frames = {}

	local function Enable(self)
		RegisterUnitWatch(self, true)
	end

	local function Disable(self)
		UnregisterUnitWatch(self)
		self:SetAttribute('state-unitexists', false)
		self:Hide()
	end

	local function Update(self, event)
		if select(2, IsInInstance()) == "arena" and (not self.LM10_IsEnabled or self:LM10_IsEnabled()) then
			self:Enable()
			self:Debug('Enabled on', event)
		else
			self:Disable()
			self:Debug('Disabled on', event)
		end
	end
	
	local monitor = CreateFrame("Frame")
	monitor:SetScript('OnEvent', function(self, ...)
		for frame in pairs(frames) do
			Update(frame, ...)
		end
	end)
	monitor:RegisterEvent('PLAYER_ENTERING_WORLD')
	monitor:RegisterEvent('ZONE_CHANGED_NEW_AREA')

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
					if not self:IsShown() then
						self:Show()
					else
						control:CallMethod("UpdateAllElements", "OnUnitExists")
					end
				end
			end
		]=])

		-- Put our handlers in place
		frame.Enable, frame.Disable = Enable, Disable

		-- Update at lease once
		Update(frame, 'OnSpawn')

		-- Register for future updates
		frames[frame] = true

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

--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

oUF:Factory(function()
	--<GLOBALS
	local GetScreenWidth = assert(_G.GetScreenWidth)
	local IsInInstance = assert(_G.IsInInstance)
	local RegisterUnitWatch = assert(_G.RegisterUnitWatch)
	local SecureHandlerWrapScript = assert(_G.SecureHandlerWrapScript)
	local select = assert(_G.select)
	local UnregisterUnitWatch = assert(_G.UnregisterUnitWatch)
	--GLOBALS>

	local mmax = assert(_G.math.max)

	local offset = 250 + mmax(0, GetScreenWidth() - 1280) / 5

	local anchor = oUF_Adirelle.CreatePseudoHeader(
		"oUF_Adirelle_Arena",
		"arena",
		"Arena enemy frames",
		190,
		5 * (47 + 40) - 15,
		"BOTTOMLEFT",
		_G.UIParent,
		"BOTTOM",
		offset,
		385
	)

	function anchor:ShouldEnable()
		return select(2, IsInInstance()) == "arena"
	end
	anchor:RegisterEvent("PLAYER_ENTERING_WORLD")
	anchor:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	local function ArenaUnit_Enable(self)
		RegisterUnitWatch(self, true)
	end

	local function ArenaUnit_Disable(self)
		UnregisterUnitWatch(self)
		self:SetAttribute("state-unitexists", false)
		self:Hide()
	end

	local ArenaUnit_OnAttributeChanged = [=[
		if name == "state-unitexists" then
			if value then
				if not self:IsShown() then
					self:Show()
				else
					control:CallMethod("UpdateAllElements", "OnUnitExists")
				end
			end
		end
	]=]

	for index = 1, 5 do
		oUF:SetActiveStyle("Adirelle_Single_Right")
		local frame = oUF:Spawn("arena" .. index, "oUF_Adirelle_Arena" .. index)
		frame:SetParent(anchor)
		frame:SetPoint("BOTTOM", anchor, "BOTTOM", 0, (index - 1) * (40 + 47))
		frame.Enable, frame.Disable = ArenaUnit_Enable, ArenaUnit_Disable
		SecureHandlerWrapScript(frame, "OnAttributeChanged", frame, ArenaUnit_OnAttributeChanged)
		anchor:AddFrame(frame)

		oUF:SetActiveStyle("Adirelle_Single_Health")
		local petFrame = oUF:Spawn("arenapet" .. index, "oUF_Adirelle_ArenaPet" .. index)
		petFrame:SetParent(anchor)
		petFrame:SetPoint("BOTTOM", frame, "TOP", 0, 5)
		anchor:AddFrame(frame)
	end

	-- Prevent loading of Blizzard arena frames
	_G.Arena_LoadUI = function()
	end
	if _G.ArenaEnemyFrames then
		_G.ArenaEnemyFrames:Hide()
		_G.ArenaEnemyFrames.Show = _G.ArenaEnemyFrames.Hide
	end
end)

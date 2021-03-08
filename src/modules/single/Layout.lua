--[=[
Adirelle's oUF layout
(c) 2009-2016 Adirelle (adirelle@gmail.com)

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

local _G = _G
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

oUF:Factory(function()
	--<GLOBALS
	local next = _G.next
	local select = _G.select
	local max = _G.max
	local GetScreenWidth = _G.GetScreenWidth
	--GLOBALS>

	local frames = {}

	local function Spawn(style, unit, ...)
		oUF:SetActiveStyle(style)
		local realUnit = unit:lower()
		local frame = oUF:Spawn(realUnit, "oUF_Adirelle_" .. unit)
		frames[frame] = unit
		if select("#", ...) > 0 then
			return frame, Spawn(style, ...)
		else
			return frame
		end
	end

	local player, pet = Spawn("Adirelle_Single", "Player", "Pet")
	local target, focus = Spawn("Adirelle_Single_Right", "Target", "Focus")
	local targettarget, pettarget, focusTarget = Spawn("Adirelle_Single_Health", "TargetTarget", "PetTarget", "FocusTarget") -- luacheck: no max line length

	local offset = 250 + max(0, GetScreenWidth() - 1280) / 5

	player:SetPoint("BOTTOMRIGHT", _G.UIParent, "BOTTOM", -offset, 180)
	pet:SetPoint("BOTTOM", player, "TOP", 0, 15)
	pettarget:SetPoint("BOTTOM", pet, "TOP", 0, 15 + 22)
	target:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOM", offset, 180)
	targettarget:SetPoint("BOTTOM", target, "TOP", 0, 15)
	focus:SetPoint("BOTTOM", targettarget, "TOP", 0, 15)
	focusTarget:SetPoint("BOTTOM", focus, "TOP", 0, 15)

	for frame, unit in next, frames do
		oUF_Adirelle.RegisterMovable(frame, unit, unit .. " frame")
	end

	-- Slim focus frame, by special request from Iuchiban-Krasus (EU)
	oUF:SetActiveStyle("Adirelle_Single_Health")
	local slim_focus = oUF:Spawn("focus", "oUF_Adirelle_SlimFocus")
	slim_focus:SetPoint("BOTTOM", targettarget, "TOP", 0, 15)
	oUF_Adirelle.RegisterMovable(slim_focus, "slim_focus", "Slim focus frame")

	frames = nil -- luacheck: ignore
end)

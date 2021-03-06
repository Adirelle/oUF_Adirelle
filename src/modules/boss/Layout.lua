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

oUF_Adirelle.oUF:Factory(function()
	--<GLOBALS
	local GetScreenWidth = assert(_G.GetScreenWidth, "_G.GetScreenWidth is undefined")
	local IsInInstance = assert(_G.IsInInstance, "_G.IsInInstance is undefined")
	--GLOBALS>

	local mmax = assert(_G.math.max)

	local offset = 250 + mmax(0, GetScreenWidth() - 1280) / 5

	local anchor = oUF_Adirelle.CreatePseudoHeader(
		"oUF_Adirelle_Bosses",
		"boss",
		"Boss frames",
		190,
		47 * 4 + 15 * 3,
		"BOTTOMLEFT",
		_G.UIParent,
		"BOTTOM",
		offset,
		385
	)

	function anchor:ShouldEnable()
		local _, iType = IsInInstance()
		return iType == "raid" or iType == "party"
	end
	anchor:RegisterEvent("PLAYER_ENTERING_WORLD")
	anchor:RegisterEvent("ZONE_CHANGED_NEW_AREA")

	oUF:SetActiveStyle("Adirelle_Single_Right")
	for index = 1, _G.MAX_BOSS_FRAMES do
		local frame = oUF:Spawn("boss" .. index, "oUF_Adirelle_Boss" .. index)
		frame:SetParent(anchor)
		frame:SetPoint("BOTTOM", anchor, "BOTTOM", 0, (47 + 15) * (index - 1))
		anchor:AddFrame(frame)
	end

end)

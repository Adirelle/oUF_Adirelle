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

--<GLOBALS
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

oUF:RegisterMetaFunction("CreateTicker", function(frame, delay, tick, ...)
	local args = { ... }
	local callback = function()
		return tick(frame, unpack(args))
	end

	local ticker = frame:CreateAnimationGroup()
	ticker:SetLooping("REPEAT")
	ticker:SetScript("OnPlay", callback)

	local animation = ticker:CreateAnimation("Animation")
	animation:SetDuration(delay)
	animation:SetScript("OnFinished", callback)

	return ticker
end)

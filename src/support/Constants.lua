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

--<GLOBALS
--GLOBALS>

oUF_Adirelle.GAP = 2
oUF_Adirelle.BORDER_WIDTH = 2
oUF_Adirelle.TEXT_MARGIN = 2
oUF_Adirelle.AURA_SIZE = 22

oUF_Adirelle.FRAME_MARGIN = oUF_Adirelle.BORDER_WIDTH + oUF_Adirelle.GAP

oUF_Adirelle.borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]],
	edgeSize = oUF_Adirelle.BORDER_WIDTH,
}

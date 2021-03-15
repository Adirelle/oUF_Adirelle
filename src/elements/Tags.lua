--[=[
Adirelle's oUF layout
(c) 2021 Adirelle (adirelle@gmail.com)

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
local C_IncomingSummon = assert(_G.C_IncomingSummon)
local format = assert(_G.format)
local tostring = assert(_G.tostring)
local UnitHasIncomingResurrection = assert(_G.UnitHasIncomingResurrection)
local UnitIsConnected = assert(_G.UnitIsConnected)
local UnitIsDead = assert(_G.UnitIsDead)
local UnitIsGhost = assert(_G.UnitIsGhost)
--GLOBALS>

local SummonStatus = _G.Enum.SummonStatus

local function toStr(val)
	return val and tostring(val) or ""
end

local function tex(d)
	if d.height == 0 and not d.width and d.left and d.right and d.top and d.bottom then
		d.width = (d.right - d.left) / (d.bottom - d.top)
	end
	return format(
		"|T%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s|t",
		d.path,
		toStr(d.height),
		toStr(d.width),
		toStr(d.offsetX),
		toStr(d.offsetY),
		toStr(d.textureWidth),
		toStr(d.textureHeight),
		toStr(d.left),
		toStr(d.right),
		toStr(d.top),
		toStr(d.bottom),
		toStr(d.r and (d.r * 255)),
		toStr(d.g and (d.g * 255)),
		toStr(d.b and (d.b * 255))
	)
end

local icons = {
	dead = {
		path = [[Interface\Navigation\IngameNavigationUI]],
		height = 0,
		textureWidth = 64,
		textureHeight = 64,
		left = 2,
		right = 25,
		top = 2,
		bottom = 32,
	},
	ghost = {
		path = [[Interface\MINIMAP\ObjectIconsAtlas]],
		height = 0,
		textureWidth = 1024,
		textureHeight = 512,
		left = 252,
		right = 283,
		top = 77,
		bottom = 110,
	},
	disconnected = {
		path = [[Interface\CHARACTERFRAME\Disconnect-Icon]],
		height = 0,
		textureWidth = 64,
		textureHeight = 64,
		left = 15,
		right = 47,
		top = 11,
		bottom = 49,
	},
	resurrection = {
		path = [[Interface\RAIDFRAME\Raid-Icon-Rez]],
		height = 0,
		textureWidth = 64,
		textureHeight = 64,
		left = 5,
		right = 58,
		top = 2,
		bottom = 59,
	},
}

local summonTexture = {
	[SummonStatus.Pending] = [[Interface\RAIDFRAME\Raid-Icon-SummonPending]],
	[SummonStatus.Accepted] = [[Interface\RAIDFRAME\Raid-Icon-SummonAccepted]],
	[SummonStatus.Declined] = [[Interface\RAIDFRAME\Raid-Icon-SummonDeclined]],
}

oUF.Tags.Methods.statusIcon = function(unit, realUnit)
	unit = realUnit or unit
	if not UnitIsConnected(unit) then
		return tex(icons.disconnected)
	end
	if UnitHasIncomingResurrection(unit) then
		return tex(icons.resurrection)
	end
	if UnitIsDead(unit) then
		return tex(icons.dead)
	end
	if UnitIsGhost(unit) then
		return tex(icons.ghost)
	end
	local summon = C_IncomingSummon.IncomingSummonStatus(unit)
	local texture = summonTexture[summon or 0]
	if not texture then
		return
	end
	return tex({
		path = texture,
		textureWidth = 32,
		textureHeight = 32,
		left = 7,
		right = 27,
		top = 7,
		bottom = 25,
	})
end

oUF.Tags.Events.statusIcon = "UNIT_HEALTH UNIT_CONNECTION INCOMING_RESURRECT_CHANGED INCOMING_SUMMON_CHANGED"

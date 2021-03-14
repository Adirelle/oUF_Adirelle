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

local addonName, private = ...
local _G, assert = _G, _G.assert
local oUF = assert(private.oUF, "oUF is undefined in oUF_Adirelle namespace")

-- Export our namespace for standalone modules
local oUF_Adirelle = { oUF = oUF }
_G.oUF_Adirelle = oUF_Adirelle

--<GLOBALS
local next = assert(_G.next)
local print = assert(_G.print)
--GLOBALS>

-- Debugging stuff
local AdiDebug = _G.AdiDebug
if AdiDebug then
	oUF_Adirelle.Debug = AdiDebug:GetSink("oUF_Adirelle")
	AdiDebug:Embed(oUF, "oUF_Adirelle")
else
	oUF_Adirelle.Debug = function()
	end
	oUF.Debug = oUF_Adirelle.Debug
end
oUF:RegisterMetaFunction("Debug", oUF.Debug)

-- Version query command
_G.SLASH_OUFADIRELLEVER1 = "/ouf_adirelle_ver"
_G.SLASH_OUFADIRELLEVER2 = "/oufa_ver"
_G.SLASH_OUFADIRELLEVER3 = "/oufav"

local versions = {}

oUF_Adirelle.VERSION = "v" .. _G.GetAddOnMetadata(addonName, "version")
--@debug@
oUF_Adirelle.VERSION = "developer version"
--@end-debug@

_G.SlashCmdList.OUFADIRELLEVER = function()
	print("oUF_Adirelle " .. oUF_Adirelle.VERSION)
	for major, minor in next, versions do
		print("- " .. major .. " v" .. minor)
	end
end

-- Library helper
local LibStub = _G.LibStub
if LibStub then
	function oUF_Adirelle.GetLib(major)
		local lib, minor = LibStub(major, true)
		if lib then
			versions[major] = minor
			return lib, minor
		end
	end
else
	oUF_Adirelle.GetLib = function()
	end
end

-- Configuration toggle

_G.SLASH_OUFADIRELLE1 = "/ouf_adirelle"
_G.SLASH_OUFADIRELLE2 = "/oufa"
_G.SlashCmdList.OUFADIRELLE = function(arg, ...)
	if oUF_Adirelle.ToggleLock and arg == "lock" then
		return oUF_Adirelle.ToggleLock()
	end
	if arg then
		oUF_Adirelle.Config:Open(arg, ...)
	else
		oUF_Adirelle.Config:Toggle()
	end
end

local LDB = oUF_Adirelle.GetLib("LibDataBroker-1.1")
if LDB then
	oUF_Adirelle.launcher = LDB:NewDataObject(addonName, {
		type = "launcher",
		icon = [[Interface\Icons\Ability_Vehicle_ShellShieldGenerator]],
		tocname = addonName,
		label = addonName,
		OnClick = function(_, button)
			if oUF_Adirelle.ToggleLock and button == "LeftButton" then
				return oUF_Adirelle.ToggleLock()
			end
			oUF_Adirelle.Config:Toggle()
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip then
				tooltip = _G.GameTooltip
			end
			tooltip:AddLine("oUF_Adirelle " .. oUF_Adirelle.VERSION, 1, 1, 1)
			if oUF_Adirelle.ToggleLock then
				tooltip:AddLine("Left click to (un)lock the frames.")
			end
			tooltip:AddLine("Right click to open the configuration window.")
		end,
	})
end

-- Some common "constants"

-- Get player class once
local _
_, oUF_Adirelle.playerClass = _G.UnitClass("player")

-- Frame background
oUF_Adirelle.backdrop = {
	--bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	bgFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]],
	bgAlpha = 0.85,
	tile = true,
	tileSize = 16,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- Glow border backdrop
oUF_Adirelle.glowBorderBackdrop = {
	edgeFile = [[Interface\AddOns\oUF_Adirelle\media\glowborder]],
	edgeSize = 4,
	alpha = 1,
--edgeFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]], edgeSize = 2, alpha = 0.5,
}

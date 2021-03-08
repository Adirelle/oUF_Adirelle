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

local _G, parent, private = _G, ...
local assert = _G.assert
local oUF = assert(private.oUF, "oUF is undefined in " .. parent .. " namespace")

-- Export our namespace for standalone modules
local oUF_Adirelle = { oUF = oUF }
_G.oUF_Adirelle = oUF_Adirelle

--<GLOBALS
local IsAddOnLoaded = _G.IsAddOnLoaded
local LoadAddOn = _G.LoadAddOn
local next = _G.next
local print = _G.print
local strlower = _G.strlower
local strmatch = _G.strmatch
local tonumber = _G.tonumber
--GLOBALS >

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

oUF_Adirelle.VERSION = "v" .. _G.GetAddOnMetadata(parent, "version")
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

-- DiminishingReturns support
function oUF_Adirelle.RegisterDiminishingReturns()
	_G.DiminishingReturns:DeclareOUF(parent, oUF)
end

-- Configuration

local function ToggleConfig(arg, button)
	if oUF_Adirelle.ToggleLock and (arg == "lock" or button == "LeftButton") then
		return oUF_Adirelle.ToggleLock()
	end
	if not IsAddOnLoaded("oUF_Adirelle_Config") then
		LoadAddOn("oUF_Adirelle_Config")
	end
	if oUF_Adirelle.ToggleConfig then
		oUF_Adirelle.ToggleConfig()
	end
end

_G.SLASH_OUFADIRELLE1 = "/ouf_adirelle"
_G.SLASH_OUFADIRELLE2 = "/oufa"
_G.SlashCmdList.OUFADIRELLE = ToggleConfig

_G.SLASH_OUFALOWHEALTH1 = "/oufa_health"
_G.SLASH_OUFALOWHEALTH2 = "/oufah"
_G.SlashCmdList.OUFALOWHEALTH = function(arg)
	local number, suffix = strmatch(strlower(arg), "(%d+)([%%k]?)")
	local threshold = tonumber(number)
	if threshold then
		local db = oUF_Adirelle.themeDB.profile.LowHealth
		if suffix == "%" then
			if threshold >= 5 and threshold <= 95 then
				db.isPercent, db.percent = true, threshold / 100
				return oUF_Adirelle.SettingsModified("OnThemeModified")
			end
		elseif threshold > 0 then
			db.isPercent, db.amount = false, threshold * (suffix == "k" and 1000 or 1)
			return oUF_Adirelle.SettingsModified("OnThemeModified")
		end
	end
	if not IsAddOnLoaded("oUF_Adirelle_Config") then
		LoadAddOn("oUF_Adirelle_Config")
	end
	if oUF_Adirelle.ToggleConfig then
		oUF_Adirelle.ToggleConfig("theme", "warningThresholds")
	end
end

local LDB = oUF_Adirelle.GetLib("LibDataBroker-1.1")
if LDB then
	oUF_Adirelle.launcher = LDB:NewDataObject(parent, {
		type = "launcher",
		icon = [[Interface\Icons\Ability_Vehicle_ShellShieldGenerator]],
		tocname = parent,
		label = parent,
		OnClick = ToggleConfig,
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

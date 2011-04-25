--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, parent, private = _G, ...
local assert = _G.assert
local oUF = assert(private.oUF, "oUF is undefined in "..parent.." namespace")

-- Export our namespace for standalone modules
local oUF_Adirelle = { oUF = oUF }
_G.oUF_Adirelle = oUF_Adirelle

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local print, next = _G.print, _G.next

-- Debugging stuff
local AdiDebug = _G.AdiDebug
if AdiDebug then
	oUF_Adirelle.Debug =  AdiDebug:GetSink("oUF_Adirelle")
	AdiDebug:Embed(oUF, "oUF_Adirelle")
else
	oUF_Adirelle.Debug = function() end
	oUF.Debug = oUF_Adirelle.Debug
end
oUF:RegisterMetaFunction('Debug', oUF.Debug)

-- Version query command
_G.SLASH_OUFADIRELLEVER1 = "/ouf_adirelle_ver"
_G.SLASH_OUFADIRELLEVER2 = "/oufa_ver"
_G.SLASH_OUFADIRELLEVER3 = "/oufav"

local versions = {}

oUF_Adirelle.VERSION = 'v'.._G.GetAddOnMetadata(parent, 'version')
--@debug@
oUF_Adirelle.VERSION = "developer version"
--@end-debug@

_G.SlashCmdList.OUFADIRELLEVER = function()
	print('oUF_Adirelle '..oUF_Adirelle.VERSION)
	for major, minor in next, versions do
		print('- '..major..' v'..minor)
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
	oUF_Adirelle.GetLib = function() end
end

-- DiminishingReturns support
function oUF_Adirelle.RegisterDiminishingReturns()
	_G.DiminishingReturns:DeclareOUF(parent, oUF)
end

-- Configuration

local function ToggleConfig(arg, button)
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

local LDB = LibStub('LibDataBroker-1.1', true)
if LDB then
	oUF_Adirelle.launcher = LDB:NewDataObject(parent, {
		type = 'launcher',
		icon = [[Interface\Icons\Ability_Vehicle_ShellShieldGenerator]],
		tocname = parent,
		label = parent,
		OnClick = ToggleConfig,
	})
end

-- Some common "constants"

-- Get player class once
local _
_, oUF_Adirelle.playerClass = _G. UnitClass("player")

-- Frame background
oUF_Adirelle.backdrop = {
	--bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	bgFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]], bgAlpha = 0.85,
	tile = true,
	tileSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

-- Glow border backdrop
oUF_Adirelle.glowBorderBackdrop = {
	edgeFile = [[Interface\AddOns\oUF_Adirelle\media\glowborder]], edgeSize = 4, alpha = 1,
	--edgeFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]], edgeSize = 2, alpha = 0.5,
}

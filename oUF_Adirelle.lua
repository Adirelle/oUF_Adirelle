--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, parent, ns = _G, ...

-- If we have no embedded oUF, try to get one from standalonne oUF
if not ns.oUF then
	local global = GetAddOnMetadata('oUF', 'X-oUF')
	ns.oUF = assert(global and _G[global], parent.." requires oUF.")
end

-- Have namespace defaults to globals
ns._G = _G
setmetatable(ns, {__index=_G})
setfenv(1, ns)

-- Export our namespace for standalone modules
_G.oUF_Adirelle = ns

-- Debugging stuff
if tekDebug then
	local frame = tekDebug:GetFrame("oUF_Adirelle")
	local type, tostring, select = type, tostring, select
	local t = {}
	local function _tostringall(...)
		local n = select('#', ...)
		for i = 1, n do
			local value = select(i, ...)
			if type(value) == "table" and type(value[0]) == "userdata" then
				t[i] = '|cffCC7700['..(value:GetName() or tostring(value):replace('table', 'frame'))..']|r'
			else
				t[i] = tostring(value)
			end
		end
		return unpack(t, 1, n)
	end
	function Debug(...)
		frame:AddMessage(strjoin(" ", _tostringall(...)))
	end
else
	function Debug() end
end
oUF.Debug = Debug
oUF:RegisterMetaFunction('Debug', Debug)

-- Version query command
_G.SLASH_OUFADIRELLEVER1 = "/ouf_adirelle_ver"
_G.SLASH_OUFADIRELLEVER2 = "/oufa_ver"
_G.SLASH_OUFADIRELLEVER3 = "/oufav"

local versions = {}
do
	VERSION = 'v'..GetAddOnMetadata(parent, 'version')
	--@debug@
	VERSION = "developer version"
	--@end-debug@

	_G.SlashCmdList.OUFADIRELLEVER = function()
		print('oUF_Adirelle '..VERSION)
		for major, minor in next, versions do
			print('- '..major..' v'..minor)
		end
	end
end

-- Library helper
local LibStub = _G.LibStub
if LibStub then
	function GetLib(major)
		local lib, minor = LibStub(major, true)
		if lib then
			versions[major] = minor
			return lib, minor
		end
	end
else
	GetLib = function() end
end

-- DiminishingReturns support
function RegisterDiminishingReturns()
	_G.DiminishingReturns:DeclareOUF(parent, oUF)
end

-- Some common "constants"

-- Recolor mana
oUF.colors.power.MANA = { 0.3, 0.5, 1.0 }

-- Get player class once
playerClass = select(2, UnitClass("player"))

-- Frame background
backdrop = {
	--bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	bgFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]], bgAlpha = 0.85,
	tile = true,
	tileSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

-- Glow border backdrop
glowBorderBackdrop = {
	edgeFile = [[Interface\AddOns\oUF_Adirelle\media\glowborder]], edgeSize = 4, alpha = 1,
	--edgeFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]], edgeSize = 2, alpha = 0.5,
}

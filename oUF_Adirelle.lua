--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, parent, ns = _G, ...

-- Get a reference to oUF
if not ns.oUF then
	local global = assert(GetAddOnMetadata(parent, 'X-oUF'), "x-oUF must be defined in "..parent.." TOC file.")
	ns.oUF = assert(_G[global], "oUF_Adirelle requires oUF")
end

-- Have namespace defaults to globals
ns._G = _G
setmetatable(ns, {__index=_G})

-- Export our namespace for standalone modules
_G.oUF_Adirelle = ns

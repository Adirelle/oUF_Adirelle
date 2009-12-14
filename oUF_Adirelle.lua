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

-- Export our namespace for standalone modules
_G.oUF_Adirelle = ns

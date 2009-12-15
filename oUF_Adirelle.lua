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
	function Debug(...) frame:AddMessage(string.join(", ", tostringall(...)):gsub("([:=]), ", "%1")) end 
	oUF.frame_metatable.__tostring = function(self) return self:GetName()..'['..tostring(self.unit)..']' end
else
	function Debug() end
end
oUF.Debug = Debug
oUF.frame_metatable.__index.Debug = Debug


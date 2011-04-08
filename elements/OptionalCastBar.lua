--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local GetCVarBool = _G.GetCVarBool

local function Update(self, event, name)
	if event == "CVAR_UPDATE" and name ~= "SHOW_TARGET_CASTBAR" then return end
	local enabled = not not GetCVarBool("showTargetCastbar")
	if enabled == self.Castbar.enabled then return end
	self.Castbar.enabled = enabled
	self:Debug('UpdateCastbarDisplay', enabled, event, name)
	if enabled then
		self:EnableElement('Castbar')
	else
		self:DisableElement('Castbar')
		self.Castbar:Hide()
	end
end

local function Enable(self)
	if self.Castbar and self.OptionalCastbar then
		self.Castbar.enabled = true
		self:RegisterEvent('CVAR_UPDATE', Update)
		self.Castbar:ForceUpdate()
		return true
	end
end

local function Disable(self)
	if self.Castbar and self.OptionalCastbar then
		self.CastBar:Hide()
		self:UnregisterEvent('CVAR_UPDATE', Update)
	end
end

oUF:AddElement('OptionalCastbar', Update, Enable, Disable)


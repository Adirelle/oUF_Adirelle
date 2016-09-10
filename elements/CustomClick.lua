 --[=[
Adirelle's oUF layout
(c) 2014-2016 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .CustomClick
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
--GLOBALS>

local function Update(self)
	if not self:CanChangeAttribute() then return end

	local spell = next(oUF_Adirelle.Dispels)
	self:Debug("CustomClick", spell, spell and (IsSpellKnown(spell, true) or IsSpellKnown(spell, false)))

	self:SetAttribute("*type2", spell and "spell")
	self:SetAttribute("*spell2", spell)
end

local function ForceUpdate(element)
	return Update(element.__owner)
end

local function Enable(self)
	local element = self.CustomClick
	if element then
		element.__owner, element.ForceUpdate = self, ForceUpdate
		self:RegisterEvent('PLAYER_REGEN_DISABLED', Update, true)
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Update, true)
		self:RegisterEvent('SPELLS_CHANGED', Update, true)
		return true
	end
end

local function Disable(self)
	if self.CustomClick then
		if self:CanChangeAttribute() then
			self:SetAttribute("*type2", nil)
			self:SetAttribute("*spell2", nil)
		end
		self:UnregisterEvent('PLAYER_REGEN_DISABLED', Update)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Update)
		self:UnregisterEvent('SPELLS_CHANGED', Update)
	end
end

oUF:AddElement('CustomClick', Update, Enable, Disable)

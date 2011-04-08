--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .Dragon
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local UnitClassification = _G.UnitClassification
local type, unpack = _G.type, _G.unpack

local classifMap = {
	rare = 'rare',
	rareelite = 'rare',
	elite = 'elite',
	worldboss = 'elite',
	boss = 'elite',
}

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local dragon = self.Dragon
	local texture = dragon[classifMap[UnitClassification(self.unit) or false] or false]
	if texture then
		if type(texture) == "table" then
			local path, x0, x1, y0, y1 = unpack(texture)
			dragon:SetTexture(path)
			dragon:SetTexCoord(x0, x1, y0, y1)
		else
			dragon:SetTexture(texture)
		end
		dragon:Show()
	else
		dragon:Hide()
	end
end

local function Enable(self)
	if self.Dragon then
		self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', Update)
		return true
	end
end

local function Disable(self)
	self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', Update)
end

oUF:AddElement('Dragon', Update, Enable, Disable)


--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .Dragon
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local type = _G.type
local UnitClassification = _G.UnitClassification
local unpack = _G.unpack
--GLOBALS>

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
	if self.Dragon then
		self.Dragon:Hide()
		self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', Update)
	end
end

oUF:AddElement('Dragon', Update, Enable, Disable)


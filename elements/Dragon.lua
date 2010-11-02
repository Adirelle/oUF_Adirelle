--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .Dragon	
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

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


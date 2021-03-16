--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Elements handled: .Dragon
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local GetCurrentRegion = assert(_G.GetCurrentRegion, "_G.GetCurrentRegion is undefined")
local type = assert(_G.type, "_G.type is undefined")
local UnitClassification = assert(_G.UnitClassification, "_G.UnitClassification is undefined")
local unpack = assert(_G.unpack, "_G.unpack is undefined")
--GLOBALS>

local classifMap = {
	rare = "rare",
	rareelite = "rare",
	elite = "elite",
	worldboss = "elite",
	boss = "elite",
}

-- Easter egg
if GetCurrentRegion() == 3 then
	local hooked_UnitClassification = UnitClassification
	local UnitGUID = _G.UnitGUID
	local UnitIsUnit = _G.UnitIsUnit
	function UnitClassification(unit)
		if not UnitIsUnit(unit, "player") and UnitGUID(unit) == "Player-1335-098DCDB7" then
			return "worldboss"
		end
		return hooked_UnitClassification(unit)
	end
end

local function Update(self, _, unit)
	if unit and unit ~= self.unit then
		return
	end
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
		self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED", Update)
		return true
	end
end

local function Disable(self)
	if self.Dragon then
		self.Dragon:Hide()
		self:UnregisterEvent("UNIT_CLASSIFICATION_CHANGED", Update)
	end
end

oUF:AddElement("Dragon", Update, Enable, Disable)

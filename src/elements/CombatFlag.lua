--[=[
Adirelle's oUF layout
(c) 2014-2021 Adirelle (adirelle@gmail.com)

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

# Element: Combat Flag

Toggles the visibility of an indicator based on the unit combat status.

## Widget

CombatFlag - Any UI widget.

## Notes

A default texture will be applied if the widget is a Texture and doesn't have a texture or a color set.

## Examples

    -- Position and size
    local CombatFlag = self:CreateTexture(nil, 'OVERLAY')
    CombatFlag:SetSize(16, 16)
    CombatFlag:SetPoint('TOP', self)

    -- Register it with oUF
    self.CombatFlag = CombatFlag
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local UnitAffectingCombat = assert(_G.UnitAffectingCombat)
--GLOBALS>

local function Update(self, _, unit)
	if unit and self.unit ~= unit then
		return
	end
	local element = self.CombatFlag

	--[[ Callback: CombatFlag:PreUpdate()
	Called before the element has been updated.

	* self - the CombatFlag element
	--]]
	if element.PreUpdate then
		element:PreUpdate()
	end

	local inCombat = UnitAffectingCombat(self.unit)
	if inCombat then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: CombatFlag:PostUpdate(inCombat)
	Called after the element has been updated.

	* self     - the CombatFlag element
	* inCombat - indicates if the unit is affecting combat (boolean)
	--]]
	if element.PostUpdate then
		return element:PostUpdate(inCombat)
	end
end

local function Path(self, ...)
	--[[ Override: CombatFlag.Override(self, event)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	--]]
	return (self.CombatFlag.Override or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local element = self.CombatFlag
	if element then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_FLAGS", Path, true)

		if (element:IsObjectType("Texture") and not element:GetTexture()) then
			element:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			element:SetTexCoord(35 / 63, 58 / 63, 4 / 63, 27 / 63)
		end

		return true
	end
end

local function Disable(self)
	local element = self.CombatFlag
	if element then
		element:Hide()

		self:UnregisterEvent("UNIT_FLAGS", Path)
	end
end

oUF:AddElement("CombatFlag", Path, Enable, Disable)

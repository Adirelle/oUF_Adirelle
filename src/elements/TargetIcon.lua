--[=[
Adirelle's oUF layout
(c) 2011-2021 Adirelle (adirelle@gmail.com)

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

Elements handled: .TargetIcon
--]=]

local _G = _G
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture
--GLOBALS>

local function Update(self, _, unit)
	if unit and unit ~= self.unit then
		return
	end
	local target = self.unit == "player" and "target" or (self.unit .. "target")
	local raidTarget = GetRaidTargetIndex(target)
	if raidTarget and raidTarget ~= 0 then
		SetRaidTargetIconTexture(self.TargetIcon, raidTarget)
		return self.TargetIcon:Show()
	else
		return self.TargetIcon:Hide()
	end
end

local function Path(self, ...)
	return (self.TargetIcon.Update or Update)(self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
	local icon = self.TargetIcon
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		if not icon:GetTexture() then
			icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
			icon:SetVertexColor(1, 1, 1, 1)
		end
		self:RegisterEvent("UNIT_TARGET", Path)
		self:RegisterEvent("RAID_TARGET_UPDATE", Path)
		icon:Hide()
		return true
	end
end

local function Disable(self)
	local icon = self.TargetIcon
	if icon then
		self:UnregisterEvent("UNIT_TARGET", Path)
		self:UnregisterEvent("RAID_TARGET_UPDATE", Path)
		icon:Hide()
	end
end

oUF:AddElement("TargetIcon", Path, Enable, Disable)

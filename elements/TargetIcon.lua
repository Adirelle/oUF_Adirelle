--[=[
Adirelle's oUF layout
(c) 2011-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .TargetIcon
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local GetRaidTargetIndex = _G.GetRaidTargetIndex
local SetRaidTargetIconTexture = _G.SetRaidTargetIconTexture
--GLOBALS>

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local target = self.unit == "player" and "target" or (self.unit.."target")
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
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local icon = self.TargetIcon
	if icon then
		icon.__owner, icon.ForceUpdate = self, ForceUpdate
		if not icon:GetTexture() then
			icon:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
			icon:SetVertexColor(1, 1, 1, 1)
		end
		self:RegisterEvent('UNIT_TARGET', Path)
		self:RegisterEvent('RAID_TARGET_UPDATE', Path)
		icon:Hide()
		return true
	end
end

local function Disable(self)
	local icon = self.TargetIcon
	if icon then
		self:UnregisterEvent('UNIT_TARGET', Path)
		self:UnregisterEvent('RAID_TARGET_UPDATE', Path)
		icon:Hide()
	end
end

oUF:AddElement('TargetIcon', Path, Enable, Disable)


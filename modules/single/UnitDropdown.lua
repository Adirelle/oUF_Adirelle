--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local moduleName, private = ...

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

-- Based on Xinhuan unit dropdown hack
local function AdjustMenu(listFrame, point, relativeTo, relativePoint, xOffset, yOffset)
	local x, y = listFrame:GetCenter()
	local reposition
	if (y - listFrame:GetHeight()/2) < 0 then
		point = gsub(point, "TOP(.*)", "BOTTOM%1")
		relativePoint = gsub(relativePoint, "BOTTOM(.*)", "TOP%1")
		reposition = true
	end
	if listFrame:GetRight() > GetScreenWidth() then
		point = gsub(point, "(.*)LEFT", "%1RIGHT")
		relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT")
		reposition = true
	end
	if reposition then
		listFrame:ClearAllPoints()
		listFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	end
end

local function DropDown_PostClick(self)
	if UIDROPDOWNMENU_OPEN_MENU == self.dropdownFrame and DropDownList1:IsShown() then
		DropDownList1:ClearAllPoints()
		DropDownList1:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0)
		AdjustMenu(DropDownList1, "TOPLEFT", self, "BOTTOMLEFT", 0, 0)
	end
end

local BLIZZARD_FRAMES = {
	player = "PlayerFrame",
	pet = "PetFrame",
	target = "TargetFrame",
	focus = "FocusFrame",
	boss = "Boss1TargetFrame",
}

function private.SetupUnitDropdown(self, unit)
	local blizzardName = BLIZZARD_FRAMES[unit]
	if not blizzardName then return end
	
	-- Redirect right-click to Blizzard frame
	local blizzardFrame = _G[blizzardName]
	self:SetAttribute("*type2", "click")
	self:SetAttribute("*clickbutton2", blizzardFrame)
	
	-- Adjust the menu position
	self.dropdownFrame = _G[blizzardName.."DropDown"]
	self:HookScript("PostClick", DropDown_PostClick)

	-- In case some addon overrides our right-click binding
	local menu = blizzardFrame.menu
	if menu then
		self.menu = function(...)
			print("|cff33ff99oUF_Adirelle:|r |cffff0000some third-party addon (Clique ?) overrides the right-click binding. Some of the menu options may fail. Remove that binding or disable the addon to fix this.|r")
			return menu(...)
		end
	end
end


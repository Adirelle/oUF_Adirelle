--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

-- Default background
local defaultBackdrop = {
	bgFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]], bgAlpha = 0.8,
	tile = true,
	tileSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local function Update(self)
	if self:IsVisible() and self.Background.enabled then
		self.Background:Show()
	else
		self.Background:Hide()
	end
end

local function Enable(self)
	local background = self.Background
	if background then
		background:SetFrameStrata("BACKGROUND")
		background:SetAllPoints(self)
		local backdrop = background.backdrop or defaultBackdrop
		background:SetBackdrop(backdrop)
		background:SetBackdropColor(0,0,0,backdrop.bgAlpha or 1)
		background:SetBackdropBorderColor(0,0,0,0)
		background.enabled = true
		self:HookScript("OnShow", Update)
		self:HookScript("OnHide", Update)
		Update(self)
		return true
	end
end

local function Disable(self)
	if self.Background then
		self.Background.enabled = nil
		Update(self)
	end
end

oUF:AddElement('Background', Update, Enable, Disable)

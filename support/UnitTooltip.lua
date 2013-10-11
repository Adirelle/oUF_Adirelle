--[=[
Adirelle's oUF layout
(c) 2009-2013 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
--GLOBALS>

local function UpdateTooltip(frame)
	if GameTooltip:SetUnit(frame.unit) then
		frame.UpdateTooltip = UpdateTooltip
	else
		frame.UpdateTooltip = nil
	end
	local r, g, b = GameTooltip_UnitColor(frame.unit)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
end

function oUF_Adirelle.Unit_OnEnter(frame)
	--[[
	local x = self:GetCenter() / self:GetEffectiveScale()
	local w = UIParent:GetWidth() / UIParent:GetEffectiveScale()
	GameTooltip:SetOwner(self, (x < w/2) and "ANCHOR_TOPLEFT" or "ANCHOR_TOPRIGHT", 0, 16)
	--]]
	oUF:Debug('Unit_OnEnter', frame, frame.unit)
	GameTooltip_SetDefaultAnchor(GameTooltip, frame)
	return UpdateTooltip(frame)
end

function oUF_Adirelle.Unit_OnLeave(frame)
	if GameTooltip:IsOwned(frame) then
		GameTooltip:Hide()
	end
end

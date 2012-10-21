--[=[
Adirelle's oUF layout
(c) 2009-2012 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

oUF:Factory(function()
	--<GLOBALS
	local _G = _G
	local next = _G.next
	local select = _G.select
	--GLOBALS>

	local frames = {}

	local function Spawn(style, unit, ...)
		oUF:SetActiveStyle(style)
		local realUnit = unit:lower()
		local frame = oUF:Spawn(realUnit, "oUF_Adirelle_"..unit)
		frames[frame] = unit
		if select('#', ...) > 0 then
			return frame, Spawn(style, ...)
		else
			return frame
		end
	end

	local player, pet = Spawn("Adirelle_Single", "Player", "Pet")
	local target, focus = Spawn("Adirelle_Single_Right", "Target", "Focus")
	local targettarget, pettarget = Spawn("Adirelle_Single_Health", "TargetTarget", "PetTarget")

	player:SetPoint('BOTTOMRIGHT', _G.UIParent, "BOTTOM", -250, 180)
	pet:SetPoint('BOTTOM', player, "TOP", 0, 15)
	pettarget:SetPoint('BOTTOM', pet, "TOP", 0, 15+22)
	target:SetPoint('BOTTOMLEFT', _G.UIParent, "BOTTOM", 250, 180)
	targettarget:SetPoint('BOTTOM', target, "TOP", 0, 15)
	focus:SetPoint('BOTTOM', targettarget, "TOP", 0, 15)

	for frame, unit in next, frames do
		oUF_Adirelle.RegisterMovable(frame, unit, unit.." frame")
	end
	frames = nil
end)


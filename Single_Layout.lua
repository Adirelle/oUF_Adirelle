--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
setfenv(1, oUF_Adirelle)

local frames = {}

local function Spawn(style, ...)
	oUF:SetActiveStyle(style)
	for i = 1, select('#', ...) do
		local unit = select(i, ...)
		local realUnit = unit:lower()
		frames[realUnit] = oUF:Spawn(realUnit, "oUF_Adirelle_"..unit)
	end
end

Spawn("Adirelle_Single", "Player", "Pet")
Spawn("Adirelle_Single_Right", "Target", "Focus")
Spawn("Adirelle_Single_Health", "TargetTarget")

frames.player:SetPoint('BOTTOMRIGHT', UIParent, "BOTTOM", -250, 180)
frames.pet:SetPoint('BOTTOM', frames.player, "TOP", 0, 15)
frames.pet:SetHeight(40)
frames.target:SetPoint('BOTTOMLEFT', UIParent, "BOTTOM", 250, 180)
frames.targettarget:SetPoint('BOTTOM', frames.target, "TOP", 0, 15)
frames.focus:SetPoint('BOTTOM', frames.targettarget, "TOP", 0, 15)

local libmovable = LibStub('LibMovable-1.0', true)
if libmovable then
	for unit, frame in pairs(frames) do
		libmovable.RegisterMovable(oUF_Adirelle, frame, nil, unit.." frame")
	end
end

frames = nil


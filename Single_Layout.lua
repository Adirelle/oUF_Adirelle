--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
setfenv(1, oUF_Adirelle)

oUF:SetActiveStyle("Adirelle_Single")
local player = oUF:Spawn("player", "oUF_Adirelle_Player")
local pet = oUF:Spawn("pet","oUF_Adirelle_Pet")

oUF:SetActiveStyle("Adirelle_Single_Right")
local target = oUF:Spawn("target", "oUF_Adirelle_Target")
local focus = oUF:Spawn("focus","oUF_Adirelle_Focus")

oUF:SetActiveStyle("Adirelle_Single_Health")
local tot = oUF:Spawn("targettarget", "oUF_Adirelle_ToT")

player:SetPoint('BOTTOMRIGHT', UIParent, "BOTTOM", -255, 180)
pet:SetPoint('BOTTOM', player, "TOP", 0, 15)
pet:SetHeight(40)

target:SetPoint('BOTTOMLEFT', UIParent, "BOTTOM", 255, 180)
tot:SetPoint('BOTTOM', target, "TOP", 0, 15)
focus:SetPoint('BOTTOM', tot, "TOP", 0, 15)


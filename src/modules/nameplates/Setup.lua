--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local CreateFrame = assert(_G.CreateFrame)
local hooksecurefunc = assert(_G.hooksecurefunc)
local NamePlateDriverFrame = assert(_G.NamePlateDriverFrame)
local next = assert(_G.next)
local SetCVar = assert(_G.SetCVar)
local UnitAffectingCombat = assert(_G.UnitAffectingCombat)
--GLOBALS>

local NAMEPLATE_CVARS = assert(oUF_Adirelle.NAMEPLATE_CVARS)

local function insecureOnShow(frame)
	frame:Hide()
end

local function DisableFrame(_, frame)
	if not frame or frame:IsForbidden() then
		return
	end
	frame:HookScript("OnShow", insecureOnShow)
	frame:UnregisterAllEvents()
	frame:Hide()
end

hooksecurefunc(NamePlateDriverFrame, "SetClassNameplateBar", DisableFrame)
hooksecurefunc(NamePlateDriverFrame, "SetClassNameplateManaBar", DisableFrame)

local function LoadNameplateCVars()
	if not oUF_Adirelle.layoutDB then
		return
	end
	local values = oUF_Adirelle.layoutDB.profile.nameplates.cvars
	for _, name in next, NAMEPLATE_CVARS do
		SetCVar(name, values[name])
	end
end

local visibility = {
	variables = {
		nameplateShowAll = "autoAll",
		nameplateShowFriends = "autoFriends",
		nameplateShowEnemies = "autoEnemies",
	},
	tests = {
		never = function()
			return false
		end,
		outOfCombat = function(inCombat)
			return not inCombat
		end,
		inCombat = function(inCombat)
			return inCombat
		end,
		always = function()
			return true
		end,
	},
}

local function UpdateVisiblities(_, event)
	local inCombat = (event == "PLAYER_REGEN_DISABLED") or UnitAffectingCombat("player")
	local profile = oUF_Adirelle.layoutDB.profile
	for cvar, config in next, visibility.variables do
		local choice = profile.nameplates[config]
		local enable = visibility.tests[choice](inCombat)
		oUF_Adirelle:Debug("UpdateVisiblities", cvar, config, choice, inCombat, "=>", enable)
		SetCVar(cvar, enable and "1" or "0")
	end
end

oUF:Factory(function(self)
	self:SetActiveStyle("Adirelle_Nameplate")
	self:SpawnNamePlates("oUF_Adirelle_")

	LoadNameplateCVars()

	DisableFrame(NamePlateDriverFrame:GetClassNameplateBar())
	DisableFrame(NamePlateDriverFrame:SetClassNameplateManaBar())

	local eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnEvent", UpdateVisiblities)
	eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	oUF_Adirelle:RegisterMessage("OnNameplateConfigured", UpdateVisiblities)
	UpdateVisiblities()
end)

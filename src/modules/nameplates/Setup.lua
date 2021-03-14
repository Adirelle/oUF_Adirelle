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
local hooksecurefunc = assert(_G.hooksecurefunc)
local NamePlateDriverFrame = assert(_G.NamePlateDriverFrame)
local next = assert(_G.next)
local SetCVar = assert(_G.SetCVar)
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

oUF:Factory(function()
	oUF:SetActiveStyle("Adirelle_Nameplate")
	oUF:SpawnNamePlates("oUF_Adirelle_")

	LoadNameplateCVars()

	DisableFrame(NamePlateDriverFrame:GetClassNameplateBar())
	DisableFrame(NamePlateDriverFrame:SetClassNameplateManaBar())
end)

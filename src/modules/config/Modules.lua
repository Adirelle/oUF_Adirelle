--[=[
Adirelle's oUF layout
(c) 2021 Adirelle (adirelle@gmail.com)

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
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)

--<GLOBALS
local DisableAddOn = assert(_G.DisableAddOn)
local EnableAddOn = assert(_G.EnableAddOn)
local format = assert(_G.format)
local GetAddOnEnableState = assert(_G.GetAddOnEnableState)
local GetAddOnInfo = assert(_G.GetAddOnInfo)
local GetAddOnMetadata = assert(_G.GetAddOnMetadata)
local IsAddOnLoaded = assert(_G.IsAddOnLoaded)
local LoadAddOn = assert(_G.LoadAddOn)
local next = assert(_G.next)
local tostring = assert(_G.tostring)
--GLOBALS>

local Config = assert(oUF_Adirelle.Config)

local moduleList = {
	"oUF_Adirelle_Raid",
	"oUF_Adirelle_Single",
	"oUF_Adirelle_Boss",
	"oUF_Adirelle_Arena",
	"oUF_Adirelle_Nameplates",
}

local function ConfigApplied()
	for _, moduleName in next, moduleList do
		local enabled = GetAddOnEnableState(oUF_Adirelle.playerName, moduleName)
		if enabled then
			local loaded = IsAddOnLoaded(moduleName)
			if enabled > 0 and not loaded then
				return false
			elseif enabled == 0 and loaded then
				return false
			end
		end
	end
	return true
end

Config:RegisterBuilder(function(_, _, merge)
	merge({
		modules = {
			name = "Modules",
			type = "group",
			order = -10,
			disabled = Config.IsLockedDown,
			args = {
				reload = {
					name = "Apply changes",
					desc = "Reload the user interface to apply the changes.",
					type = "execute",
					order = -10,
					func = _G.ReloadUI,
					hidden = ConfigApplied,
				},
			},
		},
	})

	local order = 10
	for _, moduleName in next, moduleList do
		local key = moduleName:sub(13):lower()
		local _, _, notes, loadable, reason = GetAddOnInfo(moduleName)
		local version = GetAddOnMetadata(moduleName, "Version")

		local name = notes or moduleName
		local desc = version and ("Version " .. tostring(version)).gi
		local cannotEnable = not loadable and reason ~= "DISABLED"
		if cannotEnable and reason then
			name = format("|cFFFF0000%s: %s\r", name, _G["ADDON_" .. reason])
		end

		merge("modules", {
			[key] = {
				name = name,
				desc = desc,
				type = "toggle",
				width = "full",
				order = order,
				disabled = cannotEnable,
				get = function()
					local enabledState = GetAddOnEnableState(oUF_Adirelle.playerName, moduleName)
					return enabledState and enabledState > 0
				end,
				set = function(_, enable)
					if enable then
						EnableAddOn(moduleName)
						if loadable then
							LoadAddOn(moduleName)
						end
					else
						DisableAddOn(moduleName)
					end
				end,
			},
		})
		order = order + 10
	end

end)

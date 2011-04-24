--[=[
Adirelle's oUF layout
(c) 2011 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- Make most globals local so I can check global leaks using "luac -l | grep GLOBAL"
local LibStub = _G.LibStub
local select, pairs, wipe, gsub = _G.select, _G.pairs, _G.wipe, _G.gsub
local GetAddOnInfo, EnableAddOn = _G.GetAddOnInfo, _G.EnableAddOn
local DisableAddOn, GetAddOnInfo = _G.DisableAddOn, _G.GetAddOnInfo
local IsAddOnLoaded, InCombatLockdown = _G.IsAddOnLoaded, _G.InCombatLockdown

local options
local function GetOptions()
	if options then return options end
	
	local LibMovable = oUF_Adirelle.GetLib('LibMovable-1.0')

	local reloadNeeded = false
	local moduleList = {
		oUF_Adirelle_Raid = 'Party/raid grid',
		oUF_Adirelle_Single = 'Player, pet, target and focus frames',
		oUF_Adirelle_Boss = 'Boss frames',
		oUF_Adirelle_Arena = 'Arena enemy frames',
	}
		
	local togglableFrameList = {}
	local togglableFrames = oUF_Adirelle.togglableFrames
	
	options = {
		name = 'oUF_Adirelle '..oUF_Adirelle.VERSION,
		type = 'group',
		disabled = function() return InCombatLockdown() end,
		args = {
			general = {
				name = 'Modules & frames',
				type = 'group',
				order = 10,
				args = {
					modules = {
						name = 'Modules',
						desc = 'Select frame modules to enable. Changes requrie to reload the user interface.',
						type = 'multiselect',
						order = 10,
						values = moduleList,
						get = function(info, addon)
							return select(4, GetAddOnInfo(addon))
						end,
						set = function(info, addon, value)
							if value then
								EnableAddOn(addon)
							else
								DisableAddOn(addon)		
							end
							reloadNeeded = false
							for name in pairs(moduleList) do
								local enabled, loaded = select(4, GetAddOnInfo(name)), IsAddOnLoaded(name)
								if (enabled and not loaded) or (not enabled and loaded) then
									reloadNeeded = true
									break
								end
							end
						end,
					},
					reload = {
						name = 'Apply changes',
						desc = 'Reload the user interface to apply the changes.',
						type = 'execute',
						order = 20,
						func = _G.ReloadUI,
						hidden = function() return not reloadNeeded end,
					},
					frames = {
						name = 'Enabled frames',
						type = 'multiselect',
						order = 30,
						values = function()
							local t = wipe(togglableFrameList)
							for key, frame in pairs(togglableFrames) do
								t[key] = gsub(frame.label, "%s+[fF]rames?$", "")
							end
							return t
						end,
						get = function(info, key) 
							return togglableFrames[key]:GetEnabledSetting()
						end,
						set = function(info, key, enabled)
							togglableFrames[key]:SetEnabledSetting(enabled)
						end,
					},
					lock = {
						name = function()
							return LibMovable.IsLocked("oUF_Adirelle") and "Unlock" or "Lock"
						end,
						type = 'execute',
						order = 40,
						func = function()
							if LibMovable.IsLocked("oUF_Adirelle") then
								LibMovable.Unlock("oUF_Adirelle")
							else
								LibMovable.Lock("oUF_Adirelle")
							end
						end,
					},
					reset = {
						name = 'Reset positions',
						type = 'execute',
						order = 50,
						func = function()
							LibMovable.ResetLayout("oUF_Adirelle")
						end,
					},
				},
			},
			media = {
				name = 'Texture & fonts',
				type = 'group',
				order = 20,
				args = {
					statusbar = {
						name = 'Bar texture',
						type = 'select',
						dialogControl = 'LSM30_Statusbar',
						order = 10,
						values = AceGUIWidgetLSMlists.statusbar,
						get = function()
							return oUF_Adirelle.db.profile.statusbar
						end,
						set = function(_, value)
							oUF_Adirelle.db.profile.statusbar = value
							oUF_Adirelle.UpdateStatusBarTextures()
						end,
					},
					--[[
					font = {
						name = 'Font',
						type = 'input',
						order = 10,
					},
					size = {
						name = 'Scale',
						type = 'range',
						order = 20,
						isPercent = true,
						min = 0.1,
						max = 1.0,
						step = 0.05,
					},
					outline = {
						name = 'Outline',
						type = 'select',
						order = 30,
						values = {
						},
					},
					--]]
				},
			},
		},
	}
	
	local db = oUF_Adirelle.db
	local dbOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(db)
	LibStub('LibDualSpec-1.0'):EnhanceOptions(dbOptions, db)
	dbOptions.order = -1
	options.args.profiles = dbOptions
	
	return options
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("oUF_Adirelle", GetOptions)
local mainPanel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions('oUF_Adirelle', "oUF_Adirelle")



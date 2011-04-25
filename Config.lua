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
local select, pairs, wipe, gsub, unpack = _G.select, _G.pairs, _G.wipe, _G.gsub, _G.unpack
local type, format, tostring, tonumber = _G.type, _G.format, _G.tostring, _G.tonumber
local GetAddOnInfo, EnableAddOn = _G.GetAddOnInfo, _G.EnableAddOn
local DisableAddOn, GetAddOnInfo = _G.DisableAddOn, _G.GetAddOnInfo
local IsAddOnLoaded, InCombatLockdown = _G.IsAddOnLoaded, _G.InCombatLockdown

local AceGUIWidgetLSMlists = _G.AceGUIWidgetLSMlists

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
	
	local elementList = {}
	for i, key in pairs(oUF_Adirelle.optionalElements) do
		elementList[key] = gsub(key, "([a-z])([A-Z])", "%1 %2")
	end
	
	local function SetColor(info, r, g, b, a)
		info.arg[1], info.arg[2], info.arg[3] = r, g, b
		if info.option.hasAlpha then
			info.arg[4] = a
		end
		oUF_Adirelle.ColorsChanged()
	end
	local function GetColor(info)
		return unpack(info.arg, 1, info.option.hasAlpha and 4 or 3)
	end
	local function BuildColorArg(name, color, hasAlpha, order)	
		return { name = name, type = 'color', arg = color, hasAlpha = hasAlpha, order = order or 10, get = GetColor, set = SetColor }
	end
	local function BuildColorGroup(name, colors, names, hasAlpha)
		if not colors then return end
		local group = { name = name, type = 'group', inline = true, order = 20, args = {} }
		for key, color in pairs(colors) do
			local entryName
			if type(names) == "table" then
				entryName = names[key] or key
			elseif type(names) == "string" then
				entryName = _G[format(names, key)]
			else
				entryName = key
			end
			group.args[tostring(key)] = BuildColorArg(entryName, color, hasAlpha, tonumber(key))
		end
		return group
	end
	
	local colorArgs = {
		class = BuildColorGroup("Class", oUF.colors.class, _G.LOCALIZED_CLASS_NAMES_MALE),
		reaction = BuildColorGroup("Reaction", oUF.colors.reaction, "FACTION_STANDING_LABEL%d"),
		power = BuildColorGroup("Power", oUF.colors.power, "%s"),
		happiness = BuildColorGroup("Pet happiness", oUF.colors.happiness, "PET_HAPPINESS%d"),
		disconnected = BuildColorArg('Disconnected', oUF.colors.disconnected),
		tapped = BuildColorArg('Tapped', oUF.colors.tapped),
		incoming = BuildColorGroup("Incoming heals", oUF.colors.incomingHeal, { self = "Self", others = "Others'" }, true),
		lowHealth = BuildColorArg("Low health warning", oUF.colors.lowHealth, true),
		runes = BuildColorGroup('Runes', oUF.colors.runes, { "Blood", "Unholy", "Frost", "Death" }),
		totems = BuildColorGroup('Totems', oUF.colors.totems, {
			[_G.FIRE_TOTEM_SLOT] = "Fire",
			[_G.EARTH_TOTEM_SLOT] = "Earth",
			[_G.WATER_TOTEM_SLOT] = "Water",
			[_G.AIR_TOTEM_SLOT] = "Air",	
		}),
	}

		
	local layoutDB = oUF_Adirelle.layoutDB
	local layoutDBOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(layoutDB)
	LibStub('LibDualSpec-1.0'):EnhanceOptions(layoutDBOptions, layoutDB)
	layoutDBOptions.order = -1

	local themeDB = oUF_Adirelle.themeDB
	local themeDBOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(themeDB)
	LibStub('LibDualSpec-1.0'):EnhanceOptions(themeDBOptions, themeDB)
	themeDBOptions.order = -1
	
	options = {
		name = 'oUF_Adirelle '..oUF_Adirelle.VERSION,
		type = 'group',		
		childGroups = 'tab',
		args = {
			modules = {
				name = 'Modules',
				type = 'group',
				childGroups = 'tree',
				order = 10,
				disabled = function() return InCombatLockdown() end,
				args = {
					_info = {
						type = 'description',
						name = 'You can select which modules should be loaded. Changes require to reload the user interface. These settings do not depend on the profile.',
						order = 1,
					},
					modules = {
						name = 'Enabled modules',
						type = 'multiselect',
						order = 10,
						width = "double",
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
					minimapIcon = oUF_Adirelle.hasMinimapIcon and {
						name = 'Display minimap icon',
						type = 'toggle',
						order = 30,
						get = function() return not layoutDB.global.minimapIcon.hide end,
						set = function(_, value)
							layoutDB.global.minimapIcon.hide = not value
							if value then
								LibStub('LibDBIcon-1.0'):Show('oUF_Adirelle')
							else
								LibStub('LibDBIcon-1.0'):Hide('oUF_Adirelle')
							end
						end,
					} or nil,
				},
			},
			layout = {
				name = 'Layout',
				type = 'group',
				order = 20,
				childGroups = 'tree',
				disabled = function() return InCombatLockdown() end,
				args = {
					frames = {
						name = 'Frames',
						type = 'group',
						order = 20,
						args = {
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
					elements = {
						name = 'Elements',
						type = 'group',
						order = 25,
						get = function(info, key)
							return layoutDB.profile.elements[key]
						end,
						set = function(info, key, value)
							layoutDB.profile.elements[key] = value
							oUF_Adirelle.ApplySettings("OnConfigChanged")
						end,
						args = {
							_warn = {
								name = 'Some elements may be linked together.',
								type = 'description',
								order = 1,
							},
							bars = {
								name = 'Bars / powers',
								type = 'multiselect',
								order = 10,
								values = {
									Experience = "Experience",
									IncomingHeal = "Incoming heals",
									RuneBar = "Runes",
									ThreatBar = "Threat",
									TotemBar = "Totems",
									Castbar = "Spell casting",
									HolyPower = "Holy power",
									SoulShards = "Soul Shards",
									ComboPoints = "Combo points",
									EclipseBar = "Eclipse energy",
								},
							},
							icons = {
								name = 'Icons',
								type = 'multiselect',
								order = 20,
								values = {
									RoleIcon = "Role or raid icon",
									StatusIcon = "Status",
									WarningIcon = "Warning",
									Assistant = "Raid assistant",
									Leader = "Party/raid leader",
									MasterLooter = "Master looter",
									PvP = "PvP flag",
									Resting = "Resting",
									RaidIcon = "Raid icon",
									ReadyCheck = "Ready check",
									Happiness = "Happiness",			
									TargetIcon = "Target raid icon"
								},
							},
							misc = {
								name = 'Miscellaneous',
								type = 'multiselect',
								order = 30, 
								values = {
									Dragon = "Classification dragon",
									LowHealth = "Low health glow",
									PvPTimer = "PvP timer",
									SmartThreat = "Threat glow",
									XRange = "Range fading",
								},
							},
						},
					},
					profiles = layoutDBOptions,
				},
			},
			theme = {
				name = 'Theme',
				type = 'group',
				order = 30,
				childGroups = 'tree',
				args = {
					media = {
						name = 'Texture & fonts',
						type = 'group',
						order = 30,
						args = {
							statusbar = {
								name = 'Bar texture',
								type = 'select',
								dialogControl = 'LSM30_Statusbar',
								order = 10,
								values = AceGUIWidgetLSMlists.statusbar,
								get = function()
									return themeDB.profile.statusbar
								end,
								set = function(_, value)
									themeDB.profile.statusbar = value
									oUF_Adirelle.ApplySettings("OnConfigChanged")
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
					colors = {
						name = 'Colors',
						type = 'group',
						order = 40,
						args = colorArgs,
					},
					profiles = themeDBOptions
				},
			},
		},
	}
	
	return options
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("oUF_Adirelle", GetOptions)
--local mainPanel = LibStub("AceConfigDialog-3.0"):AddToBlizOptions('oUF_Adirelle', "oUF_Adirelle")

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function oUF_Adirelle.ToggleConfig()
	if not AceConfigDialog:Close("oUF_Adirelle") then
		AceConfigDialog:Open("oUF_Adirelle")
	end
end


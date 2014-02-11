--[=[
Adirelle's oUF layout
(c) 2011-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local DisableAddOn = _G.DisableAddOn
local EnableAddOn = _G.EnableAddOn
local format = _G.format
local GetAddOnInfo = _G.GetAddOnInfo
local gsub = _G.gsub
local IsAddOnLoaded = _G.IsAddOnLoaded
local next = _G.next
local pairs = _G.pairs
local select = _G.select
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local UnitAffectingCombat = _G.UnitAffectingCombat
local unpack = _G.unpack
local wipe = _G.wipe
--GLOBALS>

local AceGUIWidgetLSMlists = _G.AceGUIWidgetLSMlists

-- ------------------------------------------------------------------------------
-- Main option builder
-- ------------------------------------------------------------------------------

local options
local function GetOptions()
	if options then return options end

	local LibMovable = oUF_Adirelle.GetLib('LibMovable-1.0')

	local reloadNeeded = false

	local SettingsModified = oUF_Adirelle.SettingsModified

	local function IsLockedDown() return UnitAffectingCombat("player") end

	-- The list of modules
	local moduleList = {
		oUF_Adirelle_Raid = 'Party/raid grid',
		oUF_Adirelle_Single = 'Player, pet, target and focus frames',
		oUF_Adirelle_Boss = 'Boss frames',
		oUF_Adirelle_Arena = 'Arena enemy frames',
	}

	-- Map "base" units to their respective modules
	local unitModuleMap = {
		raid = "oUF_Adirelle_Raid",
		arena = "oUF_Adirelle_Arena",
		arenapet = "oUF_Adirelle_Arena",
		boss = "oUF_Adirelle_Boss",
		player = "oUF_Adirelle_Single",
		pet = "oUF_Adirelle_Single",
		pettarget = "oUF_Adirelle_Single",
		target = "oUF_Adirelle_Single",
		targettarget = "oUF_Adirelle_Single",
		focus = "oUF_Adirelle_Single",
		slim_focus = "oUF_Adirelle_Single",
	}

	-- Create the profile options of the layout
	local layoutDB = oUF_Adirelle.layoutDB
	local layoutDBOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(layoutDB)
	LibStub('LibDualSpec-1.0'):EnhanceOptions(layoutDBOptions, layoutDB)
	layoutDBOptions.disabled = IsLockedDown
	layoutDBOptions.order = -1

	-- Create the profile options of the theme
	local themeDB = oUF_Adirelle.themeDB
	local themeDBOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(themeDB)
	LibStub('LibDualSpec-1.0'):EnhanceOptions(themeDBOptions, themeDB)
	themeDBOptions.order = -1

	-- Fetch the list of togglable frames
	local togglableFrameList = {}
	local togglableFrames = oUF_Adirelle.togglableFrames

	local function IsAddOnEnabled(name) return name and select(4, GetAddOnInfo(name)) end

	-- Test if a frame is disabled
	local IsFrameDisabled = {}
	for key, module in pairs(unitModuleMap) do
		if key ~= "arenapet" then
			local key, module = key, module -- Make them fixed upvalues
			IsFrameDisabled[key] = function() return not IsAddOnEnabled(module) or layoutDB.profile.disabled[key] end
		end
	end
	IsFrameDisabled.arenapet = IsFrameDisabled.arena

	-- Test if the raid style is not used
	local function IsRaidStyleUnused()
		return not oUF_Adirelle.RaidStyle or layoutDB.profile.disabled.raid
	end

	-- Test if the single style is not used
	local function IsSingleStyleUnused()
		local d = layoutDB.profile.disabled
		return not oUF_Adirelle.SingleStyle or (d.arena and d.boss and d.player and d.pet and d.pettarget and d.target and d.targettarget and d.focus)
	end

	-- Fetch the list of elements that can be disabled
	local elementList, IsElementDisabled = {}, {}
	for i, key in pairs(oUF_Adirelle.optionalElements) do
		local key = key
		elementList[key] = gsub(key, "([a-z])([A-Z])", "%1 %2")
		IsElementDisabled[key] = function() return not layoutDB.profile.elements[key] end
	end

	local colorArgs
	do
		-- Helpers to build color options
		local function SetColor(info, r, g, b, a)
			info.arg[1], info.arg[2], info.arg[3] = r, g, b
			if info.option.hasAlpha then
				info.arg[4] = a
			end
			SettingsModified('OnColorModified')
		end
		local function GetColor(info)
			return unpack(info.arg, 1, info.option.hasAlpha and 4 or 3)
		end

		-- Build one color option
		local function BuildColorArg(name, color, hasAlpha, order)
			return { name = name, type = 'color', arg = color, hasAlpha = hasAlpha, order = order or 10, get = GetColor, set = SetColor }
		end

		-- Build a group of color options from a table of colors
		local function BuildColorGroup(name, colors, names, hasAlpha)
			if not colors then return end
			local group = { name = name, type = 'group', inline = true, order = 20, args = {} }
			for key, color in pairs(colors) do
				local entryName = key
				if type(names) == "table" then
					entryName = names[key]
				elseif type(names) == "string" then
					entryName = _G[format(names, key)]
				end
				if entryName then
					group.args[tostring(key)] = BuildColorArg(entryName, color, hasAlpha, tonumber(key))
				end
			end
			if next(group.args) then
				return group
			end
		end

		-- The base color
		colorArgs = {
			class = BuildColorGroup("Class", oUF.colors.class, _G.LOCALIZED_CLASS_NAMES_MALE),
			reaction = BuildColorGroup("Reaction", oUF.colors.reaction, "FACTION_STANDING_LABEL%d"),
			power = BuildColorGroup("Power", oUF.colors.power, {
				MANA = _G.MANA,
				RAGE = _G.RAGE,
				ENERGY = _G.ENERGY,
				FOCUS = _G.FOCUS,
				RUNIC_POWER = _G.RUNIC_POWER,
				CHI = _G.CHI,
				SOUL_SHARDS = _G.SOUL_SHARDS,
				BURNING_EMBERS = _G.BURNING_EMBERS,
				DEMONIC_FURY = _G.DEMONIC_FURY,
				SHADOW_ORBS = _G.SHADOW_ORBS,
				HOLY_POWER = _G.HOLY_POWER
			}),
			health = BuildColorArg('Health', oUF.colors.health),
			disconnected = BuildColorArg('Disconnected player', oUF.colors.disconnected),
			tapped = BuildColorArg('Tapped mob', oUF.colors.tapped),
			outOfRange = BuildColorArg('Out of range', oUF.colors.outOfRange, true),
			healPrediction = BuildColorGroup("Heal prediction", oUF.colors.healPrediction, { self = "Self", others = "Others'", absorb = "Shields", healAbsorb = "Heal absorption" }, true),
			lowHealth = BuildColorArg("Low health warning", oUF.colors.lowHealth, true),
			group = {
				name = 'Group member status',
				type = 'group',
				inline = true,
				hidden = IsRaidStyleUnused,
				args = {
					vehicle = BuildColorGroup('In vehicle', oUF.colors.vehicle, {name="Name", background="Background"}),
					charmed = BuildColorGroup('Charmed', oUF.colors.charmed, {name="Name", background="Background"}),
				},
			},
		}

		-- Set up the conditions to show some color options
		colorArgs.reaction.hidden = function() return IsSingleStyleUnused() or not (themeDB.profile.Health.colorReaction or themeDB.profile.Power.colorReaction) end
		colorArgs.tapped.hidden = function() return IsSingleStyleUnused() or not (themeDB.profile.Health.colorTapping or themeDB.profile.Power.colorTapping) end
		colorArgs.power.hidden = function() return IsSingleStyleUnused() or not themeDB.profile.Power.colorPower end
		colorArgs.lowHealth.hidden = IsElementDisabled.LowHealth
		colorArgs.healPrediction.hidden = IsElementDisabled.HealPrediction
		colorArgs.outOfRange.hidden = IsElementDisabled.XRange

		-- Class-specific colors
		if oUF_Adirelle.playerClass == "DEATHKNIGHT" then
			local runes = BuildColorGroup('Runes', oUF.colors.runes, { "Blood", "Unholy", "Frost", "Death" })
			runes.hidden = IsElementDisabled.RuneBar
			colorArgs.runes = runes
		elseif oUF_Adirelle.playerClass == "SHAMAN" then
			local totems = BuildColorGroup('Totems', oUF.colors.totems, {
				[_G.FIRE_TOTEM_SLOT] = "Fire",
				[_G.EARTH_TOTEM_SLOT] = "Earth",
				[_G.WATER_TOTEM_SLOT] = "Water",
				[_G.AIR_TOTEM_SLOT] = "Air",
			})
			totems.hidden = IsElementDisabled.TotemBar
			colorArgs.totems = totems
		end
	end

	-- Build an option to set the position of auras
	local function BuildAuraSideOption(key, label, order)
		return {
			name = label,
			type = 'select',
			order = order,
			get = function(info) return layoutDB.profile.Single.Auras.sides[key] end,
			set = function(info, value)
				layoutDB.profile.Single.Auras.sides[key] = value
				SettingsModified("OnSingleLayoutModified")
			end,
			hidden = IsFrameDisabled[key],
			values = {
				TOP = 'Top',
				BOTTOM = 'Bottom',
				RIGHT = 'Right',
				LEFT = 'Left',
			},
		}
	end

	local SharedMedia = oUF_Adirelle.GetLib('LibSharedMedia-3.0')

	local function BuildFontGroup(kind, label, order)
		return {
			name = label,
			type = 'group',
			inline = true,
			order = order,
			get = function(info) return themeDB.profile.fonts[kind][info[#info]] end,
			set = function(info, value)
				themeDB.profile.fonts[kind][info[#info]] = value
				SettingsModified("OnFontModified")
			end,
			args = {
				name = {
					name = 'Font',
					type = 'select',
					dialogControl = 'LSM30_Font',
					values = function() return SharedMedia:HashTable("font") end,
					order = 10,
				},
				scale = {
					name = 'Scale',
					type = 'range',
					isPercent = true,
					min = 0.05,
					max = 2.0,
					step = 0.05,
					order = 20,
				},
				flags = {
					name = 'Outline',
					type = 'select',
					values = {
						[""] = "None",
						["DEFAULT"] = "Default",
						["OUTLINE"] = "Thin",
						["THICKOUTLINE"] = "Thick",
					},
					order = 30,
				},
			}
		}
	end

	-- Build the big table
	options = {
		name = 'oUF_Adirelle '..oUF_Adirelle.VERSION,
		type = 'group',
		childGroups = 'tab',
		args = {
			_combatLockdown = {
				name = '|cffff0000WARNING:|r some settings are unavailable because of addon restrictions during fights.',
				type = 'description',
				hidden = function() return not IsLockedDown() end,
			},
			modules = {
				name = 'Modules',
				type = 'group',
				childGroups = 'tree',
				order = -10,
				disabled = IsLockedDown,
				args = {
					modules = {
						name = 'Enabled modules',
						desc = 'There you can enable and disable the frame modules. This is the same as disabling the matching addons on the character selection screen. These settings are specific to each character and require to reload the interface to apply the changes.',
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
				args = {
					frames = {
						name = 'Frames',
						type = 'group',
						order = 20,
						disabled = IsLockedDown,
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
							lock = oUF_Adirelle.ToggleLock and {
								name = function()
									return oUF_Adirelle.IsLocked() and "Unlock" or "Lock"
								end,
								type = 'execute',
								order = 40,
								func = oUF_Adirelle.ToggleLock,
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
							SettingsModified("OnElementsModified")
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
									HealPrediction = "Heal prediction",
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
									TargetIcon = "Target raid icon",
									Combat = "Combat",
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
									Portrait = "Portrait",
									CustomClick = "Dispel on right-click (raid units)",
								},
							},
						},
					},
					Single = {
						name = 'Unit frames',
						type = 'group',
						order = 30,
						get = function(info) return layoutDB.profile.Single[info[#info]] end,
						set = function(info, value)
							layoutDB.profile.Single[info[#info]] = value
							SettingsModified("OnSingleLayoutModified")
						end,
						hidden = IsSingleStyleUnused,
						args = {
							width = {
								name = 'Width',
								type = 'range',
								disabled = IsLockedDown,
								order = 10,
								min = 80,
								max = 250,
								step = 1,
								bigStep = 5,
							},
							heightBig = {
								name = 'Large frame height',
								type = 'range',
								disabled = IsLockedDown,
								order = 20,
								min = 37,
								max = 87,
								step = 1,
								bigStep = 5,
							},
							heightSmall = {
								name = 'Thin frame height',
								type = 'range',
								disabled = IsLockedDown,
								order = 30,
								min = 10,
								max = 40,
								step = 1,
							},
							Auras = {
								name = 'Buffs & debuffs',
								type = 'group',
								inline = true,
								order = 40,
								get = function(info, key)
									if info.type == 'multiselect' then
										return layoutDB.profile.Single.Auras[info[#info]][key]
									else
										return layoutDB.profile.Single.Auras[info[#info]]
									end
								end,
								set = function(info, ...)
									if info.type == 'multiselect' then
										local key, value = ...
										layoutDB.profile.Single.Auras[info[#info]][key] = value
									else
										layoutDB.profile.Single.Auras[info[#info]] = ...
									end
									SettingsModified("OnSingleLayoutModified")
								end,
								args = {
									size = {
										name = 'Icon size',
										desc = 'Set the ',
										type = 'range',
										order = 10,
										min = 8,
										max = 32,
										step = 1,
									},
									spacing = {
										name = 'Spacing',
										type = 'range',
										order = 20,
										min = 0,
										max = 8,
										step = 1,
									},
									enlarge = {
										name = 'Enlarge special auras',
										type = 'toggle',
										order = 30,
									},
									_ = {
										name = 'Filters',
										type = 'header',
										order = 40,
									},
									numBuffs = {
										name = 'Maximum buffs',
										desc = 'Set the maximum number of displayed buffs; the excess one are hidden.',
										type = 'range',
										min = 0,
										max = 32,
										step = 1,
										bigStep = 4,
										order = 45,
									},
									buffFilter = {
										name = 'Buffs to ignore',
										desc = 'Select which buffs should be displayed in combat. Buffs matching any checked category are hidden.',
										type = 'multiselect',
										width = 'double',
										values = {
											permanent     = 'Permanent buffs',
											allies        = "Allies' buffs",
											consolidated  = 'Raid buffs',
											undispellable = "Buffs I cannot dispell/steal (on enemy)",
										},
										disabled = function() return oUF_Adirelle.layoutDB.profile.Single.Auras.numBuffs == 0 end,
										order = 50,
									},
									numDebuffs = {
										name = 'Maximum debuffs',
										desc = 'Set the maximum number of displayed debuffs; the excess one are hidden.',
										type = 'range',
										min = 0,
										max = 40,
										step = 1,
										bigStep = 4,
										order = 55,
									},
									debuffFilter = {
										name = 'Debuffs to ignore',
										desc = 'Select which debuffs should be displayed in combat. Debuffs matching any checked category are hidden.',
										type = 'multiselect',
										width = 'double',
										values = {
											permanent     = 'Permanent debuffs',
											allies        = "Allies' debuffs",
											undispellable = "Debuffs I cannot dispell (on ally)",
											unknown       = "Debuffs I cannot apply",
										},
										disabled = function() return oUF_Adirelle.layoutDB.profile.Single.Auras.numDebuffs == 0 end,
										order = 60,
									},
									_sides = {
										name = 'Aura side',
										type = 'header',
										order = 100,
									},
									target = BuildAuraSideOption('target', 'Target', 105),
									focus = BuildAuraSideOption('focus', 'Focus', 110),
									pet = BuildAuraSideOption('pet', 'Pet', 115),
									boss = BuildAuraSideOption('boss', 'Bosses', 120),
									arena = BuildAuraSideOption('arena', 'Arena enemies', 125),
								},
							},
						},
					},
					Raid = {
						name = 'Group grid',
						type = 'group',
						order = 40,
						get = function(info) return layoutDB.profile.Raid[info[#info]] end,
						set = function(info, value)
							layoutDB.profile.Raid[info[#info]] = value
							SettingsModified("OnRaidLayoutModified")
						end,
						hidden = IsRaidStyleUnused,
						disabled = IsLockedDown,
						args = {
							width = {
								name = 'Cell width',
								desc = 'The width of each unit cell, in pixels.',
								order = 10,
								type = 'range',
								min = 60,
								max = 160,
								step = 1,
								bigStep = 5,
							},
							height = {
								name = 'Cell height',
								desc = 'The default height of each unit cell, in pixels.',
								order = 20,
								type = 'range',
								min = 20,
								max = 80,
								step = 1,
							},
							healerHeight = {
								name = 'Healer cell height',
								desc = 'The height of unit cells when playing a healer spec and there are 25 people or less in the raid.',
								order = 30,
								type = 'range',
								min = 20,
								max = 80,
								step = 1,
							},
							alignment = {
								name = 'Alignement',
								desc = 'Select how the units should be aligned with regard to the anchor.',
								type = 'select',
								order = 40,
								values = {
									TOPLEFT = 'Top left',
									TOP = 'Top',
									TOPRIGHT = 'Top right',
									LEFT = 'Left',
									CENTER = 'Center',
									RIGHT = 'Right',
									BOTTOMLEFT = 'Bottom left',
									BOTTOM = 'Bottom',
									BOTTOMRIGHT = 'Bottom right',
								},
							},
							orientation = {
								name = 'Group shape',
								desc = 'Select how each group is displayed individually.',
								type = 'select',
								order = 50,
								values = {
									horizontal = "Rows",
									vertical = "Columns",
								},
							},
							unitSpacing = {
								name = 'Unit spacing',
								desc = 'The size of the space between cells of the same group, in pixels.',
								type = 'range',
								order = 60,
								min = 2,
								max = 20,
								step = 1,
							},
							groupSpacing = {
								name = 'Group spacing',
								desc = 'The size of the space between groups, in pixels.',
								type = 'range',
								order = 70,
								min = 2,
								max = 20,
								step = 1,
							},
							smallIconSize = {
								name = 'Small icon size',
								desc = 'The size of small icons, in pixels.',
								type = 'range',
								order = 80,
								min = 5,
								max = 32,
								step = 1,
							},
							bigIconSize = {
								name = 'Large icon size',
								desc = 'The size of large icons, in pixels.',
								type = 'range',
								order = 80,
								min = 5,
								max = 32,
								step = 1,
							},
							showTanks = {
								name = 'Show tank group',
								desc = 'Enable to show a separate group with tanks.',
								type = 'toggle',
								order = 90,
							},
							showPets = {
								name = 'Show pets in...',
								type = 'multiselect',
								order = 100,
								values = {
									party = "5-man groups",
									raid10 = "10-man groups",
									raid15 = "15-man groups",
									raid25 = "25-man groups",
									raid40 = "40-man groups",
									arena = "Arenas",
									battleground = "Battlegrounds",
								},
								get = function(info, key) return layoutDB.profile.Raid.showPets[key] end,
								set = function(info, key, value)
									layoutDB.profile.Raid.showPets[key] = value
									SettingsModified("OnRaidLayoutModified")
								end,
							},
							strictSize = {
								name = 'Strict raid size',
								desc = 'When enabled, oUF_Adirelle will only show groups according to instance size, e.g. only groups 1 and 2 for a 10-man raid or battleground.',
								type = 'toggle',
								order = 110,
							},
						},
					},
					unitTooltip = {
						name = 'Unit tooltip',
						type = 'group',
						get = function(info) return layoutDB.profile.unitTooltip[info[#info]] end,
						set = function(info, value)
							layoutDB.profile.unitTooltip[info[#info]] = value
							SettingsModified("OnUnitTooltipModified")
						end,
						order = 45,
						args = {
							enabled = {
								name = 'Enabled',
								desc = 'Uncheck to totally disable unit tooltips.',
								type = 'toggle',
								order = 10,
							},
							inCombat = {
								name = 'In Combat',
								desc = 'Uncheck to disable tooltips in combat.',
								type = 'toggle',
								order = 20,
								disabled = function() return not layoutDB.profile.unitTooltip.enabled end,
							},
							anchor = {
								name = 'Anchoring',
								desc = 'Select how the unit tooltip should be placed.',
								type = 'select',
								values = {
									DEFAULT = 'At the default position',
									ANCHOR_TOP = 'Above the unit frame',
									ANCHOR_BOTTOM = 'Below the unit frame',
								},
								order = 30,
								disabled = function() return not layoutDB.profile.unitTooltip.enabled end,
							},
							fadeOut = {
								name = 'Fade out',
								desc = 'When enabled, the tooltip fades out when the mouse pointer leaves it. If disabled, the tooltip is immediately hidden.',
								type = 'toggle',
								order = 40,
								disabled = function() return not layoutDB.profile.unitTooltip.enabled end,
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
						order = 10,
						args = {
							statusbar = {
								name = 'Bar texture',
								type = 'select',
								dialogControl = 'LSM30_Statusbar',
								order = 10,
								values = function() return SharedMedia:HashTable("statusbar") end,
								get = function()
									return themeDB.profile.statusbar
								end,
								set = function(_, value)
									themeDB.profile.statusbar = value
									SettingsModified("OnTextureModified")
								end,
							},
							text = BuildFontGroup("text", "Text", 20),
							number = BuildFontGroup("number", "Number", 30),
							raid = BuildFontGroup("raid", "Raid frame text", 40),
						},
					},
					single = {
						name = 'Basic/arena/boss frames',
						type = 'group',
						order = 20,
						hidden = IsSingleStyleUnused,
						args = {
							healthColor = {
								name = 'Health bar color',
								desc = 'Select which conditions affect the health bar color',
								type = 'multiselect',
								order = 10,
								get = function(info, key) return themeDB.profile.Health[key] end,
								set = function(info, key, value)
									themeDB.profile.Health[key] = value
									SettingsModified('OnSingleThemeModified')
								end,
								values = {
									colorTapping = 'Tapped mobs',
									colorDisconnected = 'Disconnected players',
									colorClass = 'Class (Player)',
									colorClassNPC = 'Class (NPC)',
									colorClassPet = 'Class (Pet)',
									colorReaction = 'Reaction',
									colorSmooth = 'Smooth',
								},
							},
							powerColor = {
								name = 'Power bar color',
								desc = 'Select which conditions affect the power bar color',
								type = 'multiselect',
								order = 20,
								get = function(info, key) return themeDB.profile.Power[key] end,
								set = function(info, key, value)
									themeDB.profile.Power[key] = value
									SettingsModified('OnSingleThemeModified')
								end,
								values = {
									colorTapping = 'Tapped mobs',
									colorDisconnected = 'Disconnected players',
									colorPower = 'Power type',
									colorClass = 'Class (Player)',
									colorClassNPC = 'Class (NPC)',
									colorClassPet = 'Class (Pet)',
									colorReaction = 'Reaction',
									colorSmooth = 'Smooth',
								},
							},
						},
					},
					warningThresholds = {
						name = 'Warning thresholds',
						type = 'group',
						order = 30,
						hidden = function(info) return IsElementDisabled[info.arg] and IsElementDisabled[info.arg]() end,
						get = function(info) return themeDB.profile[info.arg][info[#info]] end,
						set = function(info, value)
							themeDB.profile[info.arg][info[#info]] = value
							SettingsModified('OnThemeModified')
						end,
						arg = '*',
						args = {
							Health = {
								name = 'Health',
								type = 'group',
								inline = true,
								order = 10,
								arg = 'LowHealth',
								args = {
									isPercent = {
										name = 'Percentage instead of amount',
										type = 'toggle',
										order = 20,
										arg = 'LowHealth',
									},
									percent = {
										name = 'Threshold',
										type = 'range',
										order = 30,
										arg = 'LowHealth',
										isPercent = true,
										min = 0.05,
										max = 0.95,
										step = 0.01,
										bigStep = 0.05,
										hidden = function() return not themeDB.profile.LowHealth.isPercent end,
									},
									amount = {
										name = 'Threshold',
										type = 'range',
										order = 0,
										arg = 'LowHealth',
										min = 1000,
										max = 200000,
										step = 100,
										bigStep = 1000,
										hidden = function() return themeDB.profile.LowHealth.isPercent end,
									},
								},
							},
							Mana = {
								name = 'Mana',
								type = 'group',
								inline = true,
								order = 20,
								arg = 'Border',
								args = {
									_manaDesc = {
										type = 'description',
										order = 210,
										arg = 'Border',
										name = 'These thresholds are used to display the blue border around units that are considered "out of mana".',
									},
									inCombatManaLevel = {
										name = 'In combat',
										type = 'range',
										order = 220,
										arg = 'Border',
										isPercent = true,
										min = 0,
										max = 1,
										step = 0.01,
										bigStep = 0.05,
									},
									oocInRaidManaLevel = {
										name = 'Out of combat in raid instances',
										type = 'range',
										order = 230,
										arg = 'Border',
										isPercent = true,
										min = 0,
										max = 1,
										step = 0.01,
										bigStep = 0.05,
									},
									oocManaLevel = {
										name = 'Out of combat',
										type = 'range',
										order = 240,
										arg = 'Border',
										isPercent = true,
										min = 0,
										max = 1,
										step = 0.01,
										bigStep = 0.05,
									},
								},
							},
						},
					},
					colors = {
						name = 'Colors',
						type = 'group',
						order = -10,
						args = colorArgs,
					},
					profiles = themeDBOptions
				},
			},
		},
	}

	local function UpdateConfig()
		LibStub("AceConfigRegistry-3.0"):NotifyChange("oUF_Adirelle")
	end

	oUF_Adirelle:RegisterEvent("PLAYER_REGEN_DISABLED", UpdateConfig)
	oUF_Adirelle:RegisterEvent("PLAYER_REGEN_ENABLED", UpdateConfig)

	return options
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("oUF_Adirelle", GetOptions)

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

function oUF_Adirelle.ToggleConfig(...)
	if not AceConfigDialog:Close("oUF_Adirelle") then
		AceConfigDialog:SelectGroup("oUF_Adirelle", ...)
		AceConfigDialog:Open("oUF_Adirelle")
	end
end

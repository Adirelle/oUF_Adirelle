--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

if oUF_Adirelle.SingleStyle then return end

--<GLOBALS
local _G = _G
local abs = _G.abs
local CreateFrame = _G.CreateFrame
local ECLIPSE_MARKER_COORDS = _G.ECLIPSE_MARKER_COORDS
local GetEclipseDirection = _G.GetEclipseDirection
local GetRuneType = _G.GetRuneType
local PowerBarColor = _G.PowerBarColor
local SPELL_POWER_ECLIPSE = _G.SPELL_POWER_ECLIPSE
local SPELL_POWER_MANA = _G.SPELL_POWER_MANA
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitPowerType = _G.UnitPowerType
local unpack = _G.unpack
--GLOBALS>

local GAP = private.GAP

local playerClass = oUF_Adirelle.playerClass

if playerClass == 'DRUID' then
	-- Eclipse Bar
	local eclipseColors = {
		lunar = {
			 sun = { 136/255, 200/255, 224/255 },
			moon = {  24/255,  36/255,  80/255 },
			none = {  56/255, 100/255, 168/255 } ,
		},
		solar = {
			moon = { 232/255, 212/255, 120/255 },
			 sun = {  88/255,  36/255,   8/255 },
			none = { 205/255, 148/255,  43/255 },
		}
	}

	local function EclipseText_Update(eclipseBar, unit)
		if unit and unit ~= "player" or not eclipseBar:IsVisible() then return end
		eclipseBar.Text:SetText(abs(UnitPower("player", SPELL_POWER_ECLIPSE) / UnitPowerMax("player", SPELL_POWER_ECLIPSE) * 100))

		local eclipse = (eclipseBar.hasLunarEclipse and "moon") or (eclipseBar.hasSolarEclipse and "sun") or "none"
		eclipseBar.LunarBar:SetStatusBarColor(unpack(eclipseColors.solar[eclipse], 1, 3))
		eclipseBar:SetBackdropColor(unpack(eclipseColors.lunar[eclipse], 1, 3))

		local direction = GetEclipseDirection() or "none"
		local mark = eclipseBar.mark
		mark:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS[direction]))
		if direction == "sun" then
			mark:SetPoint("CENTER", eclipseBar, "CENTER", eclipseBar:GetWidth() / 4, 0)
			mark:Show()
		elseif direction == "moon" then
			mark:SetPoint("CENTER", eclipseBar, "CENTER", -eclipseBar:GetWidth() / 4, 0)
			mark:Show()
		else
			mark:Hide()
		end
	end

	private.SetupSecondaryPowerBar = function(self)
		local eclipseBar = CreateFrame("Frame", nil, self)
		eclipseBar.PostUnitAura = EclipseText_Update
		eclipseBar.PostDirectionChange  = EclipseText_Update
		eclipseBar.PostUpdateVisibility = EclipseText_Update
		eclipseBar.PostUpdatePower  = EclipseText_Update
		eclipseBar:SetBackdrop({
			bgFile = [[Interface\AddOns\oUF_Adirelle\media\white16x16]],
			tile = true, tileSize = 16,
			insets = {left = 0, right = 0, top = 0, bottom = 0},
		})
		eclipseBar.color = PowerBarColor.ECLIPSE.negative
		self.EclipseBar = eclipseBar

		local lunar = CreateFrame("StatusBar", nil, eclipseBar)
		lunar:SetAllPoints(eclipseBar)
		lunar:SetStatusBarTexture([[Interface\AddOns\oUF_Adirelle\media\white16x16]])
		lunar.color = PowerBarColor.ECLIPSE.positive
		eclipseBar.LunarBar = lunar

		local text = private.SpawnText(self, lunar, "OVERLAY", "CENTER", "CENTER", 0, 0, "number", nil, "OUTLINE")
		text:SetShadowColor(0, 0, 0, 0)
		eclipseBar.Text = text

		local mark = lunar:CreateTexture(nil, "OVERLAY")
		mark:SetSize(20, 20)
		mark:SetPoint("CENTER")
		mark:SetTexture([[Interface\PlayerFrame\UI-DruidEclipse]])
		mark:SetBlendMode("ADD")
		eclipseBar.mark = mark

		return eclipseBar
	end

elseif playerClass == 'DEATHKNIGHT' then
	-- Runes
	local function UpdateRuneColor(rune)
		local color = oUF.colors.runes[GetRuneType(rune.index) or false]
		if color then
			rune:SetStatusBarColor(unpack(color))
		end
	end

	private.SetupSecondaryPowerBar = function(self)
		local runeBar = private.SpawnDiscreteBar(self, 6, true)
		self.RuneBar = runeBar
		runeBar:SetMinMaxValues(0, 6)
		runeBar:SetValue(6)
		for i = 1, 6 do
			runeBar[i].UpdateRuneColor = UpdateRuneColor
		end
		return runeBar
	end

elseif playerClass == "SHAMAN" then
	-- Totems
	private.SetupSecondaryPowerBar = function(self)
		local MAX_TOTEMS, SHAMAN_TOTEM_PRIORITIES = _G.MAX_TOTEMS, _G.SHAMAN_TOTEM_PRIORITIES
		local bar = private.SpawnDiscreteBar(self, MAX_TOTEMS, true)
		for i = 1, MAX_TOTEMS do
			local totemType = SHAMAN_TOTEM_PRIORITIES[i]
			bar[i].totemType = totemType
			bar[i]:SetStatusBarColor(unpack(oUF.colors.totems[totemType], 1, 3))
		end
		self.TotemBar = bar
		return bar
	end

elseif playerClass == 'MONK' then
	-- Stagger bar
	private.SetupSecondaryPowerBar = function(self)
		local bar = private.SpawnStatusBar(self)
		self.Stagger = bar
		return bar
	end
end


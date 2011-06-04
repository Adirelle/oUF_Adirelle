--[=[
Adirelle's oUF layout
(c) 2009-2011 Adirelle (adirelle@tagada-team.net)
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

if playerClass == "DRUID" then
	-- Druid mana bar

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

	local function AltPower_Update(power, unit)
		power:GetParent().EclipseBar:ForceUpdate()
		local manaBar = power:GetParent().AltPower.ManaBar
		if unit == 'player' and UnitPowerType(unit) ~= SPELL_POWER_MANA then
			local current, max = UnitPower(unit, SPELL_POWER_MANA), UnitPowerMax(unit, SPELL_POWER_MANA)
			if max and max > 0 then
				manaBar:SetMinMaxValues(0, max)
				manaBar:SetValue(current)
				return manaBar:Show()
			end
		end
		return manaBar:Hide()
	end

	private.SetupSecondaryPowerBar = function(self)
		local altPower = CreateFrame("Frame", nil, self)
		self.AltPower = altPower

		local manaBar = private.SpawnStatusBar(self)
		manaBar:SetAllPoints(altPower)
		manaBar:SetStatusBarColor(unpack(self.colors.power.MANA,1,3))
		manaBar:Hide()
		altPower.ManaBar = manaBar

		if self.Power.PostUpdate then
			local orig = self.Power.PostUpdate
			self.Power.PostUpdate = function(...)
				AltPower_Update(...)
				return orig(...)
			end
		else
			self.Power.PostUpdate = AltPower_Update
		end

		local eclipseBar = CreateFrame("Frame", nil, self)
		eclipseBar:SetAllPoints(altPower)
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

		local text = private.SpawnText(lunar, "OVERLAY", "CENTER", "CENTER", 0, 0)
		local name, size = text:GetFont()
		text:SetFont(name, size, "OUTLINE")
		text:SetShadowColor(0, 0, 0, 0)
		eclipseBar.Text = text

		local mark = lunar:CreateTexture(nil, "OVERLAY")
		mark:SetSize(20, 20)
		mark:SetPoint("CENTER")
		mark:SetTexture([[Interface\PlayerFrame\UI-DruidEclipse]])
		mark:SetBlendMode("ADD")
		eclipseBar.mark = mark

		local function UpdateAltPower()
			if manaBar:IsShown() or eclipseBar:IsShown() then
				altPower:Show()
			else
				altPower:Hide()
			end
		end
		manaBar:HookScript('OnShow', UpdateAltPower)
		manaBar:HookScript('OnHide', UpdateAltPower)
		eclipseBar:HookScript('OnShow', UpdateAltPower)
		eclipseBar:HookScript('OnHide', UpdateAltPower)

		return altPower
	end

elseif playerClass == "WARLOCK" then
	-- Soul shards
	private.SetupSecondaryPowerBar = function(self)
		-- Display them in the mana bar, without changing its size
		local shards = {}
		local parent, anchor = self.Indicators, self.Power
		local scale = 1/1.2
		local w, h = scale*17, scale*16
		for index = 1, _G.SHARD_BAR_NUM_SHARDS do
			local shard = parent:CreateTexture(nil, "OVERLAY")
			shard:SetTexture([[Interface\PlayerFrame\UI-WarlockShard]])
			shard:SetSize(w, h)
			shard:SetTexCoord(0.01562500, 0.28125000, 0.00781250, 0.13281250)
			shard:SetPoint("CENTER", anchor, "BOTTOM", (index-2)*(w+GAP), -GAP/2)
			shards[index] = shard
		end
		self.SoulShards = shards
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

elseif playerClass == "PALADIN" then
	-- Holy power
	private.SetupSecondaryPowerBar = function(self)
		local bar = private.SpawnDiscreteBar(self, _G.MAX_HOLY_POWER)
		local r, g, b = unpack(oUF.colors.power.HOLY_POWER, 1, 3)
		for i = 1, _G.MAX_HOLY_POWER do
			bar[i]:SetVertexColor(r, g, b)
		end
		self.HolyPower = bar
		return bar
	end
end


--[=[
Adirelle's oUF layout
(c) 2009-2010 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

-- Use our own namespace
setfenv(1, _G.oUF_Adirelle)

local BORDER_WIDTH = 2
local TEXT_MARGIN = 2
local GAP = 2
local FRAME_MARGIN = BORDER_WIDTH + GAP
local AURA_SIZE = 22

local borderBackdrop = { edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]], edgeSize = BORDER_WIDTH }

local floor = math.floor
local strformat = string.format

local function smartValue(value)
	if value >= 10000000 then
		return strformat("%.1fm", value/1000000)
	elseif value >= 10000 then
		return strformat("%.1fk", value/1000)
	else
		return tostring(value)
	end
end

local function OnStatusBarUpdate(bar)
	if not bar:IsShown() then return end
	local text = bar.Text
	if not text then return end
	local value, min, max = bar:GetValue(), bar:GetMinMaxValues()
	if max == 100 then
		text:SetFormattedText("%d%%", floor(value))
	elseif max <= 1 then
		return text:Hide()
	else
		local perValue = ((value < max) and UnitClassification(bar:GetParent().unit) ~= 'normal') and strformat("%d%% ", floor(value/max*100)) or ""
		local maxValue = smartValue(max)
		local curValue = value < max and (smartValue(value).."/") or ""
		text:SetText(strjoin('', perValue, curValue, maxValue))
	end
	text:Show()
end

local fontPath, fontSize, fontFlags = GameFontWhiteSmall:GetFont()
local lsm = GetLib('LibSharedMedia-3.0')
if lsm then
	local altFont = lsm:Fetch("font", "ABF", true)
	if altFont then
		fontPath, fontSize, fontFlags = altFont, 12, ""
	end
end

local function SetFont(fs, size, flags)
	fs:SetFont(fontPath, size or fontSize, flags or fontFlags)
	fs:SetTextColor(1, 1, 1, 1)
	fs:SetShadowColor(0, 0, 0, 1)
	fs:SetShadowOffset(1, -1)
end

local function SpawnTexture(object, size, to, xOffset, yOffset)
	local texture = object:CreateTexture(nil, "OVERLAY")
	texture:SetWidth(size)
	texture:SetHeight(size)
	texture:SetPoint("CENTER", object, to or "CENTER", xOffset or 0, yOffset or 0)
	return texture
end

local function SpawnText(object, layer, from, to, xOffset, yOffset)
	local text = object:CreateFontString(nil, layer)
	SetFont(text)
	text:SetWidth(0)
	text:SetHeight(0)
	text:SetJustifyV("MIDDLE")
	if from then
		text:SetPoint(from, object, to or from, xOffset or 0, yOffset or 0)
		if from:match("RIGHT") then
			text:SetJustifyH("RIGHT")
		elseif from:match("LEFT") then
			text:SetJustifyH("LEFT")
		else
			text:SetJustifyH("CENTER")
		end
	else
		text:SetJustifyH("LEFT")
	end
	return text
end

local function SpawnStatusBar(self, noText, from, anchor, to, xOffset, yOffset)
	local bar = CreateFrame("StatusBar", nil, self)
	if not noText then
		local text = SpawnText(bar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
		text:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
		bar.Text = text
		bar:SetScript('OnShow', OnStatusBarUpdate)
		bar:SetScript('OnValueChanged', OnStatusBarUpdate)
		bar:SetScript('OnMinMaxChanged', OnStatusBarUpdate)
	end
	if from then
		bar:SetPoint(from, anchor or self, to or from, xOffset or 0, yOffset or 0)
	end
	self:RegisterStatusBarTexture(bar)
	return bar
end

local IncomingHeal_PostUpdate, Health_PostUpdate
if oUF.HasIncomingHeal then
	local function UpdateHealBar(bar, unit, current, max, incoming)
		if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
			current, incoming  = 0, 0
		end
		if bar.incoming ~= incoming or bar.current ~= current or bar.max ~= max then
			bar.incoming, bar.current, bar.max = incoming, current, max
			local health = bar:GetParent()
			if current and max and incoming and incoming > 0 and max > 0 and current < max then
				local width = health:GetWidth()
				bar:SetPoint("LEFT", width * current / max, 0)
				bar:SetWidth(width * math.min(incoming, max-current) / max)
				bar:Show()
			else
				bar:Hide()
			end
		end
	end

	function IncomingHeal_PostUpdate(bar, event, unit, incoming)
		return UpdateHealBar(bar, unit, bar.current, bar.max, incoming or 0)
	end

	function Health_PostUpdate(healthBar, unit, current, max)
		local bar = healthBar:GetParent().IncomingHeal
		return UpdateHealBar(bar, unit, current, max, bar.incoming)
	end
end

local function Auras_PostCreateIcon(icons, button)
	button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.cd.noCooldownCount = true
	button.cd:SetReverse(true)
	button.cd:SetDrawEdge(true)
end

local LibDispellable = GetLib("LibDispellable-1.0")

local function IsMine(unit)
	return unit and (UnitIsUnit(unit, 'player') or UnitIsUnit(unit, 'pet') or UnitIsUnit(unit, 'vehicle'))
end

local function Buffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura)
	if UnitCanAttack("player", unit) then
		icon.bigger = LibDispellable:CanDispel(unit, true, dtype, spellID) or (canSteal and isStealable)
		return true
	elseif UnitCanAssist("player", unit) then
		icon.bigger = IsMine(caster)
		if UnitAffectingCombat("player") then
			return duration > 0 and (icon.bigger or canApplyAura or not shouldConsolidate)
		else
			return true
		end
	end
	return true
end

local canSteal = select(2, UnitClass("player")) == "MAGE"
local function Debuffs_CustomFilter(icons, unit, icon, name, rank, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
	if UnitCanAttack("player", unit) then
		icon.bigger = IsMine(caster)
	elseif UnitCanAssist("player", unit) then
		icon.bigger = isBossDebuff or IsMine(caster) or LibDispellable:CanDispel(unit, false, dtype, spellID)
	end
	return true
end

local Auras_SetPosition
do
	local function CompareIcons(a, b)
		if a.bigger and not b.bigger then
			return true
		elseif not a.bigger and b.bigger then
			return false
		else
			return a:GetID() < b:GetID()
		end
	end

	function Auras_SetPosition(icons, numIcons)
		if not icons or numIcons == 0 then return end
		local spacing = icons.spacing or 0
		local size = icons.size or 16
		local anchor = icons.initialAnchor or "BOTTOMLEFT"
		local growthx = (icons["growth-x"] == "LEFT" and -1) or 1
		local growthy = (icons["growth-y"] == "DOWN" and -1) or 1
		local x = 0
		local y = 0
		local rowSize = 0
		local width = math.floor(icons:GetWidth() / size) * size
		local height = math.floor(icons:GetHeight() / size) * size

		table.sort(icons, CompareIcons)
		for i = 1, #icons do
			local button = icons[i]
			if button:IsShown() then
				local iconSize = button.bigger and size or size * 0.75
				rowSize = math.max(rowSize, iconSize)
				button:ClearAllPoints()
				button:SetWidth(iconSize)
				button:SetHeight(iconSize)
				button:SetPoint(anchor, icons, anchor, x * growthx, y * growthy)
				x = x + iconSize + spacing
				if x >= width then
					y = y + rowSize + spacing
					x = 0
					rowSize = 0
					if y >= height then
						for j = i+1, #icons do
							icons[j]:Hide()
						end
						return
					end
				end
			end
		end
	end
end

local SetupAltPower
if playerClass == 'DEATHKNIGHT' then
	-- Death Knight Runes

	oUF.colors.runes = oUF.colors.runes or {
		{ 1, 0, 0  },
		{ 0, 0.5, 0 },
		{ 0, 1, 1 },
		{ 0.8, 0.1, 1 },
	}

	local function UpdateRuneColor(rune)
		local color = oUF.colors.runes[GetRuneType(rune.index) or false]
		if color then
			rune:SetStatusBarColor(unpack(color))
		end
	end


	local function LayoutRunes(runeBar)
		local spacing = (runeBar:GetWidth() + GAP) / 6
		local runeWidth = spacing - GAP
		local runeHeight = runeBar:GetHeight()
		for index = 1, 6 do
			local rune = runeBar[index]
			rune:SetPoint("TOPLEFT", runeBar, "TOPLEFT", spacing * (index-1), 0)
			rune:SetWidth(runeWidth)
			rune:SetHeight(runeHeight)
		end
	end

	function SetupAltPower(self)
		local runeBar = CreateFrame("Frame", nil, self)
		runeBar:SetScript('OnShow', LayoutRunes)
		runeBar:SetScript('OnSizeChanged', LayoutRunes)
		self.RuneBar = runeBar
		for index = 1, 6 do
			local rune = CreateFrame("StatusBar", nil, runeBar)
			rune.index = index
			rune.UpdateRuneColor = UpdateRuneColor
			self:RegisterStatusBarTexture(rune, UpdateRuneColor)
			runeBar[index] = rune
		end
		return runeBar
	end

elseif playerClass == "DRUID" then
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

	local SPELL_POWER_MANA = SPELL_POWER_MANA
	local SPELL_POWER_ECLIPSE = SPELL_POWER_ECLIPSE

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

	function AltPower_Update(power, unit)
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

	function SetupAltPower(self)
		local altPower = CreateFrame("Frame", nil, self)
		self.AltPower = altPower

		local manaBar = SpawnStatusBar(self)
		manaBar:SetAllPoints(altPower)
		manaBar.textureColor = oUF.colors.power.MANA
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

		local text = SpawnText(lunar, "OVERLAY", "CENTER", "CENTER", 0, 0)
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

elseif playerClass == "SHAMAN" then
	-- Shaman totems
	local MAX_TOTEMS = MAX_TOTEMS

	oUF.colors.totems = oUF.colors.totems or {
		[FIRE_TOTEM_SLOT] = { 1, 0.3, 0.0  },
		[EARTH_TOTEM_SLOT] = { 0.3, 1, 0.2 },
		[WATER_TOTEM_SLOT] = { 0.3, 0.2, 1 },
		[AIR_TOTEM_SLOT] = { 0.2, 0.8, 1 },
	}

	local function UpdateTotemColor(totem)
		local color = oUF.colors.totems[totem.totemType]
		if color then
			totem:SetStatusBarColor(unpack(color))
		end
	end

	local function LayoutTotems(totemBar)
		local spacing = (totemBar:GetWidth() + GAP) / MAX_TOTEMS
		local totemWidth = spacing - GAP
		local totemHeight = totemBar:GetHeight()
		for index = 1, MAX_TOTEMS do
			local totem = totemBar[index]
			totem:SetPoint("TOPLEFT", totemBar, "TOPLEFT", spacing * (index-1), 0)
			totem:SetWidth(totemWidth)
			totem:SetHeight(totemHeight)
		end
	end

	function SetupAltPower(self)
		local totemBar = CreateFrame("Frame", nil, self)
		totemBar:SetScript('OnShow', LayoutTotems)
		totemBar:SetScript('OnSizeChanged', LayoutTotems)
		self.TotemBar = totemBar
		for index = 1, MAX_TOTEMS do
			local totem = CreateFrame("StatusBar", nil, totemBar)
			totem.totemType = SHAMAN_TOTEM_PRIORITIES[index]
			self:RegisterStatusBarTexture(totem, UpdateTotemColor)
			totemBar[index] = totem
		end
		return totemBar
	end

elseif playerClass == "WARLOCK" then
	-- Warlock shards

	function SetupAltPower(self)
		-- Display them in the mana bar, without changing its size
		local shards = {}
		local parent, anchor = self.Indicators, self.Power
		local scale = 1/1.2
		local w, h = scale*17, scale*16
		for index = 1, SHARD_BAR_NUM_SHARDS do
			local shard = parent:CreateTexture(nil, "OVERLAY")
			shard:SetTexture([[Interface\PlayerFrame\UI-WarlockShard]])
			shard:SetSize(w, h)
			shard:SetTexCoord(0.01562500, 0.28125000, 0.00781250, 0.13281250)
			shard:SetPoint("CENTER", anchor, "BOTTOM", (index-2)*(w+GAP), -GAP/2)
			shards[index] = shard
		end
		self.SoulShards = shards
	end

elseif playerClass == "PALADIN" then
	-- Paladin holy power

	local function LayoutHolyPower(holyPowerBar)
		local spacing = (holyPowerBar:GetWidth() + GAP) / MAX_HOLY_POWER
		local width = spacing - GAP
		local height = holyPowerBar:GetHeight()
		for index = 1, MAX_HOLY_POWER do
			local power = holyPowerBar[index]
			power:SetPoint("TOPLEFT", holyPowerBar, "TOPLEFT", spacing * (index-1), 0)
			power:SetSize(width, height)
		end
	end

	local color = PowerBarColor.HOLY_POWER
	local function SetHolyPowerColor(power)
		power:SetStatusBarColor(color.r, color.g, color.b)
	end

	function SetupAltPower(self)
		local holyPowerBar = CreateFrame("Frame", nil, self)
		holyPowerBar:SetScript('OnShow', LayoutHolyPower)
		holyPowerBar:SetScript('OnSizeChanged', LayoutHolyPower)
		self.HolyPower = holyPowerBar
		for index = 1, MAX_HOLY_POWER do
			local power = CreateFrame("StatusBar", nil, holyPowerBar)
			self:RegisterStatusBarTexture(power, SetHolyPowerColor)
			holyPowerBar[index] = power
		end
		return holyPowerBar
	end

end

local function Power_PostUpdate(power, unit, min, max)
	if power.disconnected or UnitIsDeadOrGhost(unit) then
		power:SetValue(0)
	end
end

local function AltPowerBar_PostUpdate(bar, min, cur, max)
	local unit = bar.__owner.unit
	if not unit then return end
	bar.Label:SetText(select(10, UnitAlternatePowerInfo(unit)))
	local _, powerRed, powerGreen, powerBlue = UnitAlternatePowerTextureInfo(unit, 2)
	local r, g, b = oUF.ColorGradient((cur-min)/(max-min), powerRed, powerGreen, powerBlue, 1, 0, 0)
	local c = bar.textureColor
	if c[1] ~= r or c[2] ~= g or c[3] ~= b then
		c[1], c[2], c[3] = r, g, b
		bar:SetStatusBarColor(r, g, b)
	end
end

-- Additional auxiliary bars
local function LayoutAuxiliaryBars(self)
	local bars = self.AuxiliaryBars
	local anchor = self
	for i, bar in ipairs(self.AuxiliaryBars) do
		if bar:IsShown() then
			bar:SetPoint("TOP", anchor, "BOTTOM", 0, -FRAME_MARGIN)
			anchor = bar
		end
	end
end

local function LayoutAuxiliaryBars_Hook(bar)
	 return LayoutAuxiliaryBars(bar.__mainFrame)
end

local function AddAuxiliaryBar(self, bar)
	if not self.AuxiliaryBars then
		self.AuxiliaryBars = {}
	end
	tinsert(self.AuxiliaryBars, bar)
	bar.__mainFrame = self
	bar:HookScript('OnShow', LayoutAuxiliaryBars_Hook)
	bar:HookScript('OnHide', LayoutAuxiliaryBars_Hook)
end

-- General bar layuot
local function LayoutBars(self, width, height)
	if width == 0 or height == 0 then return end
	self.Border:SetWidth(width + 2 * BORDER_WIDTH)
	self.Border:SetHeight(height + 2 * BORDER_WIDTH)
	local portrait = self.Portrait
	if portrait then
		portrait:SetWidth(height)
		portrait:SetHeight(height)
	end
	if self.Power then
		local totalPowerHeihgt = height * 0.45 - GAP
		local powerHeight
		if self.AltPower and self.AltPower:IsShown() then
			powerHeight = (totalPowerHeihgt - GAP) / 2
			self.AltPower:SetHeight(powerHeight)
		else
			powerHeight = totalPowerHeihgt
		end
		self.Power:SetHeight(powerHeight)
		height = height - totalPowerHeihgt - GAP
	end
	self.Health:SetHeight(height)
	if self.AuxiliaryBars then
		LayoutAuxiliaryBars(self)
	end
end

do
	local function Update(self, event, name)
		if event == "CVAR_UPDATE" and name ~= "SHOW_TARGET_CASTBAR" then return end
		local enabled = not not GetCVarBool("showTargetCastbar")
		if enabled == self.Castbar.enabled then return end
		self.Castbar.enabled = enabled
		self:Debug('UpdateCastbarDisplay', enabled, event, name)
		if enabled then
			self:EnableElement('Castbar')
		else
			self:DisableElement('Castbar')
			self.Castbar:Hide()
		end
	end

	local function Enable(self)
		if self.Castbar and self.OptionalCastbar then
			self.Castbar.enabled = true
			self:RegisterEvent('CVAR_UPDATE', Update)
			return true
		end
	end

	local function Disable(self)
		if self.Castbar and self.OptionalCastbar then
			self:UnregisterEvent('CVAR_UPDATE', Update)
		end
	end

	oUF:AddElement('OptionalCastbar', Update, Enable, Disable)
end

-- Based on Xinhuan unit dropdown hack
local function AdjustMenu(listFrame, point, relativeTo, relativePoint, xOffset, yOffset)
	local x, y = listFrame:GetCenter()
	local reposition
	if (y - listFrame:GetHeight()/2) < 0 then
		point = gsub(point, "TOP(.*)", "BOTTOM%1")
		relativePoint = gsub(relativePoint, "BOTTOM(.*)", "TOP%1")
		reposition = true
	end
	if listFrame:GetRight() > GetScreenWidth() then
		point = gsub(point, "(.*)LEFT", "%1RIGHT")
		relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT")
		reposition = true
	end
	if reposition then
		listFrame:ClearAllPoints()
		listFrame:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	end
end

local function DropDown_PostClick(self)
	if UIDROPDOWNMENU_OPEN_MENU == self.dropdownFrame and DropDownList1:IsShown() then
		DropDownList1:ClearAllPoints()
		DropDownList1:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0)
		AdjustMenu(DropDownList1, "TOPLEFT", self, "BOTTOMLEFT", 0, 0)
	end
end

local DROPDOWN_FRAMES = {
	player = "PlayerFrame",
	pet = "PetFrame",
	target = "TargetFrame",
	focus = "FocusFrame",
	boss = "Boss1TargetFrame",
}

local DRAGON_TEXTURES = {
	rare  = { [[Interface\Addons\oUF_Adirelle\media\rare_graphic]],  6/128, 123/128, 17/128, 112/128, },
	elite = { [[Interface\Addons\oUF_Adirelle\media\elite_graphic]], 6/128, 123/128, 17/128, 112/128, },
}

local function OoC_UnitFrame_OnEnter(...)
	if not InCombatLockdown() then return UnitFrame_OnEnter(...) end
end

local function InitFrame(settings, self, unit)
	local unit = gsub(unit or self.unit, "%d+", "")

	self:SetSize(settings['initial-width'], settings['initial-height'])

	self:RegisterForClicks("AnyDown")

	self:SetScript("OnEnter", OoC_UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	if self:CanChangeAttribute() then
		self:SetAttribute("type", "target")
	end

	local dropdownButton = DROPDOWN_FRAMES[unit]
	if dropdownButton then
		-- Hacky workaround
		if self:CanChangeAttribute() then
			self:SetAttribute("*type2", "click")
			self:SetAttribute("*clickbutton2", _G[dropdownButton])
		end
		self.dropdownFrame = _G[dropdownButton.."DropDown"]
		self:HookScript("PostClick", DropDown_PostClick)

		-- In case some addon overrides our right-click binding
		local menu = _G[dropdownButton].menu
		if menu then
			self.menu = function(...)
				print("|cff33ff99oUF_Adirelle:|r |cffff0000some third-party addon (Clique ?) overrides the right-click binding. Some of the menu options may fail. Remove that binding or disable the addon to fix this.|r")
				return menu(...)
			end
		end
	end

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,backdrop.bgAlpha)
	self:SetBackdropBorderColor(0,0,0,0)

	-- Border
	local border = CreateFrame("Frame", nil, self)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER", self)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border.blackByDefault = true
	border.noTarget = true
	self.Border = border

	local barContainer
	local left, right, dir = "LEFT", "RIGHT", 1
	if settings.mirroredFrame then
		left, right, dir = "RIGHT", "LEFT", -1
	end

	-- Portrait
	if not settings.noPortrait then
		-- Spawn the player model
		local portrait = CreateFrame("PlayerModel", nil, self)
		portrait:SetPoint(left)
		self.Portrait = portrait

		-- Create an icon displaying important debuffs (either PvP or PvE) all over the portrait
		local importantDebuff = self:SpawnAuraIcon(portrait)
		importantDebuff:SetAllPoints(portrait)
		local stack = importantDebuff.Stack
		stack:ClearAllPoints()
		stack:SetPoint("BOTTOMRIGHT", importantDebuff, -1, 1)
		importantDebuff.Stack:SetFont(GameFontNormal:GetFont(), 14, "OUTLINE")
		self.WarningIcon = importantDebuff

		-- Spawn a container frame that spans remaining space
		barContainer = CreateFrame("Frame", nil, self)
		barContainer:SetPoint("TOP"..left, portrait, "TOP"..right, GAP*dir, 0)
		barContainer:SetPoint("BOTTOM"..right)
	else
		barContainer = self
	end
	self.BarContainer = barContainer

	-- Dynamic bar layout
	local UpdateLayout = function()
		local width, height = self:GetWidth(), self:GetHeight()
		if width and height then
			return LayoutBars(self, width, height)
		end
	end

	-- Health bar
	local health = SpawnStatusBar(self, false, "TOPLEFT", barContainer)
	health:SetPoint("TOPRIGHT", barContainer)
	health.barSizePercent = 55
	health.colorTapping = true
	health.colorDisconnected = true
	health.colorHappiness = true
	health.colorClass = true
	health.colorSmooth = true
	health.frequentUpdates = true
	self.Health = health

	-- Name
	local name = SpawnText(health, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN)
	name:SetPoint("BOTTOMLEFT", health, "BOTTOMLEFT", TEXT_MARGIN)
	name:SetPoint("RIGHT", health.Text, "LEFT")
	self:Tag(name, (unit == "player" or unit == "pet" or unit == "boss") and "[name]" or "[name][ <>status<>]")
	self.Name = name

	if unit ~= "boss" then
		-- Low health indicator
		local lowHealth = self:CreateTexture(nil, "OVERLAY")
		lowHealth:SetPoint("TOPLEFT", self, -2, 2)
		lowHealth:SetPoint("BOTTOMRIGHT", self, 2, -2)
		lowHealth:SetTexture(1, 0, 0, 0.4)
		self.LowHealth = lowHealth

		-- Incoming heals
		local incomingHeal = health:CreateTexture(nil, "OVERLAY")
		incomingHeal:SetTexture([[Interface\AddOns\oUF_Adirelle\media\white16x16]])
		incomingHeal:SetVertexColor(0, 1, 0, 0.5)
		incomingHeal:SetBlendMode("ADD")
		incomingHeal:SetPoint("TOP", health)
		incomingHeal:SetPoint("BOTTOM", health)
		incomingHeal.PostUpdate = IncomingHeal_PostUpdate
		incomingHeal.current, incomingHeal.max, incomingHeal.incoming = 0, 0, 0
		self.IncomingHeal = incomingHeal

		health.PostUpdate = Health_PostUpdate
	end

	-- Used for some overlays
	local indicators = CreateFrame("Frame", nil, self)
	indicators:SetAllPoints(self)
	indicators:SetFrameLevel(health:GetFrameLevel()+3)
	self.Indicators = indicators

	-- Power bar
	if not settings.noPower then
		local power = SpawnStatusBar(self, false, "TOPLEFT", health, "BOTTOMLEFT", 0, -GAP)
		power:SetPoint('RIGHT', barContainer)
		power.colorDisconnected = true
		power.colorPower = true
		power.frequentUpdates = true
		power.PostUpdate = Power_PostUpdate
		self.Power = power

		if unit == "player" and SetupAltPower then
			local altPower = SetupAltPower(self)
			if altPower then
				altPower:SetPoint('TOPLEFT', power, 'BOTTOMLEFT', 0, -GAP)
				altPower:SetPoint('RIGHT', barContainer)
				altPower:HookScript('OnShow', UpdateLayout)
				altPower:HookScript('OnHide', UpdateLayout)
				self.AltPower = altPower
			end
		end

		-- Unit level and class (or creature family)
		if unit ~= "player" and unit ~= "pet" then
			local classif = SpawnText(power, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
			classif:SetPoint("BOTTOMLEFT", power)
			classif:SetPoint("RIGHT", power.Text, "LEFT")
			self:Tag(classif, "[smartlevel][ >smartclass<]")
		end

		-- Casting Bar
		if unit ~= 'player' then
			local castbar = CreateFrame("StatusBar", nil, self)
			castbar:Hide()
			castbar:SetPoint('BOTTOMRIGHT', power)
			self:RegisterStatusBarTexture(castbar)
			self.Castbar = castbar

			castbar.PostCastStart = function()
				castbar:SetStatusBarColor(1.0, 0.7, 0.0)
			end
			castbar.PostChannelStart = function()
				castbar:SetStatusBarColor(0.0, 1.0, 0.0)
			end

			local icon = castbar:CreateTexture(nil, "ARTWORK")
			icon:SetPoint('TOPRIGHT', castbar, 'TOPLEFT', -GAP, 0)
			icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
			castbar.Icon = icon

			local spellText = SpawnText(castbar, "OVERLAY")
			spellText:SetPoint('TOPLEFT', castbar, 'TOPLEFT', TEXT_MARGIN, 0)
			spellText:SetPoint('BOTTOMRIGHT', castbar, 'BOTTOMRIGHT', -TEXT_MARGIN, 0)
			castbar.Text = spellText

			local UpdateSize = function()
				local height = castbar:GetHeight()
				if height and height ~= castbar.__height then
					castbar.__height = height
					castbar:SetPoint('TOPLEFT', power, 'TOPLEFT', GAP + height, 0)
					icon:SetWidth(height)
					icon:SetHeight(height)
				end
			end
			castbar:SetScript('OnSizeChanged', UpdateSize)
			castbar:SetScript('OnShow', function() power:Hide() UpdateSize() end)
			castbar:SetScript('OnHide', function() power:Show() end)
			UpdateSize()

			local ptFrame = CreateFrame("Frame", nil, self)
			ptFrame:SetAllPoints(power)
			ptFrame:SetFrameLevel(castbar:GetFrameLevel()+1)
			power.Text:SetParent(ptFrame)

			-- Enable the element depending on a CVar
			self.OptionalCastbar = true
		end
	end

	-- Threat Bar
	if unit == "target" then
		-- Add a simple threat bar on the target
		local threatBar = SpawnStatusBar(self, false)
		threatBar:SetBackdrop(backdrop)
		threatBar:SetBackdropColor(0,0,0,backdrop.bgAlpha)
		threatBar:SetBackdropBorderColor(0,0,0,1)
		threatBar:SetWidth(190*0.5)
		threatBar:SetHeight(14)
		threatBar:SetMinMaxValues(0, 100)
		threatBar.PostUpdate = function(self, event, unit, bar, isTanking, status, scaledPercent, rawPercent, threatValue)
			if not bar.Text then return end
			if threatValue then
				local value, unit = threatValue / 100, ""
				if value > 1000000 then
					value, unit = value / 1000000, "m"
				elseif value > 1000 then
					value, unit = value / 1000, "k"
				end
				bar.Text:SetFormattedText("%d%% (%.1f%s)", scaledPercent, value, unit)
				bar.Text:Show()
			else
				bar.Text:Hide()
			end
		end
		self.ThreatBar = threatBar
		AddAuxiliaryBar(self, threatBar)
	end

	-- Threat glow
	local threat = CreateFrame("Frame", nil, self)
	threat:SetAllPoints(self.Border)
	threat:SetBackdrop(glowBorderBackdrop)
	threat:SetBackdropColor(0,0,0,0)
	threat.SetVertexColor = threat.SetBackdropBorderColor
	threat:SetAlpha(glowBorderBackdrop.alpha)
	threat:SetFrameLevel(self:GetFrameLevel()+2)
	self.Threat = threat

	-- Raid target icon
	self.RaidIcon = SpawnTexture(indicators, 16)
	self.RaidIcon:SetPoint("CENTER", barContainer)

	if unit ~= "boss" then
		-- Various indicators
		self.Leader = SpawnTexture(indicators, 16, "TOP"..left)
		self.Assistant = SpawnTexture(indicators, 16, "TOP"..left)
		self.MasterLooter = SpawnTexture(indicators, 16, "TOP"..left, 16*dir)
		self.Combat = SpawnTexture(indicators, 16, "BOTTOM"..left)

		-- Assigned/guessed raid/party icons, if we have a portrait
		if self.Portrait then
			self.RoleIcon = SpawnTexture(indicators, 16)
			self.RoleIcon:SetPoint("CENTER", self.Portrait, "TOP"..right)
			self.RoleIcon.noRaidTarget = true
		end

		-- PvP flag
		if self.Portrait then
			local pvp = SpawnTexture(indicators, 12)
			pvp:SetTexCoord(0, 0.6, 0, 0.6)
			pvp:SetPoint("CENTER", self.Portrait, "BOTTOM"..right)
			self.PvP = pvp
		end
	end

	if unit == "pet" then
		-- Pet happiness
		self.Happiness = SpawnTexture(indicators, 16, "BOTTOMRIGHT")

	elseif unit == "player" then
		-- Player resting status
		self.Resting = SpawnTexture(indicators, 16, "BOTTOMLEFT")

	elseif unit == "target" then
		-- Combo points
		local DOT_SIZE = 10
		local cpoints = {}
		for i = 0, 4 do
			local cpoint = SpawnTexture(indicators, DOT_SIZE)
			cpoint:SetTexture([[Interface\AddOns\oUF_Adirelle\media\combo]])
			cpoint:SetTexCoord(3/16, 13/16, 5/16, 15/16)
			cpoint:SetPoint("LEFT", health, "BOTTOMLEFT", i*(DOT_SIZE+GAP), 0)
			cpoint:Hide()
			tinsert(cpoints, cpoint)
		end
		self.ComboPoints = cpoints
	end

	-- Auras
	local buffs, debuffs
	if unit == "pet" then
		buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, FRAME_MARGIN)
		buffs.initialAnchor = "BOTTOMLEFT"
		buffs['growth-x'] = "RIGHT"
		buffs['growth-y'] = "UP"

	elseif unit == "target" or unit == "focus" or unit == "boss" then
		buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOM"..right, self, "BOTTOM"..left, -FRAME_MARGIN*dir, 0)
		buffs.showType = true
		buffs.initialAnchor = "BOTTOM"..right
		buffs['growth-x'] = left
		buffs['growth-y'] = "UP"

		debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint("TOP"..right, self, "TOP"..left, -FRAME_MARGIN*dir, 0)
		debuffs.showType = true
		debuffs.initialAnchor = "TOP"..right
		debuffs['growth-x'] = left
		debuffs['growth-y'] = "DOWN"
	end

	if buffs then
		buffs.size = AURA_SIZE
		buffs.num = 12
		buffs:SetWidth(AURA_SIZE * 12)
		buffs:SetHeight(AURA_SIZE)
		buffs.CustomFilter = Buffs_CustomFilter
		buffs.SetPosition = Auras_SetPosition
		buffs.PostCreateIcon = Auras_PostCreateIcon
		self.Buffs = buffs
	end
	if debuffs then
		debuffs.size = AURA_SIZE
		debuffs.num = 12
		debuffs:SetWidth(AURA_SIZE * 12)
		debuffs:SetHeight(AURA_SIZE)
		debuffs.CustomFilter = Debuffs_CustomFilter
		debuffs.SetPosition = Auras_SetPosition
		debuffs.PostCreateIcon = Auras_PostCreateIcon
		self.Debuffs = debuffs
	end

	-- Classification dragon
	if unit == "target" or unit == "focus" or unit == "boss" then
		local dragon = indicators:CreateTexture(nil, "ARTWORK")
		local DRAGON_HEIGHT = 45*95/80+2
		dragon:SetWidth(DRAGON_HEIGHT*117/95)
		dragon:SetHeight(DRAGON_HEIGHT)
		dragon:SetPoint('TOPLEFT', self, 'TOPLEFT', -44*DRAGON_HEIGHT/95-1, 15*DRAGON_HEIGHT/95+1)
		dragon.elite = DRAGON_TEXTURES.elite
		dragon.rare = DRAGON_TEXTURES.rare
		self.Dragon = dragon
	end

	-- Experience Bar for player
	if unit == "player" then
		local xpFrame = CreateFrame("Frame", nil, self)
		xpFrame:SetPoint("TOP")
		xpFrame:SetPoint("RIGHT")
		xpFrame:SetHeight(12)
		xpFrame:SetBackdrop(backdrop)
		xpFrame:SetBackdropColor(0,0,0,backdrop.bgAlpha)
		xpFrame:SetBackdropBorderColor(0,0,0,1)
		xpFrame:EnableMouse(false)

		local xpBar = SpawnStatusBar(self, true)
		xpBar:SetParent(xpFrame)
		xpBar:SetAllPoints(xpFrame)
		xpBar.Show = function() return xpFrame:Show() end
		xpBar.Hide = function() return xpFrame:Hide() end
		xpBar.IsShown = function() return xpFrame:IsShown() end
		xpBar:EnableMouse(false)
		xpBar.PostTextureUpdate = function() return self.ExperienceBar.ForceUpdate and self.ExperienceBar:ForceUpdate() end

		local restedBar = SpawnStatusBar(self, true)
		restedBar:SetParent(xpFrame)
		restedBar:SetAllPoints(xpFrame)
		restedBar:EnableMouse(false)
		restedBar.PostTextureUpdate = xpBar.PostTextureUpdate

		local levelText = SpawnText(xpBar, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
		levelText:SetPoint("BOTTOMLEFT", xpBar, "BOTTOMLEFT", TEXT_MARGIN, 0)

		local xpText = SpawnText(xpBar, "OVERLAY", "TOPRIGHT", "TOPRIGHT", -TEXT_MARGIN, 0)
		xpText:SetPoint("BOTTOMRIGHT", xpBar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)

		xpBar.UpdateText = function(self, bar, current, max, rested, level)
			levelText:SetFormattedText(level)
			if rested and rested > 0 then
				xpText:SetFormattedText("%s(+%s)/%s", smartValue(current), smartValue(rested), smartValue(max))
			else
				xpText:SetFormattedText("%s/%s", smartValue(current), smartValue(max))
			end
		end

		xpBar.Rested = restedBar
		xpBar:SetFrameLevel(restedBar:GetFrameLevel()+1)

		self.ExperienceBar = xpBar
		AddAuxiliaryBar(self, xpFrame)
	end

	-- Range fading
	self.XRange = true

	-- Special boss events
	if unit == "boss" then
		self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", self.UpdateAllElements)
		self:RegisterEvent("UNIT_TARGETABLE_CHANGED", function(_, event, unit)
			if unit == self.unit then return self:UpdateAllElements()	end
		end)
	end

	-- Altenate power bar (e.g. sound on Atramedes, or poison on Isorath)
	if unit == "player" or unit == "target" then

		local altPowerBar = SpawnStatusBar(self)
		altPowerBar:SetBackdrop(backdrop)
		altPowerBar:SetBackdropColor(0,0,0,backdrop.bgAlpha)
		altPowerBar:SetBackdropBorderColor(0,0,0,1)
		altPowerBar:SetPoint("LEFT")
		altPowerBar:SetPoint("RIGHT")
		altPowerBar:SetHeight(12)
		altPowerBar.showOthersAnyway = true
		altPowerBar.textureColor = { 1, 1, 1, 1 }
		altPowerBar.PostUpdate = AltPowerBar_PostUpdate

		local label = SpawnText(altPowerBar, "OVERLAY", "TOPLEFT", "TOPLEFT", TEXT_MARGIN, 0)
		label:SetPoint("RIGHT", altPowerBar.Text, "LEFT", -TEXT_MARGIN, 0)
		altPowerBar.Label = label

		self.AltPowerBar = altPowerBar
		AddAuxiliaryBar(self, altPowerBar)
	end

	-- Update layout at least once
	self:HookScript('OnSizeChanged', UpdateLayout)
	UpdateLayout()
end

local single_style = setmetatable({
	["initial-width"] = 190,
	["initial-height"] = 47,
}, {
	__call = InitFrame,
})

oUF:RegisterStyle("Adirelle_Single", single_style)

local single_style_right = setmetatable({
	mirroredFrame = true
}, {
	__call = InitFrame,
	__index = single_style,
})

oUF:RegisterStyle("Adirelle_Single_Right", single_style_right)

local single_style_health = setmetatable({
	["initial-height"] = 20,
	noPower = true,
	noPortrait = true
}, {
	__call = InitFrame,
	__index = single_style,
})

oUF:RegisterStyle("Adirelle_Single_Health", single_style_health)

--[=[
Adirelle's oUF layout
(c) 2009-2016 Adirelle (adirelle@gmail.com)

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

local _G = _G
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local CreateFrame = _G.CreateFrame
local unpack = _G.unpack
--GLOBALS>

local backdrop = oUF_Adirelle.backdrop
local CreateName = oUF_Adirelle.CreateName
local GAP = oUF_Adirelle.GAP
local GetSerialName = oUF_Adirelle.GetSerialName
local TEXT_MARGIN = oUF_Adirelle.TEXT_MARGIN
local CanDispel = oUF_Adirelle.CanDispel
local IsEncounterDebuff = oUF_Adirelle.IsEncounterDebuff

local LPS = oUF_Adirelle.GetLib("LibPlayerSpells-1.0")
local IsCrowdControl = LPS:GetSpellTester("DISORIENT INCAPACITATE ROOT STUN", "CROWD_CTRL", "TAUNT")

local MM_AFFIXES = { -- Shadowlands S1
	178658, -- Enrage
	209858, -- Necrotic Wound
	209859, -- Bolster
	226510, -- Sanguine Ichor (healing mobs)
	226512, -- Sanguine Ichor (hurting players)
	240443, -- Burst
	240447, -- Quake
	240559, -- Grievous Wound
	343502, -- Inspiring Presence
}

local BORDER_WIDTH = 1
local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]],
	edgeSize = BORDER_WIDTH,
}

local colors = oUF.colors.castbar
local function SetCastBarColor(castbar)
	local color = "failed"
	if castbar.notInterruptible then
		color = "notInterruptible"
	elseif castbar.channeling then
		color = "channeling"
	elseif castbar.casting then
		color = "casting"
	end
	return castbar:SetStatusBarColor(unpack(colors[color]))
end

local function Auras_PostCreateIcon(_, button)
	button.cd:SetReverse(true)
end

local function Auras_CustomFilter(_, unit, button, _, _, _, debuffType, _, _, _, isStealable, _, spellID, _, isBossDebuff) -- luacheck: no max line length
	return isBossDebuff
		or isStealable
		or CanDispel(unit, not button.isDebuff, debuffType)
		or IsEncounterDebuff(spellID)
		or IsCrowdControl(spellID)
		or MM_AFFIXES[spellID or 0]
end

local function InitFrame(self)
	local WIDTH, HEIGHT = 120, 16
	local CASTBAR_SIZE = 12
	local SYMBOL_SIZE = 20

	self:SetSize(WIDTH, HEIGHT)
	self:SetPoint("BOTTOM")

	local backdropFrame = CreateFrame("Frame", nil, self, "BackdropTemplate")
	backdropFrame:SetFrameLevel(self:GetFrameLevel() - 1)
	backdropFrame:SetAllPoints()
	backdropFrame:SetBackdrop(backdrop)
	backdropFrame:SetBackdropColor(0, 0, 0, backdrop.bgAlpha)
	backdropFrame:SetBackdropBorderColor(0, 0, 0, 0)

	-- Border
	local border = CreateFrame("Frame", CreateName(self, "Border"), self, "BackdropTemplate")
	border:SetPoint("TOPLEFT", -BORDER_WIDTH, BORDER_WIDTH)
	border:SetPoint("BOTTOMRIGHT", BORDER_WIDTH, -BORDER_WIDTH)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER", self)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border.blackByDefault = true
	self.Border = border

	-- 2d portrait
	local portrait = self:CreateTexture(nil, "ARTWORK")
	portrait:SetSize(HEIGHT, HEIGHT)
	portrait:SetPoint("LEFT")
	self.Portrait = portrait

	-- Health bar
	local health = self:SpawnStatusBar("health", true)
	health:SetPoint("TOPLEFT", portrait, "TOPRIGHT")
	health:SetPoint("BOTTOMRIGHT")
	health.frequentUpdates = true
	health.colorTapping = true
	health.colorClass = true
	health.colorSelection = true
	health.colorHealth = true
	health.considerSelectionInCombatHostile = true
	self.Health = health

	-- Name
	local name = self:SpawnText(health, "ARTWORK", nil, nil, nil, nil, "nameplate")
	name:SetPoint("TOPLEFT", TEXT_MARGIN, 0)
	name:SetPoint("BOTTOMRIGHT", -TEXT_MARGIN, 0)
	name:SetJustifyH("CENTER")
	self:Tag(name, "[name]")
	self.Name = name

	-- Indicator overlays
	local overlay = CreateFrame("Frame", nil, self)
	overlay:SetAllPoints(self)
	overlay:SetFrameLevel(border:GetFrameLevel() + 10)

	-- Range fading
	local xrange = overlay:CreateTexture(nil, "BACKGROUND")
	xrange:SetAllPoints(self)
	xrange:SetBlendMode("MOD")
	self.XRange = xrange

	-- Display auras of interest on top of the nameplate
	local auras = CreateFrame("Frame", nil, self)
	auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", GAP, GAP)
	auras:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -GAP, GAP)
	auras:SetHeight(CASTBAR_SIZE)
	auras.disableMouse = true
	auras.size = 20
	auras.spacing = 1
	auras.numTotal = 5
	auras.showType = true
	auras.showStealableBuffs = true
	auras.CustomFilter = Auras_CustomFilter
	auras.PostCreateIcon = Auras_PostCreateIcon
	self.Auras = auras

	-- Elite/rare classification
	local dragon = overlay:CreateTexture(CreateName(self, "Dragon"), "OVERLAY")
	dragon:SetSize(SYMBOL_SIZE / 2, SYMBOL_SIZE / 2)
	dragon:SetPoint("CENTER", self, "TOPLEFT")
	dragon.rare = [[Interface\Addons\oUF_Adirelle\media\rare_icon]]
	dragon.elite = [[Interface\Addons\oUF_Adirelle\media\elite_icon]]
	self.Dragon = dragon

	-- Casting bar
	local castbar = CreateFrame("StatusBar", CreateName(self, "CastBar"), self)
	castbar:Hide()
	castbar.__owner = self
	castbar:SetHeight(CASTBAR_SIZE)
	castbar:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -GAP, -GAP)
	castbar.hideTradeSkills = true
	castbar.PostCastStart = SetCastBarColor
	castbar.CastInterruptible = SetCastBarColor
	castbar.PostCastFail = SetCastBarColor
	castbar.timeToHold = 0.5
	self:RegisterStatusBarTexture(castbar, "castbar")
	self.Castbar = castbar

	local icon = castbar:CreateTexture(CreateName(castbar, "Icon"), "ARTWORK")
	icon:SetSize(CASTBAR_SIZE, CASTBAR_SIZE)
	icon:SetPoint("TOPLEFT", self, "BOTTOMLEFT", GAP, -GAP)
	icon:SetTexCoord(4 / 64, 60 / 64, 4 / 64, 60 / 64)
	castbar.Icon = icon
	castbar:SetPoint("LEFT", icon, "RIGHT")

	local spellText = self:SpawnText(castbar, "OVERLAY", nil, nil, nil, nil, "castbar")
	spellText:SetPoint("TOPLEFT", castbar, "TOPLEFT", TEXT_MARGIN, 0)
	spellText:SetPoint("BOTTOMRIGHT", castbar, "BOTTOMRIGHT", -TEXT_MARGIN, 0)
	castbar.Text = spellText

	local bg = castbar:CreateTexture(CreateName(castbar, "Background"), "BACKGROUND")
	bg:SetColorTexture(0, 0, 0, 1)
	bg:SetPoint("TOPLEFT", icon)
	bg:SetPoint("BOTTOMRIGHT", castbar)

	-- Raid target icon
	local raidTargetIcon = overlay:CreateTexture(GetSerialName(self, "RaidTarget"), "OVERLAY")
	raidTargetIcon:SetSize(SYMBOL_SIZE, SYMBOL_SIZE)
	raidTargetIcon:SetPoint("LEFT", self, "RIGHT", GAP, 0)
	self.RaidTargetIndicator = raidTargetIcon

	-- Threat glow
	local threat = overlay:CreateTexture(GetSerialName(self, "ThreatGlow"), "BACKGROUND")
	threat:SetPoint("TOPLEFT", border, -32, 16)
	threat:SetPoint("BOTTOMRIGHT", border, 32, -16)
	threat:SetTexture([[Interface\Addons\oUF_Adirelle\media\threat_overlay]])
	threat:SetTexCoord(85 / 512, (512 - 85) / 512, 0, 1)
	threat:SetVertexColor(1.0, 0.0, 0.0, 0.7)
	self.SmartThreat = threat
end

oUF:RegisterStyle("Adirelle_Nameplate", InitFrame)

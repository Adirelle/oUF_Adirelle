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

local _G, moduleName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local CreateFrame = _G.CreateFrame
--GLOBALS>
local mmin, mmax = _G.min, _G.max

local backdrop = oUF_Adirelle.backdrop
local CreateName = oUF_Adirelle.CreateName
local GAP = oUF_Adirelle.GAP
local GetSerialName = oUF_Adirelle.GetSerialName
local glowBorderBackdrop = oUF_Adirelle.glowBorderBackdrop
local SpawnStatusBar = oUF_Adirelle.SpawnStatusBar
local SpawnText = oUF_Adirelle.SpawnText
local SpawnTexture = oUF_Adirelle.SpawnTexture
local TEXT_MARGIN = oUF_Adirelle.TEXT_MARGIN

local BORDER_WIDTH = 1
local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\media\white16x16]],
	edgeSize = BORDER_WIDTH
}

local function SetCastBarColor(castbar)
	local r, g, b = 0.7, 0, 0
	if castbar.notInterruptible then
		r, g, b = 0.7, 0.7, 0.7
	elseif castbar.channeling then
		r, g, b = 0.0, 0.7, 1.0
	elseif castbar.casting then
		r, g, b = 1.0, 0.7, 0.0
	end
	return castbar:SetStatusBarColor(r, g, b)
end

local function InitFrame(self, unit)
	local WIDTH, HEIGHT = 120, 16
	local CASTBAR_SIZE = 12
	local SYMBOL_SIZE = 20

	self:SetSize(WIDTH, HEIGHT)
	self:SetPoint("BOTTOM")

	local backdropFrame = CreateFrame("Frame", nil, self, "BackdropTemplate")
	backdropFrame:SetFrameLevel(self:GetFrameLevel()-1)
	backdropFrame:SetAllPoints()
	backdropFrame:SetBackdrop(backdrop)
	backdropFrame:SetBackdropColor(0,0,0,backdrop.bgAlpha)
	backdropFrame:SetBackdropBorderColor(0,0,0,0)

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

	-- Health bar
	local health = SpawnStatusBar(self, true)
	health:SetAllPoints()
	health.frequentUpdates = true
	health.colorTapping = true
	health.colorClass = true
	health.colorSelection = true
	health.colorHealth = true
	health.considerSelectionInCombatHostile = true
	self.Health = health

	-- Name
	local name = SpawnText(self, health, nil, nil, nil, nil, nil, "text")
	name:SetPoint("TOPLEFT", TEXT_MARGIN, 0)
	name:SetPoint("BOTTOMRIGHT", -TEXT_MARGIN, 0)
	name:SetJustifyH("CENTER")
	self:Tag(name, "[name]")
	self.Name = name

	-- Create an icon displaying important debuffs
	local importantDebuff = self:CreateIcon(health, HEIGHT * 1.4)
	importantDebuff.minPriority = 50
	importantDebuff:SetPoint("CENTER", self)
	self.WarningIcon = importantDebuff

	-- Elite/rare classification
	local dragon = health:CreateTexture(CreateName(self, "Dragon"), "OVERLAY")
	dragon:SetSize(SYMBOL_SIZE / 2, SYMBOL_SIZE / 2)
	dragon:SetPoint("LEFT", self, "TOPLEFT")
	dragon.rare = [[Interface\Addons\oUF_Adirelle\media\rare_icon]]
	dragon.elite = [[Interface\Addons\oUF_Adirelle\media\elite_icon]]
	self.Dragon = dragon

	-- Casting bar
	local castbar = CreateFrame("StatusBar", CreateName(self, "CastBar"), self)
	castbar:Hide()
	castbar.__owner = self
	castbar:SetHeight(CASTBAR_SIZE)
	castbar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', -GAP, -GAP)
	castbar.hideTradeSkills = true
	castbar.PostCastStart = SetCastBarColor
	castbar.CastInterruptible = SetCastBarColor
	castbar.PostCastFail = SetCastBarColor
	castbar.timeToHold = 0.5
	self:RegisterStatusBarTexture(castbar)
	self.Castbar = castbar

	local icon = castbar:CreateTexture(CreateName(castbar, "Icon"), "ARTWORK")
	icon:SetSize(CASTBAR_SIZE, CASTBAR_SIZE)
	icon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', GAP, -GAP)
	icon:SetTexCoord(4/64, 60/64, 4/64, 60/64)
	castbar.Icon = icon
	castbar:SetPoint("LEFT", icon, "RIGHT")

	local spellText = SpawnText(self, castbar, "OVERLAY", nil, nil, nil, nil, "text")
	spellText:SetPoint('TOPLEFT', castbar, 'TOPLEFT', TEXT_MARGIN, 0)
	spellText:SetPoint('BOTTOMRIGHT', castbar, 'BOTTOMRIGHT', -TEXT_MARGIN, 0)
	castbar.Text = spellText

	local bg = castbar:CreateTexture(CreateName(castbar, "Background"), "BACKGROUND")
	bg:SetColorTexture(0,0,0,1)
	bg:SetPoint('TOPLEFT', icon)
	bg:SetPoint('BOTTOMRIGHT', castbar)

	-- Raid target icon
	local raidTargetIcon = self:CreateTexture(GetSerialName(self, "RaidTarget"), "OVERLAY")
	raidTargetIcon:SetSize(SYMBOL_SIZE, SYMBOL_SIZE)
	raidTargetIcon:SetPoint("LEFT", self, "RIGHT", GAP, 0)
	self.RaidTargetIndicator = raidTargetIcon

	-- Threat glow
	local threat = self:CreateTexture(GetSerialName(self, "ThreatGlow"), "BACKGROUND")
	threat:SetPoint("TOPLEFT", border, -32, 16)
	threat:SetPoint("BOTTOMRIGHT", border, 32, -16)
	threat:SetTexture([[Interface\Addons\oUF_Adirelle\media\threat_overlay]])
	threat:SetTexCoord(85/512, (512-85)/512, 0, 1)
	threat:SetVertexColor(1.0, 0.0, 0.0, 0.7)
	self.SmartThreat = threat
end

oUF:RegisterStyle("Adirelle_Nameplate", InitFrame)

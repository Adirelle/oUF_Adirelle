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

local function InitFrame(self, unit)
	local width, height = 100, 16

	self:SetSize(width, height)
	self:SetPoint("BOTTOM", 0, 0)

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

	-- Create an icon displaying important debuffs
	local importantDebuff = self:CreateIcon(self, height * 1.3)
	importantDebuff.minPriority = 20
	importantDebuff:SetPoint("RIGHT", self, "LEFT", -GAP, 0)
	self.WarningIcon = importantDebuff

	local stack = importantDebuff.Stack
	stack:ClearAllPoints()
	stack:SetPoint("BOTTOMRIGHT", importantDebuff, -1, 1)
	self:RegisterFontString(importantDebuff.Stack, "number", 14, "OUTLINE")

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
	name:SetAllPoints()
	name:SetJustifyH("CENTER")
	self:Tag(name, "[name]")
	self.Name = name

	-- Casting bar
	local castbar = CreateFrame("StatusBar", CreateName(self, "CastBar"), self)
	castbar:Hide()
	castbar.__owner = self
	castbar:SetHeight(height)
	castbar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, -GAP)
	castbar.PostCastStart = function() castbar:SetStatusBarColor(1.0, 0.7, 0.0) end
	castbar.PostChannelStart = function() castbar:SetStatusBarColor(0.0, 1.0, 0.0) end
	self:RegisterStatusBarTexture(castbar)
	self.Castbar = castbar

	local icon = castbar:CreateTexture(CreateName(castbar, "Icon"), "ARTWORK")
	icon:SetSize(height, height)
	icon:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -GAP)
	icon:SetTexCoord(4/64, 60/64, 4/64, 60/64)
	castbar.Icon = icon

	local spellText = SpawnText(self, castbar, "OVERLAY", nil, nil, nil, nil, "text")
	spellText:SetPoint('TOPLEFT', castbar, 'TOPLEFT', TEXT_MARGIN, 0)
	spellText:SetPoint('BOTTOMRIGHT', castbar, 'BOTTOMRIGHT', -TEXT_MARGIN, 0)
	castbar.Text = spellText

	local bg = castbar:CreateTexture(CreateName(castbar, "Background"), "BACKGROUND")
	bg:SetColorTexture(0,0,0,1)
	bg:SetPoint('TOPLEFT', icon)
	bg:SetPoint('BOTTOMRIGHT', castbar)

	castbar:SetPoint("TOPLEFT", icon, "TOPRIGHT", GAP, 0)

	-- Raid target icon
	local raidTargetIcon = self:CreateTexture(GetSerialName(self, "RaidTarget"), "OVERLAY")
	raidTargetIcon:SetSize(height * 1.2, height * 1.2)
	raidTargetIcon:SetPoint("LEFT", self, "RIGHT", GAP, 0)
	self.RaidTargetIndicator = raidTargetIcon

	-- Threat glow
	local threat = CreateFrame("Frame", CreateName(self, "ThreatGlow"), self, "BackdropTemplate")
	threat:SetPoint("TOPLEFT", border, -2, 2)
	threat:SetPoint("BOTTOMRIGHT", border, 2, -2)
	threat:SetBackdrop(glowBorderBackdrop)
	threat:SetBackdropColor(0,0,0,0)
	threat.SetVertexColor = threat.SetBackdropBorderColor
	self.SmartThreat = threat

	-- -- Classification dragon
	-- if not settings.noPortrait and (unit == "target" or unit == "focus" or unit == "boss") then
	-- 	local dragon = indicators:CreateTexture(CreateName(self, "Classification"), "ARTWORK")
	-- 	local DRAGON_HEIGHT = 45*95/80+2
	-- 	dragon:SetWidth(DRAGON_HEIGHT*117/95)
	-- 	dragon:SetHeight(DRAGON_HEIGHT)
	-- 	dragon:SetPoint('TOPLEFT', self, 'TOPLEFT', -44*DRAGON_HEIGHT/95-1, 15*DRAGON_HEIGHT/95+1)
	-- 	dragon.elite = DRAGON_TEXTURES.elite
	-- 	dragon.rare = DRAGON_TEXTURES.rare
	-- 	self.Dragon = dragon
	-- end
end

oUF:RegisterStyle("Adirelle_Nameplate", InitFrame)

--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local WIDTH = 80
local HEIGHT = 25
local BORDER_WIDTH = 1
local ICON_SIZE = 14
local SPACING = 2

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")
local lsm = LibStub('LibSharedMedia-3.0', true)

local statusbarTexture = lsm and lsm:Fetch("statusbar", false) or [[Interface\TargetingFrame\UI-StatusBar]]

local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 16,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local borderBackdrop = {
	edgeFile = [[Interface\Addons\oUF_Adirelle\white16x16]], 
	edgeSize = BORDER_WIDTH,	insets = {left = BORDER_WIDTH, right = BORDER_WIDTH, top = BORDER_WIDTH, bottom = BORDER_WIDTH},
}

local UnitClass, UnitIsConnected = UnitClass, UnitIsConnected
local UnitIsDeadOrGhost, UnitName = UnitIsDeadOrGhost, UnitName
local strformat = string.format
local mmin = math.min

-- ------------------------------------------------------------------------------
-- LibHealComm-3.0 support
-- ------------------------------------------------------------------------------
local lbh = LibStub('LibHealComm-3.0', true)

local GetPlayerHealer
if lbh then
	local playerName = UnitName('player')
	local playerHeals = {}
	
	local function UpdateHeals(event, healer, amount, ...)
		for i = 1, select('#', ...) do
			local target = select(i, ...)
			if healer == playerName then
				playerHeals[target] = amount and ((playerHeals[target] or 0) + amount) or nil
			end
			for k, frame in pairs(oUF.objects) do
				local health = frame.Health
				if health and frame.unit and UnitName(frame.unit) == target then	
					if health.frequentUpdates then
						health.min = nil
					else
						frame:UNIT_MAXHEALTH(event, frame.unit)
					end
				end
			end
		end
	end
	
	lbh.RegisterCallback(playerHeals, 'HealComm_DirectHealStart', function(event, healer, amount, _, ...)
		return UpdateHeals(event, healer, amount, ...)
	end)
	lbh.RegisterCallback(playerHeals, 'HealComm_DirectHealDelayed', function(event, healer, _, ...)
		return UpdateHeals(event, healer, 0, ...)
	end)		
	lbh.RegisterCallback(playerHeals, 'HealComm_DirectHealStop', function(event, healer, _, ...)
		return UpdateHeals(event, healer, nil, ...)
	end)		
	lbh.RegisterCallback(playerHeals, 'HealComm_HealModifierUpdate', function(event, unit)
		local frame = oUF.units[unit] 
		if frame and frame.Health and frame.Health.heal then
			frame:UNIT_MAXHEALTH(event, unit)
		end
	end)
	
	function GetPlayerHealer(unit)
		return playerHeals[UnitName(unit) or false] or 0
	end
end

-- ------------------------------------------------------------------------------
-- Health bar and name updates
-- ------------------------------------------------------------------------------

local function UpdateHealth(self, event, unit, bar, current, max)
	local isDisconnected, isDead = not UnitIsConnected(unit), UnitIsDeadOrGhost(unit)
	if isDisconnected or isDead then
		bar:SetValue(max)
	end
	
	local r, g, b = 0.5, 0.5, 0.5
	local color = isDisconnected and self.colors.disconnected or self.colors.class[select(2, UnitClass(unit))]
	if color then
		r, g, b = unpack(color)
	end
	bar.bg:SetVertexColor(r, g, b, 1)

	local incomingHeal = 0	
	if lbh then
		incomingHeal = ((lbh:UnitIncomingHealGet(unit, GetTime() + 5) or 0) + GetPlayerHealer(unit)) * lbh:UnitHealModifierGet(unit)
	end
	local hpPercent = current/max
	if isDead then
		self.Name:SetText("MORT")
	elseif incomingHeal > 0 then
		self.Name:SetText(strformat("+%.1fk", incomingHeal/1000))
	elseif isDisconnected or hpPercent > 0.9  then
		self.Name:SetText(UnitName(unit))
	else
		self.Name:SetText(strformat("-%.1fk", (max-current)/1000))
	end
	if hpPercent < 0.4 then
		self.Name:SetTextColor(1,0,0)
	elseif incomingHeal > 0 then
		self.Name:SetTextColor(0,1,0)
	else
		self.Name:SetTextColor(r, g, b)
	end
	
	local heal = bar.heal
	if heal then
		if incomingHeal > 0 and current < max then
			local pixelPerHP = bar:GetWidth() / max		
			heal:SetPoint('LEFT', bar, 'LEFT', current * pixelPerHP, 0)
			heal:SetPoint('RIGHT', bar, 'LEFT', mmin(current + incomingHeal, max) * pixelPerHP, 0)
			heal:Show()
		else
			heal:Hide()
		end
	end
end

-- ------------------------------------------------------------------------------
-- Aura icons
-- ------------------------------------------------------------------------------

local function SpawnIcon(self, noCooldown, noStack, noBorder)
	local	icon = CreateFrame("Frame", nil, self)
	icon:SetWidth(ICON_SIZE)
	icon:SetHeight(ICON_SIZE)
	
	local texture = icon:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints(icon)
	texture:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	texture:SetTexture(1,1,1,0)	
	icon.Texture = texture	

	if not noCooldown then
		local cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
		cooldown:SetAllPoints(texture)
		cooldown:SetReverse(true)
		icon.Cooldown = cooldown
	end

	if not noStack then
		local stack = icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		stack:SetAllPoints(texture)
		stack:SetJustifyH("CENTER")
		stack:SetJustifyV("MIDDLE")
		stack:SetFont(GameFontNormal:GetFont(), 10, "OUTLINE")
		stack:SetTextColor(1, 1, 1, 1)
		icon.Stack = stack
	end
	
	if not noBorder then
		local border = CreateFrame("Frame", nil, icon)
		border:SetPoint("CENTER", icon)
		border:SetWidth(ICON_SIZE + 2 * BORDER_WIDTH)
		border:SetHeight(ICON_SIZE + 2 * BORDER_WIDTH)
		border:SetBackdrop(borderBackdrop)
		border:SetBackdropColor(0, 0, 0, 0)
		border:SetBackdropBorderColor(1, 1, 1, 1)
		border.SetColor = border.SetBackdropBorderColor
		border:Hide()
		icon.Border = border
	end

	icon:Hide()
	return icon
end

local function TestMyAura(spellId)
	local spellName = GetSpellInfo(spellId)
	assert(spellName, "invalid spell id: "..spellId)
	return function(unit)
		local name, _, texture, count, _, duration, expirationTime, caster = UnitAura(unit, spellName)
		if name and UnitIsUnit(caster, "player") then
			return texture, count, expirationTime-duration, duration
		end
	end
end

local function GetCureableDebuff(unit)
	local name, _, texture, count, debuffType, duration, expirationTime, caster = UnitAura(unit, 1, "HARMFUL|RAID")
	if name then
		local color = DebuffTypeColor[debuffType or "none"]
		return texture, count, expirationTime-duration, duration, color.r, color.g, color.b
	end
end

-- ------------------------------------------------------------------------------
-- Statusbar texturing
-- ------------------------------------------------------------------------------

local function UpdateTextures(self)
	local bar = self.Health
	bar:SetStatusBarTexture(statusbarTexture)
	bar:SetStatusBarColor(0, 0, 0, 0.75)
	bar.bg:SetTexture(statusbarTexture)
end

-- ------------------------------------------------------------------------------
-- Unit frame initialization
-- ------------------------------------------------------------------------------

local function InitFrame(settings, self, unit)
	self:EnableMouse(true)
	self:RegisterForClicks("anyup")
	
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	
	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(0, 0, 0, 1)
	
	-- Health bar
	local hp = CreateFrame("StatusBar", nil, self)
	hp:SetAllPoints(self)
	hp.frequentUpdates = true
		
	local hpbg = hp:CreateTexture(nil, "BACKGROUND")
	hpbg:SetAllPoints(hp)
	hpbg:SetAlpha(1)
	hp.bg = hpbg
	
	-- Incoming heals
	if lbh then
		local heal = hp:CreateTexture(nil, "OVERLAY")
		heal:SetTexture(0, 0.5, 0, 0.5)
		heal:SetBlendMode("BLEND")
		heal:SetPoint("LEFT")
		heal:SetPoint("TOP")
		heal:SetPoint("BOTTOM")
		heal:Hide()
		hp.heal = heal
	end

	self.Health = hp
	self.OverrideUpdateHealth = UpdateHealth

	UpdateTextures(self)
	
	if lsm then
		lsm.RegisterCallback(self, 'LibSharedMedia_SetGlobal', function(_, media, value)
			if media == "statusbar" then
				statusbarTexture = lsm:Fetch("statusbar", value)
				UpdateTextures(self)
			end
		end)
	end
	
	-- Name
	local name = hp:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	name:SetAllPoints(self)
	name:SetJustifyH("CENTER")
	name:SetJustifyV("MIDDLE")
	name:SetFont(GameFontNormal:GetFont(), 11)
	name:SetTextColor(1, 1, 1, 1)
	self.Name = name
	
	-- Border
	local border = CreateFrame("Frame", nil, self)
	border:SetFrameStrata("BACKGROUND")
	border:SetPoint("CENTER", self)
	border:SetWidth(WIDTH + 2 * BORDER_WIDTH)
	border:SetHeight(HEIGHT + 2 * BORDER_WIDTH)
	border:SetBackdrop(borderBackdrop)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(1, 1, 1, 1)
	border.SetColor = border.SetBackdropBorderColor
	border:Hide()	 
	self.Border = border
	
	-- ReadyCheck icon
	local rc = self:CreateTexture(nil, 'OVERLAY')
	rc:SetPoint('CENTER', self)
	rc:SetWidth(HEIGHT)
	rc:SetHeight(HEIGHT)
	rc:SetAlpha(1.0)
	rc:Hide()
	self.ReadyCheck = rc 
	
	-- Per-class aura icons
	local _, class = UnitClass("player")
	if class == "HUNTER" then
		local misdirection = SpawnIcon(self)
		misdirection:SetPoint("CENTER")
		self:AuraIcon(misdirection, TestMyAura(34477))
		
	elseif class == "DRUID" then
		local rejuv = SpawnIcon(self, false, false, true)
		rejuv:SetPoint("CENTER", self, "LEFT", WIDTH * 0.2, 0)
		self:AuraIcon(rejuv, TestMyAura(774))

		local regrowth = SpawnIcon(self, false, false, true)
		regrowth:SetPoint("CENTER", self, "LEFT", WIDTH * 0.4, 0)
		self:AuraIcon(regrowth, TestMyAura(8936))

		local lifebloom = SpawnIcon(self, false, false, true)
		lifebloom:SetPoint("CENTER", self, "LEFT", WIDTH * 0.6, 0)
		self:AuraIcon(lifebloom, TestMyAura(33763))
		
		local debuff = SpawnIcon(self)
		debuff:SetPoint("CENTER", self, "LEFT", WIDTH * 0.8, 0)
		self:AuraIcon(debuff, GetCureableDebuff)

	elseif class == 'SHAMAN' or class == 'PALADIN' or class == 'MAGE' or class == 'WARLOCK' or class == 'PRIEST' then
		local debuff = SpawnIcon(self)
		debuff:SetPoint("CENTER")
		self:AuraIcon(debuff, GetCureableDebuff)
	end
	self.iconBlinkThreshold = 3
	
	-- Range fading
	self.Range = true
	self.inRangeAlpha = 1.0
	self.outsideRangeAlpha = 0.25
end

-- ------------------------------------------------------------------------------
-- Style and layout setup
-- ------------------------------------------------------------------------------

local style = setmetatable(
	{
		["initial-width"] = WIDTH,
		["initial-height"] = HEIGHT,
	}, {
		__call = InitFrame,
	}
)
 
oUF:RegisterStyle("Adirelle", style)
oUF:SetActiveStyle("Adirelle")

-- Raid groups
local raid = {}
for group = 1, 8 do
	local header = oUF:Spawn("header", "oUF_Raid" .. group)
	header:SetManyAttributes(
		"showRaid", true,
		"groupFilter", group,
		"point", "LEFT",
		"xOffset", SPACING
	)
	if group > 1 then
		header:SetPoint("BOTTOMLEFT", raid[group - 1], "TOPLEFT", 0, SPACING)
	end
	header:Show()
	raid[group] = header
end

do
	-- Party pets
	local header = oUF:Spawn("header", "oUF_PartyPets", "SecureGroupPetHeaderTemplate")
	header:SetManyAttributes(
		"showParty", true,
		"showPlayer", true,
		"showSolo", true,
		"groupFilter", 1,
		"point", "LEFT",
		"xOffset", SPACING
	)
	header:SetPoint("BOTTOMLEFT", raid[1], "TOPLEFT", 0, SPACING)
	header:Show()
	raid['PartyPets'] = header
end

-- First raid group (or party)
raid[1]:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 230)
raid[1]:SetManyAttributes(
	"showParty", true,
	"showPlayer", true
)


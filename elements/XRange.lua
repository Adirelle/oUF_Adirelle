--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local UnitIsUnit = UnitIsUnit
local IsSpellInRange = IsSpellInRange
local UnitIsConnected = UnitIsConnected
local UnitCanAttack = UnitCanAttack
local UnitCanAssist = UnitCanAssist
local UnitInRange = UnitInRange
local UnitIsCorpse = UnitIsCorpse
local CheckInteractDistance = CheckInteractDistance
local GetSpellInfo = GetSpellInfo

local objects = {}
local updateFrame
local timer = 0

local friendlySpell, hostileSpell, petSpell, rezSpell

-- Based on list from ShadowedUnitFrames, thanks to Shadowed
local playerClass = select(2, UnitClass("player"))
if playerClass == 'PRIEST' then
	friendlySpell = GetSpellInfo(2050) -- Lesser Heal
	hostileSpell = GetSpellInfo(48127) -- Mind Blast
	rezSpell = GetSpellInfo(2006) -- Resurrection
	
elseif playerClass == 'DRUID' then
	friendlySpell = GetSpellInfo(48378) -- Healing Touch 
	hostileSpell = GetSpellInfo(48461) -- Wrath
	rezSpell = GetSpellInfo(20484) -- Rebirth
	
elseif playerClass == 'PALADIN' then
	friendlySpell = GetSpellInfo(48782) -- Holy Light
	hostileSpell = GetSpellInfo(62124) -- Hand of Reckoning
	rezSpell = GetSpellInfo(7328) -- Redemption
	
elseif playerClass == 'HUNTER' then
	hostileSpell = GetSpellInfo(75) -- Auto Shot
	petSpell = GetSpellInfo(53271) -- Master's Call
	
elseif playerClass == 'SHAMAN' then
	friendlySpell = GetSpellInfo(49273) -- Healing Wave
	hostileSpell = GetSpellInfo(529) -- Lightning Bolt
	rezSpell = GetSpellInfo(2008) -- Ancestral Spirit
	
elseif playerClass == 'WARLOCK' then
	hostileSpell = GetSpellInfo(686) -- Shadow Bolt
	friendlySpell = GetSpellInfo(132) -- (buff) Detect Invisibility
	
elseif playerClass == 'MAGE' then
	hostileSpell = GetSpellInfo(133) -- Fireball
	friendlySpell = GetSpellInfo(1459) -- (buff) Arcane Intellect
	
elseif playerClass == 'DEATHKNIGHT' then
	hostileSpell = GetSpellInfo(49576) -- Death grip
end

local function GetRangeSpell(unit)
	if UnitCanAssist('player', unit) then
		return (UnitIsCorpse(unit) and rezSpell) or (UnitIsUnit(unit, 'pet') and petSpell) or friendlySpell
	elseif UnitCanAttack('player', unit) then
		return hostileSpell
	end
end

local function GetRangeAlpha(self, unit)
	if UnitIsUnit(unit, 'player') or not UnitIsConnected(unit) then 
		return self.inRangeAlpha
	--	elseif not UnitIsVisible(unit) then
	--	return self.notVisibleAlpha
	end
	local spell =  GetRangeSpell(unit)
	local spellInRange = spell and IsSpellInRange(spell, unit)
	if spellInRange == 1 or (spellInRange == nil and (UnitInRange(unit) or CheckInteractDistance(unit, 4))) then
		return self.inRangeAlpha
	else
		return self.outsideRangeAlpha
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local alpha = GetRangeAlpha(self, unit)
	if alpha ~= self:GetAlpha() then
		self:SetAlpha(alpha)
	end
end

local function OnUpdate(self, elapsed)
	if timer > 0 then
		timer = timer - elapsed
	else
		timer = 0.25
		for frame in pairs(objects) do
			if frame:IsShown() then
				Update(frame, "OnUpdate", frame.unit)
			end
		end
		if not next(objects) then
			self:Hide()
		end
	end
end

local function Enable(self)
	if self.XRange and self.unit ~= 'player' then
		if not updateFrame then
			updateFrame = CreateFrame("Frame")
			updateFrame:SetScript('OnUpdate', OnUpdate)
		end
		updateFrame:Show()
		self.inRangeAlpha = self.inRangeAlpha or 1.0
		self.outsideRangeAlpha = self.outsideRangeAlpha or 0.4
		self.notVisibleAlpha = notVisibleAlpha or 0.2
		objects[self] = true
		return true
	end
end

local function Disable(self)
	objects[self] = nil
end

oUF:AddElement('XRange', Update, Enable, Disable)


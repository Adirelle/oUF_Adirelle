--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local objects = {}
local updateFrame
local timer = 0

local friendlySpell, hostileSpell, petSpell

-- Based on list from ShadowedUnitFrames, thanks to Shadowed
local playerClass = select(2, UnitClass("player"))
if playerClass == 'PRIEST' then
	friendlySpell = GetSpellInfo(2050) -- Lesser Heal
	hostileSpell = GetSpellInfo(48127) -- Mind Blast
	
elseif playerClass == 'DRUID' then
	friendlySpell = GetSpellInfo(48378) -- Healing Touch 
	hostileSpell = GetSpellInfo(48461) -- Wrath
	
elseif playerClass == 'PALADIN' then
	friendlySpell = GetSpellInfo(48782) -- Holy Light
	hostileSpell = GetSpellInfo(62124) -- Hand of Reckoning
	
elseif playerClass == 'HUNTER' then
	hostileSpell = GetSpellInfo(75) -- Auto Shot
	petSpell = GetSpellInfo(53271) -- Master's Call
	
elseif playerClass == 'SHAMAN' then
	friendlySpell = GetSpellInfo(49273) -- Healing Wave
	hostileSpell = GetSpellInfo(529) -- Lightning Bolt
	
elseif playerClass == 'WARLOCK' then
	hostileSpell = GetSpellInfo(686) -- Shadow Bolt
	friendlySpell = GetSpellInfo(132) -- (buff) Detect Invisibility
	
elseif playerClass == 'MAGE' then
	hostileSpell = GetSpellInfo(133) -- Fireball
	friendlySpell = GetSpellInfo(1459) -- (buff) Arcane Intellect
	
elseif playerClass == 'DEATHKNIGHT' then
	hostileSpell = GetSpellInfo(49576) -- Death grip
end

local UnitIsUnit = UnitIsUnit
local IsSpellInRange = IsSpellInRange
local UnitCanAttack = UnitCanAttack
local UnitCanAssist = UnitCanAssist
local UnitInRange = UnitInRange
local CheckInteractDistance = CheckInteractDistance

local function InRange(unit)
	if UnitIsUnit(unit, 'player') then return true end
	local spellInRange
	if petSpell and UnitIsUnit(unit, 'pet') then
		spellInRange = IsSpellInRange(petSpell, unit)	
	elseif hostileSpell and UnitCanAttack('player', unit) then
		spellInRange = IsSpellInRange(hostileSpell, unit)
	elseif friendlySpell and UnitCanAssist('player', unit) then
		spellInRange = IsSpellInRange(friendlySpell, unit)
	end
	if spellInRange ~= nil then
		return spellInRange == 1
	else
		return UnitInRange(unit) or CheckInteractDistance(unit, 4)
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	if UnitIsConnected(unit) and not InRange(unit) then
		if self:GetAlpha() == self.inRangeAlpha then
			self:SetAlpha(self.outsideRangeAlpha)
		end
	elseif self:GetAlpha() ~= self.inRangeAlpha then
		self:SetAlpha(self.inRangeAlpha)
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
		objects[self] = true
		return true
	end
end

local function Disable(self)
	objects[self] = nil
end

oUF:AddElement('XRange', Update, Enable, Disable)


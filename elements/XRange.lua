--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local UnitIsUnit = UnitIsUnit
local IsSpellInRange = IsSpellInRange
local UnitIsConnected = UnitIsConnected
local UnitCanAttack = UnitCanAttack
local UnitCanAssist = UnitCanAssist
local UnitInRange = UnitInRange
local UnitIsCorpse = UnitIsCorpse
local UnitIsVisible = UnitIsVisible
local CheckInteractDistance = CheckInteractDistance
local GetSpellInfo = GetSpellInfo

local objects = {}
local updateFrame
local timer = 0

local friendlySpell, hostileSpell, petSpell, rezSpell

local function DefaultRangeCheck(unit)
	return UnitInRange(unit) or CheckInteractDistance(unit, 4)
end

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
	petSpell = GetSpellInfo(136) -- Mend Pet

elseif playerClass == 'SHAMAN' then
	friendlySpell = GetSpellInfo(49273) -- Healing Wave
	hostileSpell = GetSpellInfo(529) -- Lightning Bolt
	rezSpell = GetSpellInfo(2008) -- Ancestral Spirit

elseif playerClass == 'WARLOCK' then
	local shadowBolt = GetSpellInfo(686) -- Shadow Bolt
	local corruption = GetSpellInfo(172) -- Corruption
	hostileSpell = function(unit)
		return IsSpellInRange(shadowBolt) == 1 or IsSpellInRange(corruption) == 1
	end
	friendlySpell = GetSpellInfo(132) -- (buff) Detect Invisibility

elseif playerClass == 'MAGE' then
	hostileSpell = GetSpellInfo(133) -- Fireball
	friendlySpell = GetSpellInfo(475) -- Remove Curse

elseif playerClass == 'DEATHKNIGHT' then
	hostileSpell = GetSpellInfo(49576) -- Death grip

elseif playerClass == 'ROGUE' then
	hostileSpell = GetSpellInfo(26679) -- Deadly Throw
	friendlySpell = GetSpellInfo(57934) -- Tricks of the Trade

elseif playerClass == 'WARRIOR' then
	local meleeAttack = GetSpellInfo(772) -- Rend
	local charge = GetSpellInfo(100) -- Charge
	local intervene = GetSpellInfo(3411)  -- Intervene
	hostileSpell = function(unit)
		local chargeRange = IsSpellInRange(charge, unit)
		local meleeRange = IsSpellInRange(meleeAttack, unit)
		if chargeRange == 1 or meleeRange == 1 then
			return true
		elseif chargeRange == 0 and meleeRange == 0 then
			return false
		else
			return DefaultRangeCheck(unit)
		end
	end
	friendlySpell = function(unit)
		local interveneRange = IsSpellInRange(intervene, unit)
		if interveneRange ~= nil then
			return interveneRange == 1
		else
			return CheckInteractDistance(unit, 2)
		end
	end
end

do
	local function WrapSpell(spell)
		if not spell or type(spell) == "function" then return spell end
		return function(unit)
			local inRange = IsSpellInRange(spell, unit)
			if inRange ~= nil then
				return inRange == 1
			else
				return DefaultRangeCheck(unit)
			end
		end
	end
	friendlySpell = WrapSpell(friendlySpell)
	hostileSpell = WrapSpell(hostileSpell)
	rezSpell = WrapSpell(rezSpell)
	petSpell = WrapSpell(petSpell)
end

local function IsInRange(unit)
	if UnitIsUnit(unit, 'player') or not UnitIsConnected(unit) then
		return true
	elseif not UnitIsVisible(unit) then
		return false
	elseif hostileSpell and UnitCanAttack('player', unit) then
		return hostileSpell(unit)
	elseif petSpell and UnitIsUnit(unit, 'pet') then
		return petSpell(unit)
	elseif rezSpell and UnitIsCorpse(unit) and UnitCanAssist('player', unit) then
		return rezSpell(unit)
	elseif friendlySpell and UnitCanAssist('player', unit) then
		return friendlySpell(unit)
	else
		return DefaultRangeCheck(unit)
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	local alpha = IsInRange(unit) and self.inRangeAlpha or self.outsideRangeAlpha
	if alpha ~= self:GetAlpha() then
		self:SetAlpha(alpha)
	end
end

local function OnUpdate(self, elapsed)
	if timer > 0 then
		timer = timer - elapsed
	else
		timer = 0.25
		for frame in next, objects do
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


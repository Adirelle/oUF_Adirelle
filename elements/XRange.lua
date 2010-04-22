--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local function BuildRangeCheck()
	local UnitIsUnit = UnitIsUnit
	local IsSpellInRange = IsSpellInRange
	local UnitIsConnected = UnitIsConnected
	local UnitCanAttack = UnitCanAttack
	local UnitCanAssist = UnitCanAssist
	local UnitIsCorpse = UnitIsCorpse
	local UnitIsVisible = UnitIsVisible
	local CheckInteractDistance = CheckInteractDistance
	local GetSpellInfo = GetSpellInfo
	local UnitInRange = UnitInRange

	local DEFAULT_INTERACT_RANGE = 4

	local function DefaultRangeCheck(unit, interactRange)
		return UnitInRange(unit) or CheckInteractDistance(unit, interactRange)
	end
	
	local function CheckSpell(id, interactRange)
		local spell = GetSpellInfo(id)
		interactRange = interactRange or DEFAULT_INTERACT_RANGE
		return function(unit)
			local inRange = IsSpellInRange(spell, unit)
			if inRange ~= nil then
				return inRange == 1
			else
				return DefaultRangeCheck(unit, interactRange)
			end
		end
	end

	local function CheckBothSpells(id1, id2, interactRange)
		local spell1, spell2 = GetSpellInfo(id1), GetSpellInfo(id2)
		interactRange = interactRange or DEFAULT_INTERACT_RANGE
		return function(unit)
			local inRange1, inRange2 = IsSpellInRange(spell1, unit), IsSpellInRange(spell2, unit)
			if inRange1 == 1 or inRange2 == 1 then
				return true
			elseif inRange1 == nil and inRange2 == nil then
				return DefaultRangeCheck(unit, interactRange)
			else
				return false
			end
		end
	end

	local friendlyCheck, hostileCheck, petCheck, rezCheck
	local playerClass = select(2, UnitClass("player"))

	if playerClass == 'PRIEST' then
		friendlyCheck = CheckSpell(2050) -- Lesser Heal
		hostileCheck = CheckBothSpells(48127, 585) -- Mind Blast or Smite
		rezCheck = CheckSpell(2006) -- Resurrection

	elseif playerClass == 'DRUID' then
		friendlyCheck = CheckSpell(48378) -- Healing Touch
		hostileCheck = CheckSpell(48461) -- Wrath
		rezCheck = CheckSpell(20484) -- Rebirth

	elseif playerClass == 'PALADIN' then
		friendlyCheck = CheckSpell(48782) -- Holy Light
		hostileCheck = CheckSpell(62124) -- Hand of Reckoning
		rezCheck = CheckSpell(7328) -- Redemption

	elseif playerClass == 'HUNTER' then
		hostileCheck = CheckSpell(75) -- Auto Shot
		petCheck = CheckSpell(136) -- Mend Pet

	elseif playerClass == 'SHAMAN' then
		friendlyCheck = CheckSpell(49273) -- Healing Wave
		hostileCheck = CheckSpell(529) -- Lightning Bolt
		rezCheck = CheckSpell(2008) -- Ancestral Spirit

	elseif playerClass == 'WARLOCK' then
		hostileCheck = CheckBothSpells(686, 172) -- Shadow Bolt or Corruption
		friendlyCheck = CheckSpell(132) -- (buff) Detect Invisibility

	elseif playerClass == 'MAGE' then
		friendlyCheck = CheckSpell(475) -- Remove Curse

		-- Mages can increase the range of each school separately
		local spell1, spell2, spell3 = GetSpellInfo(5143),  GetSpellInfo(133),  GetSpellInfo(116) -- Arcane Missiles, Fireball, Frostbolt
		hostileCheck = function(unit)
			local inRange1, inRange2, inRange3 = IsSpellInRange(spell1, unit), IsSpellInRange(spell2, unit), IsSpellInRange(spell3, unit)
			if inRange1 == 1 or inRange2 == 1 or inRange3 == 1 then
				return true
			elseif inRange1 == nil and inRange2 == nil and inRange3 == nil then
				return DefaultRangeCheck(unit, DEFAULT_INTERACT_RANGE)
			else
				return false
			end
		end
		
	elseif playerClass == 'DEATHKNIGHT' then
		hostileCheck = CheckSpell(49576) -- Death grip

	elseif playerClass == 'ROGUE' then
		hostileCheck = CheckSpell(26679) -- Deadly Throw
		friendlyCheck = CheckSpell(57934) -- Tricks of the Trade

	elseif playerClass == 'WARRIOR' then
		hostileCheck = CheckBothSpells(772, 100) -- Rend (melee) or Charge
		friendlyCheck = CheckSpell(3411, 2) -- Intervene
	end

	return function(unit)
		if UnitIsUnit(unit, 'player') or not UnitIsConnected(unit) then
			return true
		elseif not UnitIsVisible(unit) then
			return false
		elseif hostileCheck and UnitCanAttack('player', unit) then
			return hostileCheck(unit)
		elseif petCheck and UnitIsUnit(unit, 'pet') then
			return petCheck(unit)
		elseif rezCheck and UnitIsCorpse(unit) and UnitCanAssist('player', unit) then
			return rezCheck(unit)
		elseif friendlyCheck and UnitCanAssist('player', unit) then
			return friendlyCheck(unit)
		else
			return DefaultRangeCheck(unit, DEFAULT_INTERACT_RANGE)
		end
	end
	
end

local IsInRange = function() return true end
local objects = {}
local updateFrame
local timer = 0

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

local function Initialize()
	IsInRange = BuildRangeCheck()
	updateFrame:UnregisterEvent('PLAYER_LOGIN')
	updateFrame:SetScript('OnEvent', nil)
	updateFrame:SetScript('OnUpdate', OnUpdate)
end

local function Enable(self)
	if self.XRange and self.unit ~= 'player' then
		if not updateFrame then
			updateFrame = CreateFrame("Frame")
			-- Postpone initialization so all spells are available
			if IsLoggedIn() then
				Initialize()
			else
				updateFrame:RegisterEvent('PLAYER_LOGIN')
				updateFrame:SetScript('OnEvent', Initialize)
			end
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


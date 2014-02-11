--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]


local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local CreateFrame = _G.CreateFrame
local IsLoggedIn = _G.IsLoggedIn
local next = _G.next
--GLOBALS>

local function BuildRangeCheck()
	local CheckInteractDistance = _G.CheckInteractDistance
	local GetSpellInfo = _G.GetSpellInfo
	local IsSpellInRange = _G.IsSpellInRange
	local UnitCanAssist = _G.UnitCanAssist
	local UnitCanAttack = _G.UnitCanAttack
	local UnitClass = _G.UnitClass
	local UnitExists = _G.UnitExists
	local UnitInRange = _G.UnitInRange
	local UnitIsConnected = _G.UnitIsConnected
	local UnitIsCorpse = _G.UnitIsCorpse
	local UnitIsUnit = _G.UnitIsUnit
	local UnitIsVisible = _G.UnitIsVisible
	local geterrorhandler = _G.geterrorhandler
	local select = _G.select

	local INTERACT_RANGE = 4

	local function DefaultRangeCheck(unit)
		local inRange, checked = UnitInRange(unit)
		if checked then
			return inRange
		else
			return CheckInteractDistance(unit, INTERACT_RANGE)
		end
	end

	local function CheckSpell(id)
		local spell = GetSpellInfo(id)
		if not spell then
			geterrorhandler()("XRange:CheckSpell: unknown spell #"..id)
			return DefaultRangeCheck
		end
		if not GetSpellInfo(spell) then
			oUF:Debug('spell unknown, using default range check:', spell)
			return DefaultRangeCheck
		end
		oUF:Debug('using', spell, 'for range check')
		return function(unit)
			local inRange = IsSpellInRange(spell, unit)
			if inRange ~= nil then
				return inRange == 1
			else
				return DefaultRangeCheck(unit)
			end
		end
	end

	local function CheckBothSpells(id1, id2)
		local spell1, spell2 = GetSpellInfo(id1), GetSpellInfo(id2)
		if not spell1 then geterrorhandler()("XRange:CheckSpell: unknown spell1 #"..id1) end
		if not spell2 then geterrorhandler()("XRange:CheckSpell: unknown spell2 #"..id2) end
		if not spell1 or not GetSpellInfo(spell1) then
			oUF:Debug('spell unknown: ', spell1, 'using', spell2)
			return CheckSpell(id2)
		elseif not spell2 or not GetSpellInfo(spell2) then
			oUF:Debug('spell unknown: ', spell2, 'using', spell1)
			return CheckSpell(id1)
		end
		oUF:Debug('using both', spell1, 'and', spell2, 'for range check')
		return function(unit)
			local inRange1, inRange2 = IsSpellInRange(spell1, unit), IsSpellInRange(spell2, unit)
			if inRange1 == 1 or inRange2 == 1 then
				return true
			elseif inRange1 == nil and inRange2 == nil then
				return DefaultRangeCheck(unit)
			else
				return false
			end
		end
	end

	local friendlyCheck, hostileCheck, petCheck, rezCheck
	local playerClass = select(2, UnitClass("player"))

	if playerClass == 'PRIEST' then
		friendlyCheck = CheckSpell(2061) -- Flash Heal
		hostileCheck = CheckSpell(589) -- Shadow Word: Pain
		rezCheck = CheckSpell(2006) -- Resurrection

	elseif playerClass == 'DRUID' then
		friendlyCheck = CheckSpell(774) -- Rejuvenation
		hostileCheck = CheckSpell(5176) -- Wrath
		rezCheck = CheckSpell(20484) -- Rebirth

	elseif playerClass == 'PALADIN' then
		friendlyCheck = CheckSpell(19750) -- Flash of Light
		hostileCheck = CheckSpell(62124) -- Hand of Reckoning
		rezCheck = CheckSpell(7328) -- Redemption

	elseif playerClass == 'HUNTER' then
		hostileCheck = CheckSpell(75) -- Auto Shot
		petCheck = CheckSpell(136) -- Mend Pet

	elseif playerClass == 'SHAMAN' then
		friendlyCheck = CheckSpell(51886) -- Cleanse Spirit
		hostileCheck = CheckSpell(403) -- Lightning Bolt
		rezCheck = CheckSpell(2008) -- Ancestral Spirit

	elseif playerClass == 'WARLOCK' then
		hostileCheck = CheckSpell(686) -- Shadow Bolt
		friendlyCheck = CheckSpell(5697) -- Unending Breath
		petCheck = CheckSpell(755) -- Health Funnel

	elseif playerClass == 'MAGE' then
		hostileCheck = CheckSpell(133) --  Fireball
		friendlyCheck = CheckSpell(475) -- Remove Curse

	elseif playerClass == 'DEATHKNIGHT' then
		hostileCheck = CheckSpell(49576) -- Death grip
		rezCheck = CheckSpell(61999) -- Raise Ally

	elseif playerClass == 'ROGUE' then
		hostileCheck = CheckBothSpells(1752, 121733) -- Sinister Strike or Throw

	elseif playerClass == 'WARRIOR' then
		hostileCheck = CheckBothSpells(78, 100) -- Heroic Strike (melee) or Charge

	elseif playerClass == 'MONK' then
		friendlyCheck = CheckSpell(115921) -- Legacy of the Emperor
		hostileCheck = CheckSpell(117952) -- Crackling Jade Lightning
		rezCheck = CheckSpell(115178) -- Resuscitate
	end

	return function(unit)
		if not UnitExists(unit) then
			return false
		elseif UnitIsUnit(unit, 'player') or not UnitIsConnected(unit) then
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
	local xrange = self.XRange
	local inRange = IsInRange(self.unit)
	if inRange then
		if xrange:IsShown() or event == 'ForceUpdate' then
			xrange:Hide()
		else
			return
		end
	else
		if not xrange:IsShown() or event == 'ForceUpdate' then
			xrange:Show()
		else
			return
		end
	end
	if xrange.PostUpdate then
		xrange:PostUpdate(event, self.unit, inRange)
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, "ForceUpdate")
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
	local xrange = self.XRange
	if xrange and self.unit ~= 'player' then
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
		xrange.__owner, xrange.ForceUpdate = self, ForceUpdate
		xrange:Hide()
		objects[self] = true
		return true
	end
end

local function Disable(self)
	if objects[self] then
		objects[self] = nil
		self.XRange:Hide()
	end
end

oUF:AddElement('XRange', Update, Enable, Disable)


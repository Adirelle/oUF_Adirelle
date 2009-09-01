--[=[
	Elements handled: .Border
	
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local UnitThreatSituation = UnitThreatSituation
local GetThreatStatusColor = GetThreatStatusColor
local UnitIsUnit = UnitIsUnit
local UnitPowerType = UnitPowerType
local UnitMana = UnitMana
local UnitManaMax = UnitManaMax

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = unit or self.unit
	local border = self.Border
	local r, g, b
	local threat = UnitThreatSituation(unit)
	if UnitIsUnit('target', unit) then
		r, g, b = 1, 1, 0
	elseif threat and threat > 0 then
		r, g, b = GetThreatStatusColor(threat)
	elseif UnitPowerType(unit) == 0 and UnitMana(unit) / UnitManaMax(unit) < 0.25 then
		r, g, b = 0, 0, 1
	else
		return border:Hide()
	end
	border:SetColor(r, g, b)
	border:Show()
end

local function Enable (self)
	if self.Border then
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		self:RegisterEvent("UNIT_MANA", Update)
		self:RegisterEvent("UNIT_MAXMANA", Update)
		self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)			
		self.Border:Hide()
		return true
	end
end

local function Disable(self)
	local border = self.Border
	if border then
		self:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE", Update)
		self:UnregisterEvent("UNIT_MANA", Update)
		self:UnregisterEvent("UNIT_MAXMANA", Update)
		self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)			
		border:Hide()
	end
end

oUF:AddElement('Adirelle_Border', Update, Enable, Disable)

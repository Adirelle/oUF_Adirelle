--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .TargetColor
--]=]

local function gradient(f)
	f = f * 6
	if f < 1 then
		return 0
	elseif f < 3 then
		return (f-1)/2
	elseif f < 4 then
		return 1
	else
		return (6-f)/2
	end
end

local function GetColorForGUID(guid)
	local v = 0x55
	for i = 3, 18, 2 do
		v = bit.bxor(v, tonumber(string.sub(guid,i,i+1), 16))
	end
	local fr = v / 256
	local fg = (fr + 1/3) % 1
	local fb = (fr + 2/3) % 1
	return { gradient(fr), gradient(fg), gradient(fb) }
end

local guidColorMap = setmetatable({}, {
	__mode='kv',
	__index = function(t, guid)
		if not guid then return end
		local color = GetColorForGUID(guid)
		t[guid] = color
		return color
	end
})

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = self.unit
	local target = unit == "player" and "target" or unit..'target'
	local color
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and not UnitIsDeadOrGhost(target) and UnitCanAttack(unit, target) then
		color = guidColorMap[UnitGUID(target)]
	end
	if color then
		local tc = self.TargetColor
		tc:SetColor(unpack(color, 1, 3))
		tc:Show()
	else
		self.TargetColor:Hide()
	end
end

local function Enable(self)
	if self.TargetColor then
		self:RegisterEvent('UNIT_TARGET', Update)
		self:RegisterEvent('UNIT_FLAGS', Update)
		return true
	end
end

local function Disable(self)
	if self.TargetColor then
		self:UnregisterEvent('UNIT_TARGET', Update)
		self:UnregisterEvent('UNIT_FLAGS', Update)
	end
end

oUF:AddElement('TargetColor', Update, Enable, Disable)

